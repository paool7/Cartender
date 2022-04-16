//
//  Endpoint.swift
//  Cartender
//
//  Created by Paul Dippold on 11/16/21.
//

import Foundation

enum Endpoint: String {
    case login = "prof/authUser"
    case vehicles = "ownr/gvl"
    case status = "cmm/gvi"
    case actionStatus = "cmm/gts"
    case updateStatus = "rems/rvs"
    case lock = "rems/door/lock"
    case unlock = "rems/door/unlock"
    case startClimate = "rems/start"
    case stopClimate = "rems/stop"
    case startCharge = "evc/charge"
    case stopCharge = "evc/cancel"
    case setChargeLimit = "evc/sts"
    case getLocation = "location/vehicle"
    
    func successMessage() -> String? {
        switch self {
        case .login:
            return nil
        case .vehicles:
            return nil
        case .status:
            return nil
        case .actionStatus:
            return nil
        case .updateStatus:
            return nil
        case .lock:
            return "Locked"
        case .unlock:
            return "Unlocked"
        case .startClimate:
            return "Climate control started"
        case .stopClimate:
            return "Climate control stopped"
        case .startCharge:
            return "Charging started"
        case .stopCharge:
            return "Charging stopped"
        case .setChargeLimit:
            return "Set charge limit"
        case .getLocation:
            return nil
        }        
    }
}
