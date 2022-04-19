//
//  ResponseError.swift
//  Cartender
//
//  Created by Paul Dippold on 4/15/22.
//

import Foundation

enum ResponseError: Int {
    case sleepMode = 1155
    case anotherCommand = 1125
    case lowCoverage = 1132
    case doorsOpen = 1131
    case invalidSession = 1003
    case logout = 1001
    case invalidVehicle = 1005
    
    var message: String? {
        switch self {
        case .sleepMode:
            return "Your car is in sleep mode. Turn it on and then try again."
        case .anotherCommand:
            return "Another remote command is being executed. Please wait for it to finish and then try again"
        case .lowCoverage:
            return "Your car is not responding. Turn it on and then try again."
        case .doorsOpen:
            return "Your car doors may be open. Close them and then try again."
        case .logout:
            return "Login and then try again."
        case .invalidSession:
            return nil
        case .invalidVehicle:
            return nil
        }
    }
}
