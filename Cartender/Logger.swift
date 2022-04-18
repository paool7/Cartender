//
//  Logger.swift
//  Cartender
//
//  Created by Paul Dippold on 4/15/22.
//

import Foundation
import SwiftyBeaver

let log = SwiftyBeaver.self
class Logger {
    static let shared = Logger()
    
    func start() {
        let platform = SBPlatformDestination(appID: Credentials.SBAppID, appSecret: Credentials.SBAppSecret, encryptionKey: Credentials.SBEncryptionKey)
        let console = ConsoleDestination()
        let file = FileDestination()
        log.addDestination(platform)
        log.addDestination(console)
        log.addDestination(file)
    }
}
