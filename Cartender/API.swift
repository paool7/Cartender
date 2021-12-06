//
//  API.swift
//  Cartender
//
//  Created by Paul Dippold on 11/16/21.
//

import Foundation
import SwiftHTTP

let baseURL = "https://api.owners.kia.com/apigw/v1/"
class API {
    static let shared = API()
    
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
    
    func post(endpoint: Endpoint, body: [String : Any]?, authorized: Bool = false, completion: ((Response) -> ())?) {
        var req = URLRequest(urlString: baseURL + endpoint.rawValue)!
        req.httpMethod = "POST"
        req.allHTTPHeaderFields = authorized ? authorizedHeaders : headers
        if let body = body {
            req.httpBody = body.json
        }
        HTTP(req).run { response in
            guard let responseHeaders = response.headers else {
                return
            }
            if let json = try? JSONSerialization.jsonObject(with: response.data, options: []) as? [String: Any], let status = json["status"] as? [String: Any] {
                print(status["errorMessage"]!)
                if status["errorMessage"] as! String == "Incorrect request payload format" {
                    print(endpoint)
                }
            }
            if !authorized, let sid = responseHeaders["Sid"] {
                self.sessionId = sid
            }
            completion?(response)
        }
    }
    
    func get(endpoint: Endpoint, _ retry: Bool = true, completion: ((Response) -> ())?) {
        var req = URLRequest(urlString: baseURL + endpoint.rawValue)!
        req.httpMethod = "GET"
        req.allHTTPHeaderFields = authorizedHeaders
        HTTP(req).run { response in
            if let json = try? JSONSerialization.jsonObject(with: response.data, options: []) as? [String: Any], let status = json["status"] as? [String: Any] {
                print(status["errorMessage"]!)
                if status["errorMessage"] as! String == "Incorrect request payload format" {
                    print(endpoint)
                }
            }
            completion?(response)
        }
    }
}
