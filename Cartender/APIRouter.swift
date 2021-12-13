//
//  APIRouter.swift
//  Cartender
//
//  Created by Paul Dippold on 11/23/21.
//

import Foundation

class APIRouter {
    static let shared = APIRouter()
    let jsonDecoder = JSONDecoder()

    func getImage(name: String, path: String) -> String {
        let trimmedName = name.replacingOccurrences(of: ".png", with: "")
        let uppercaseName = trimmedName.uppercased()
       return "https://owners.kia.com\(path)\(uppercaseName).png/jcr:content/renditions/cq5dam.thumbnail.1280.861.png"
    }
    
    func checkActionStatus(xid: String, completion: @escaping () -> ()) {
        API.shared.post(endpoint: .actionStatus, body: ["xid": xid], authorized: true) { response in
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
    
    func login(username: String, password: String, completion: @escaping () -> ()) {
        API.shared.post(endpoint: .login, body: ["deviceKey": "",
                                                 "deviceType": 2,
                                                 "userCredential": ["userId": username,
                                                                    "password": password]], authorized: false) { response in
            if let responseHeaders = response.headers, let sid = responseHeaders["Sid"] {
                API.shared.sessionId = sid
            }
            completion()
        }
    }
}
