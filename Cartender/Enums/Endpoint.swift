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
}
