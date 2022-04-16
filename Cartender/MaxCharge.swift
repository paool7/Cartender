//
//  MaxCharge.swift
//  Cartender
//
//  Created by Paul Dippold on 4/10/22.
//

import Foundation

class MaxCharge {
    static var AC: Int {
        get {
            let max = defaults?.integer(forKey: "ACChargeMax")
            return (max == 0) ? 80 : max ?? 80
        }
        set {
            defaults?.set(newValue, forKey: "ACChargeMax")
        }
    }
    static var DC: Int {
        get {
            let max = defaults?.integer(forKey: "DCChargeMax")
            return (max == 0) ? 80 : max ?? 80
        }
        set {
            defaults?.set(newValue, forKey: "DCChargeMax")
        }
    }
}
