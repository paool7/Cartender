//
//  APIRouter.swift
//  Cartender
//
//  Created by Paul Dippold on 11/23/21.
//

import Foundation
import SwiftHTTP
import SwiftKeychainWrapper

let baseURL = "https://api.owners.kia.com/apigw/v1/"
class APIRouter {
    static let shared = APIRouter()
    
    var logoutHandler: (() -> ())?
    let jsonDecoder = JSONDecoder()
    
    //Generate a fake but consistent UUID
    var uuid: String {
        get {
            guard let uuid = UserDefaults.standard.string(forKey: "APIUUID") else {
                let newUUID = UUID().uuidString
                UserDefaults.standard.set(newUUID, forKey: "APIUUID")
                return newUUID
            }
            return uuid
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "APIUUID")
        }
    }
    var vinKey: String?

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
            return UserDefaults.standard.string(forKey: "APISessionID")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "APISessionID")
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
       return "https://owners.kia.com\(path)\(uppercaseName).png/jcr:content/renditions/cq5dam.thumbnail.1280.861.png"
    }
    
    func checkActionStatus(xid: String, completion: @escaping () -> ()) {
        post(endpoint: .actionStatus, body: ["xid": xid], authorized: true) { response in
            if let actionStatus = try? self.jsonDecoder.decode(ActionStatusResponse.self, from: response.data) {
                if actionStatus.payload?.evStatus == 0, actionStatus.payload?.alertStatus == 0, actionStatus.payload?.locationStatus == 0, actionStatus.payload?.remoteStatus == 0 {
                    completion()
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                        self.checkActionStatus(xid: xid, completion: completion)
                     }
                }
            }
        }
    }
    
    func login(username: String, password: String, completion: @escaping (String?) -> ()) {
        post(endpoint: .login, body: ["deviceKey": "",
                                                 "deviceType": 2,
                                                 "userCredential": ["userId": username,
                                                                    "password": password]], authorized: false) { [weak self] response in
            if let statusResponse = try? self?.jsonDecoder.decode(UpdateStatusResponse.self, from: response.data) {
                if let errorMessage = statusResponse.status?.errorMessage, let errorCode = statusResponse.status?.errorCode, errorCode != 0 {
                    if errorCode == 1001 {
                        KeychainWrapper.standard.removeObject(forKey: .usernameKey)
                        KeychainWrapper.standard.removeObject(forKey: .passwordKey)
                    }
                    completion(errorMessage)
                } else {
                    if let responseHeaders = response.headers {
                        if let sid = responseHeaders["Sid"] {
                            self?.sessionId = sid
                            completion(nil)
                        } else {
                            completion("Unable to connect, check your internet connection")
                        }
                    }
                }
            } else {
                completion("Unable to connect, check your internet connection")
            }
        }
    }
}

extension APIRouter {
    func post(endpoint: Endpoint, body: [String : Any]?, authorized: Bool = false, completion: ((Response) -> ())?) {
        var req = URLRequest(urlString: baseURL + endpoint.rawValue)!
        req.httpMethod = "POST"
        req.allHTTPHeaderFields = authorized ? authorizedHeaders : headers
        if let body = body {
            req.httpBody = body.json
        }
        HTTP(req).run { [weak self] response in
            if let text = response.text, text.contains(":1003") {
                self?.sessionId = nil
                self?.logoutHandler?()
            } else {
                guard let responseHeaders = response.headers else {
                    return
                }
                if let json = try? JSONSerialization.jsonObject(with: response.data, options: []) as? [String: Any], let status = json["status"] as? [String: Any] {
                    print(status["errorMessage"]!)
                    if status["errorMessage"] as? String == "Incorrect request payload format" {
                        print(endpoint)
                    }
                }
                if !authorized, let sid = responseHeaders["Sid"] {
                    self?.sessionId = sid
                }
                completion?(response)
            }
        }
    }
    
    func get(endpoint: Endpoint, _ retry: Bool = true, completion: ((Response) -> ())?) {
        var req = URLRequest(urlString: baseURL + endpoint.rawValue)!
        req.httpMethod = "GET"
        req.allHTTPHeaderFields = authorizedHeaders
        HTTP(req).run { [weak self] response in
            if let text = response.text, text.contains(":1003") {
                self?.sessionId = nil
                self?.logoutHandler?()
            } else {
                if let json = try? JSONSerialization.jsonObject(with: response.data, options: []) as? [String: Any], let status = json["status"] as? [String: Any] {
                    print(status["errorMessage"]!)
                    if status["errorMessage"] as? String == "Incorrect request payload format" {
                        print(endpoint)
                    }
                }
                completion?(response)
            }
        }
    }
}
