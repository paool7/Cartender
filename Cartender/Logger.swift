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
        let platform = SBPlatformDestination(appID: Secrets.SBAppID, appSecret: Secrets.SBAppSecret, encryptionKey: Secrets.SBEncryptionKey)
        platform.sendingPoints.threshold = 5
        let console = ConsoleDestination()
        let file = FileDestination()
        log.addDestination(platform)
        log.addDestination(console)
        log.addDestination(file)
    }
}
