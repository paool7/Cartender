//
//  Shortcut.swift
//  Cartender
//
//  Created by Paul Dippold on 4/8/22.
//

import Foundation
import Intents

enum Shortcut: String, CaseIterable {
    case getCharge = "Is the car charged?"
    case setLock = "Lock the car"
    case setTemperature = "Turn on climate control"
    case getLocation = "Where's the car?"
    case getTemperature = "What's the car temperature?"
    case getLock = "Is the car locked?"
    case setUnlock = "Unlock the car"
    
    var intent: INIntent {
        switch self {
        case .setTemperature:
            let intent = SetTemperatureIntent()
            intent.suggestedInvocationPhrase = self.rawValue
            intent.temperature = nil
            return intent
        case .getLocation:
            let intent = CurrentLocationIntent()
            intent.suggestedInvocationPhrase = self.rawValue
            return intent
        case .getCharge:
            let intent = CurrentChargeIntent()
            intent.suggestedInvocationPhrase = self.rawValue
            return intent
        case .getTemperature:
            let intent = CurrentTemperatureIntent()
            intent.suggestedInvocationPhrase = self.rawValue
            return intent
        case .getLock:
            let intent = CheckDoorsIntent()
            intent.suggestedInvocationPhrase = self.rawValue
            return intent
        case .setLock:
            let intent = LockDoorsIntent()
            intent.suggestedInvocationPhrase = self.rawValue
            return intent
        case .setUnlock:
            let intent = UnlockDoorsIntent()
            intent.suggestedInvocationPhrase = self.rawValue
            return intent
        }
    }
    
    func donate() {
        let interaction = INInteraction(intent: self.intent, response: nil)
        interaction.donate { (error) in
            if let error = error as NSError? {
                log.error("Interaction donation failed: \(error.description)")
            } else {
                log.info("Successfully donated interaction")
            }
        }
    }
}
