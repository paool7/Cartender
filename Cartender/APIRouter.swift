//
//  APIRouter.swift
//  Cartender
//
//  Created by Paul Dippold on 11/23/21.
//

import Foundation
import SwiftHTTP
import SwiftKeychainWrapper
import NotificationBannerSwift

let baseURL = "https://api.owners.kia.com/apigw/v1/"
class APIRouter {
    static let shared = APIRouter()
    let jsonDecoder = JSONDecoder()
    var logoutHandler: (() -> ())?
    var vinKey: String?

    //Generate a fake but consistent UUID
    var uuid: String {
        get {
            guard let uuid = defaults?.string(forKey: "APIUUID") else {
                let newUUID = UUID().uuidString
                defaults?.set(newUUID, forKey: "APIUUID")
                return newUUID
            }
            return uuid
        }
        set {
            defaults?.set(newValue, forKey: "APIUUID")
        }
    }

    var headers: [String: String] {
        return ["to":"APIGW",
                "secretkey":"98er-w34rf-ibf3-3f6h",
                "appversion":"1.0",
                "language":"0",
                "clientid":"mwamobile",
                "osversion":"15",
                "ostype":"iOS",
                "date":"",
                "deviceid": self.uuid,
                "offset":"-5",
                "apptype":"L",
                "from":"SPA",
                "Content-Type":"application/json"]
    }
    
    var sessionId: String? {
        get {
            return defaults?.string(forKey: "APISessionID")
        }
        set {
            defaults?.set(newValue, forKey: "APISessionID")
        }
    }
    
    var authorizedHeaders: [String: String] {
        var authHeaders = headers
        if let sessionId = sessionId {
            authHeaders["sid"] = sessionId
        }
        if let vinKey = vinKey {
            authHeaders["vinKey"] = vinKey
        }
        return authHeaders
    }

    func getImage(name: String, path: String) -> String {
        let trimmedName = name.replacingOccurrences(of: ".png", with: "")
        let uppercaseName = trimmedName.uppercased()
        let trimmedPath = path.replacingOccurrences(of: "vehicle-app", with: "vehicle")
       return "https://owners.kia.com\(trimmedPath)\(uppercaseName).png/jcr:content/renditions/cq5dam.thumbnail.1280.861.png"
    }
    
    func checkActionStatus(xid: String, completion: @escaping ((code: Int, message: String)?) -> ()) {
        post(endpoint: .actionStatus, body: ["xid": xid], authorized: true) { response, error in
            if let error = error {
                completion(error)
            } else if let data = response?.data, let actionStatus = try? self.jsonDecoder.decode(ActionStatusResponse.self, from: data) {
                if actionStatus.payload?.evStatus == 0, actionStatus.payload?.alertStatus == 0, actionStatus.payload?.locationStatus == 0, actionStatus.payload?.remoteStatus == 0 {
                    completion(nil)
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                        self.checkActionStatus(xid: xid, completion: completion)
                     }
                }
            }
        }
    }
    
    func login(username: String, password: String, _ checkError: Bool = true, completion: @escaping (String?) -> ()) {
        post(endpoint: .login, body: ["deviceKey": "",
                                                 "deviceType": 2,
                                                 "userCredential": ["userId": username,
                                                                    "password": password]], authorized: false) { [weak self] response, error in
            if let error = error?.message {
                completion(error)
            } else if let responseHeaders = response?.headers, let sid = responseHeaders["Sid"] {
                keychain.set(username, forKey: .usernameKey)
                keychain.set(password, forKey: .passwordKey)
                self?.sessionId = sid
                completion(nil)
            } else {
                completion("Unable to connect, check your internet connection")
            }
        }
    }
}

extension APIRouter {
    func post(endpoint: Endpoint, _ retry: Bool = true, body: [String : Any]?, authorized: Bool = false, _ checkError: Bool = true, completion: ((Response?, (code: Int, message: String)?) -> ())?) {
        if Reachability.isConnectedToNetwork() {
            var req = URLRequest(urlString: baseURL + endpoint.rawValue)!
            req.httpMethod = "POST"
            req.allHTTPHeaderFields = authorized ? authorizedHeaders : headers
            if let body = body {
                req.httpBody = body.json
            }
            HTTP(req).run { [weak self] response in
                if checkError {
                    self?.error(response: response, completion: { result, tryAgain in
                        if let result = result {
                            if tryAgain == true && retry {
                                self?.post(endpoint: endpoint, false, body: body, completion: completion)
                            } else {
                                completion?(nil, result)
                            }
                        } else {
                            completion?(response, nil)
                        }
                    })
                } else {
                    completion?(response, nil)
                }
            }
        } else {
            self.showError(message: "No internet connection. Make sure your device is connected to the internet and try again.")
            completion?(nil, (0, "No internet connection. Make sure your device is connected to the internet and try again."))
        }
    }
    
    func get(endpoint: Endpoint, _ retry: Bool = true, _ checkError: Bool = true, completion: ((Response?, (code: Int, message: String)?) -> ())?) {
        if Reachability.isConnectedToNetwork() {
            var req = URLRequest(urlString: baseURL + endpoint.rawValue)!
            req.httpMethod = "GET"
            req.allHTTPHeaderFields = authorizedHeaders
            HTTP(req).run { [weak self] response in
                if checkError {
                    self?.error(response: response, completion: { result, tryAgain in
                        if let result = result {
                            if tryAgain == true && retry {
                                self?.get(endpoint: endpoint, false, completion: completion)
                            } else {
                                completion?(nil, result)
                            }
                        } else {
                            completion?(response, nil)
                        }
                    })
                } else {
                    completion?(response, nil)
                }
            }
        } else {
            self.showError(message: "No internet connection. Make sure your device is connected to the internet and try again.")
            completion?(nil, (0, "No internet connection. Make sure your device is connected to the internet and try again."))
        }
    }
    
    func error(response: Response, completion: (((code: Int, message: String)?, Bool?) -> ())?) {
        if let error = try? self.jsonDecoder.decode(ActionError.self, from: response.data), let code = error.status?.errorCode, let message = error.status?.errorMessage, error.status?.statusCode != 0 {
            var errorMessage = message
            
            if let rError = ResponseError(rawValue: code) {
                errorMessage = rError.message ?? errorMessage
                if (rError == .invalidSession || rError == .invalidVehicle), let username = keychain.string(forKey: .usernameKey), let password = keychain.string(forKey: .passwordKey) {
                    self.sessionId = nil
                    APIRouter.shared.vinKey = nil
                    APIRouter.shared.login(username: username, password: password, false) { [weak self] loginError in
                        if loginError != nil {
                            self?.logout()
                            completion?((code, errorMessage), false)
                        } else {
                            APIRouter.shared.get(endpoint: .vehicles, false, false) { response, error in
                                if let data = response?.data, let vehicles = try? APIRouter.shared.jsonDecoder.decode(VehiclesResponse.self, from: data), let vinKey = vehicles.payload?.vehicleSummary?.first?.vehicleKey {
                                    APIRouter.shared.vinKey = vinKey
                                    completion?((code, errorMessage), true)
                                } else {
                                    completion?((code, errorMessage), false)
                                }
                            }
                        }
                    }
                } else if rError == .logout {
                    self.logout()
                    completion?((code, errorMessage), false)
                } else {
                    completion?((code, errorMessage), false)
                }
            }
            
            if (code != ResponseError.invalidSession.rawValue && code != ResponseError.invalidVehicle.rawValue) {
                self.showError(message: errorMessage)
                log.error("\(code): \(message)")
            }
            completion?((code, errorMessage), false)
        } else {
            completion?(nil, false)
        }
    }
    
    func logout() {
        self.sessionId = nil
        APIRouter.shared.vinKey = nil
        keychain.removeObject(forKey: .usernameKey)
        keychain.removeObject(forKey: .passwordKey)
        self.logoutHandler?()
    }
    
    func showError(message: String) {
        DispatchQueue.main.async {
            let banner = FloatingNotificationBanner(title: "Error!", subtitle: message, style: .danger)
            banner.show(cornerRadius: 8)
        }
    }
    
    func showSuccess(message: String) {
        DispatchQueue.main.async {
            let banner = FloatingNotificationBanner(title: "Success!", subtitle: message, style: .success)
            banner.show(cornerRadius: 8)
        }
    }
}

extension Dictionary {
    var json: Data? {
        guard let theJSONData = try? JSONSerialization.data(withJSONObject: self, options: [.prettyPrinted]) else {
            return nil
        }
        
        return theJSONData
    }
}

