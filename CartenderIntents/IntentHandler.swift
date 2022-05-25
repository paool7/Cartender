//
//  IntentHandler.swift
//  CartenderIntents
//
//  Created by Paul Dippold on 4/6/22.
//

import Intents
import SwiftHTTP
import SwiftKeychainWrapper

class IntentHandler: INExtension, CurrentChargeIntentHandling, CurrentLocationIntentHandling, CheckDoorsIntentHandling, CurrentTemperatureIntentHandling, SetTemperatureIntentHandling, LockDoorsIntentHandling, UnlockDoorsIntentHandling {
    override func handler(for intent: INIntent) -> Any {
        return self
    }
    
    func handle(intent: LockDoorsIntent, completion: @escaping (LockDoorsIntentResponse) -> Void) {
        Shortcut.setLock.donate()
        self.getVehicleStatus { vehicle, error in
            let name = vehicle?.payload?.vehicleInfoList?.first?.lastVehicleInfo?.vehicleNickName ?? vehicle?.payload?.vehicleInfoList?.first?.vehicleConfig?.vehicleDetail?.vehicle?.trim?.modelName ?? "Niro"

            if let error = error {
                completion(LockDoorsIntentResponse.failure(error: error))
            } else if let sleepMode = vehicle?.payload?.vehicleInfoList?.first?.lastVehicleInfo?.vehicleStatusRpt?.vehicleStatus?.sleepMode, sleepMode {
                completion(LockDoorsIntentResponse.failure(error: "\(name) is in sleep mode. Turn the car on and try again."))
            } else {
                self.lockDoors(name: name, completion: completion)
            }
        }
    }
    
    func lockDoors(name: String, completion: @escaping (LockDoorsIntentResponse) -> Void) {
        APIRouter.shared.get(endpoint: .lock) { response, error in
            if let error = error {
                if error.code == ResponseError.invalidSession.rawValue {
                    completion(LockDoorsIntentResponse.failure(error: "Open the app to login and then try again."))
                } else if error.code == ResponseError.anotherCommand.rawValue {
                    completion(LockDoorsIntentResponse.failure(error: "Another remote command is being executed. Please wait for it to finish and try again"))
                } else {
                    completion(LockDoorsIntentResponse.failure(error: error.message))
                }
            } else {
                if let headers = response?.headers, let xid = headers["Xid"] {
                    APIRouter.shared.checkActionStatus(xid: xid) { error in
                        if let error = error {
                            completion(LockDoorsIntentResponse.failure(error: error.message))
                        } else {
                            completion(LockDoorsIntentResponse.success(name: name, locked: 1))
                        }
                    }
                } else {
                    completion(LockDoorsIntentResponse.failure(error: "Couldn't lock doors. Open the app to try again."))
                }
            }
        }
    }
    
    func handle(intent: UnlockDoorsIntent, completion: @escaping (UnlockDoorsIntentResponse) -> Void) {
        Shortcut.setUnlock.donate()
        self.getVehicleStatus { vehicle, error in
            let name = vehicle?.payload?.vehicleInfoList?.first?.lastVehicleInfo?.vehicleNickName ?? vehicle?.payload?.vehicleInfoList?.first?.vehicleConfig?.vehicleDetail?.vehicle?.trim?.modelName ?? "Niro"

            if let error = error {
                completion(UnlockDoorsIntentResponse.failure(error: error))
            } else if let sleepMode = vehicle?.payload?.vehicleInfoList?.first?.lastVehicleInfo?.vehicleStatusRpt?.vehicleStatus?.sleepMode, sleepMode {
                completion(UnlockDoorsIntentResponse.failure(error: "\(name) is in sleep mode. Turn the car on and try again."))
            } else {
                self.unlockDoors(name: name, completion: completion)
            }
        }
    }
    
    func unlockDoors(name: String, completion: @escaping (UnlockDoorsIntentResponse) -> Void) {
        APIRouter.shared.get(endpoint: .unlock) { response, error in
            if let error = error {
                if error.code == ResponseError.invalidSession.rawValue {
                    completion(UnlockDoorsIntentResponse.failure(error: "Open the app to login and then try again."))
                } else if error.code == ResponseError.anotherCommand.rawValue {
                    completion(UnlockDoorsIntentResponse.failure(error: "Another remote command is being executed. Please wait for it to finish and try again"))
                } else {
                    completion(UnlockDoorsIntentResponse.failure(error: error.message))
                }
            } else {
                if let headers = response?.headers, let xid = headers["Xid"] {
                    APIRouter.shared.checkActionStatus(xid: xid) { error in
                        if let error = error {
                            completion(UnlockDoorsIntentResponse.failure(error: error.message))
                        } else {
                            completion(UnlockDoorsIntentResponse.success(name: name, locked: 0))
                        }
                    }
                } else {
                    completion(UnlockDoorsIntentResponse.failure(error: "Couldn't unlock doors. Open the app to try again."))
                }
            }
        }
    }
    
    func handle(intent: SetTemperatureIntent, completion: @escaping (SetTemperatureIntentResponse) -> Void) {
        Shortcut.setTemperature.donate()
        self.getVehicleStatus { vehicle, error in
            if let error = error {
                completion(SetTemperatureIntentResponse.failure(error: error))
            } else if let sleepMode = vehicle?.payload?.vehicleInfoList?.first?.lastVehicleInfo?.vehicleStatusRpt?.vehicleStatus?.sleepMode, sleepMode {
                let name = vehicle?.payload?.vehicleInfoList?.first?.lastVehicleInfo?.vehicleNickName ?? vehicle?.payload?.vehicleInfoList?.first?.vehicleConfig?.vehicleDetail?.vehicle?.trim?.modelName ?? "Niro"
                completion(SetTemperatureIntentResponse.failure(error: "\(name) is in sleep mode. Turn the car on and try again."))
            } else if let temp = intent.temperature {
                self.startClimate(temp: Int(truncating: temp), defrost: false, wheel: false, rearDefrost: false, completion: completion)
            }
        }
    }
    
    func resolveTemperature(for intent: SetTemperatureIntent, with completion: @escaping (SetTemperatureTemperatureResolutionResult) -> Void) {
        guard let temperature = intent.temperature else {
               completion(SetTemperatureTemperatureResolutionResult.needsValue())
               return
            }
        completion(SetTemperatureTemperatureResolutionResult.success(with: Int(truncating: temperature)))
    }
    
    func startClimate(temp: Int, defrost: Bool, wheel: Bool, rearDefrost: Bool, completion: @escaping (SetTemperatureIntentResponse) -> Void) {
        var climateDuration = defaults?.integer(forKey: "ClimateDuration") ?? 30
        climateDuration = climateDuration == 0 ? 30 : climateDuration
        let body = [
            "remoteClimate": [
                "airCtrl": true,
                "airTemp": [
                    "unit": 1,
                    "value": "\(temp)"
                ],
                "defrost": defrost,
                "heatingAccessory": [
                    "rearWindow": rearDefrost ? 1 : 0,
                    "sideMirror": 0,
                    "steeringWheel": wheel ? 1 : 0,
                ],
                "ignitionOnDuration": [
                    "unit": 4,
                    "value": climateDuration
                ],
            ]
        ]
        APIRouter.shared.post(endpoint: .startClimate, body: body, authorized: true) { response, error in
            if let error = error {
                if error.code == ResponseError.invalidSession.rawValue {
                    completion(SetTemperatureIntentResponse.failure(error: "Open the app to login and then try again."))
                } else if error.code == ResponseError.anotherCommand.rawValue {
                    completion(SetTemperatureIntentResponse.failure(error: "Another remote command is being executed. Please wait for it to finish and try again"))
                } else {
                    completion(SetTemperatureIntentResponse.failure(error: error.message))
                }
            } else if let headers = response?.headers, let xid = headers["Xid"] {
                APIRouter.shared.checkActionStatus(xid: xid) { error in
                    if let error = error {
                        completion(SetTemperatureIntentResponse.failure(error: error.message))
                    } else {
                        completion(SetTemperatureIntentResponse.success(result: "Set temperature to \(temp) and defrost is \(defrost ? "on" : "off")."))
                    }
                }
            } else {
                completion(SetTemperatureIntentResponse.failure(error: "Couldn't set temperature. Open the app to try again."))
            }
        }
    }
    
    
    func handle(intent: CurrentTemperatureIntent, completion: @escaping (CurrentTemperatureIntentResponse) -> Void) {
        Shortcut.getTemperature.donate()
        self.getVehicleStatus { vehicle, error in
            if let error = error {
                completion(CurrentTemperatureIntentResponse.failure(error: error))
            } else if let vehicle = vehicle {
                self.setTemperature(for: vehicle, completion: completion)
            }
        }
    }
    
    func setTemperature(for vehicle: StatusResponse, completion: @escaping (CurrentTemperatureIntentResponse) -> Void) {
        guard let report = vehicle.payload?.vehicleInfoList?.first?.lastVehicleInfo?.vehicleStatusRpt, let vehicleStatus = report.vehicleStatus else {
            completion(CurrentTemperatureIntentResponse.failure(error: "Couldn't check climate status. Open the app to try again."))
            return
        }
        let name = vehicle.payload?.vehicleInfoList?.first?.lastVehicleInfo?.vehicleNickName ?? vehicle.payload?.vehicleInfoList?.first?.vehicleConfig?.vehicleDetail?.vehicle?.trim?.modelName ?? "Niro"
        
        if let climate = vehicleStatus.climate, let climateOn = climate.airCtrl {
            defaults?.set(climateOn, forKey: "IntentClimateOn")

            if !climateOn {
                completion(CurrentTemperatureIntentResponse.successOff(name: name))
            } else if let tempString = climate.airTemp?.value, let temp = Int(tempString) {
                defaults?.set(temp, forKey: "IntentTemperature")
                
                if let defrost = climate.defrost {
                    defaults?.set(defrost, forKey: "IntentDefrost")
                }
                if let wheel = climate.heatingAccessory?.steeringWheel {
                    defaults?.set(wheel == 1, forKey: "IntentWheelHeat")
                }
                if let rearWindow = climate.heatingAccessory?.rearWindow {
                    defaults?.set(rearWindow == 1, forKey: "IntentWindowHeat")
                }
                completion(CurrentTemperatureIntentResponse.success(name: name, temperature: NSNumber(value:temp)))
            } else {
                completion(CurrentTemperatureIntentResponse.failure(error: "Couldn't check climate status. Open the app to try again."))
            }
        }
    }
    
    func handle(intent: CheckDoorsIntent, completion: @escaping (CheckDoorsIntentResponse) -> Void) {
        Shortcut.getLock.donate()
        self.getVehicleStatus { vehicle, error in
            if let error = error {
                completion(CheckDoorsIntentResponse.failure(error: error))
            } else if let vehicle = vehicle {
                self.setDoors(for: vehicle, completion: completion)
            }
        }
    }
    
    func setDoors(for vehicle: StatusResponse, completion: @escaping (CheckDoorsIntentResponse) -> Void) {
        guard let report = vehicle.payload?.vehicleInfoList?.first?.lastVehicleInfo?.vehicleStatusRpt, let vehicleStatus = report.vehicleStatus else {
            completion(CheckDoorsIntentResponse.failure(error: "Couldn't check door status. Open the app to try again."))
            return
        }
        let name = vehicle.payload?.vehicleInfoList?.first?.lastVehicleInfo?.vehicleNickName ?? vehicle.payload?.vehicleInfoList?.first?.vehicleConfig?.vehicleDetail?.vehicle?.trim?.modelName ?? "Niro"

        if let locked = vehicleStatus.doorLock, let doorStatus = vehicleStatus.doorStatus {
            var doors = ""
            var open = true
            if doorStatus.hood == 0, doorStatus.trunk == 0, doorStatus.frontLeft == 0, doorStatus.frontRight == 0, doorStatus.backLeft == 0, doorStatus.backRight == 0 {
                doors = "doors are closed"
                open = false
            } else if doorStatus.hood != 0 {
                doors = "the hood is open"
            } else if doorStatus.trunk != 0 {
                doors = "the trunk is open"
            } else {
                doors = "doors are open"
            }
            
            let lockedStatus = locked ? "is locked" : "is unlocked"
            
            defaults?.set(open, forKey: "IntentDoorStatus")
            defaults?.set(locked, forKey: "IntentLockStatus")

            completion(CheckDoorsIntentResponse.success(name: name, locks: lockedStatus, doors: doors))
        }
    }
    
    func handle(intent: CurrentLocationIntent, completion: @escaping (CurrentLocationIntentResponse) -> Void) {
        Shortcut.getLocation.donate()
        self.getVehicleStatus { vehicle, error in
            if let error = error {
                completion(CurrentLocationIntentResponse.failure(error: error))
            } else if let vehicle = vehicle {
                self.setLocation(for: vehicle, completion: completion)
            }
        }
    }
    
    func setLocation(for vehicle: StatusResponse, completion: @escaping (CurrentLocationIntentResponse) -> Void) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMddHHmmss"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        
        guard let location = vehicle.payload?.vehicleInfoList?.first?.lastVehicleInfo?.location, let lat = location.coord?.lat, let long = location.coord?.lon else {
            completion(CurrentLocationIntentResponse.failure(error: "Couldn't check location status. Open the app to try again."))
            return
        }
        
        defaults?.set(lat, forKey: "IntentLatitude")
        defaults?.set(long, forKey: "IntentLongitude")

        let name = vehicle.payload?.vehicleInfoList?.first?.lastVehicleInfo?.vehicleNickName ?? vehicle.payload?.vehicleInfoList?.first?.vehicleConfig?.vehicleDetail?.vehicle?.trim?.modelName ?? "Niro"
        
        self.getAddress(latitude: lat, longitude: long) { address in
            completion(CurrentLocationIntentResponse.success(name: name, location: address))
        }
    }
    
    func handle(intent: CurrentChargeIntent, completion: @escaping (CurrentChargeIntentResponse) -> Void) {
        Shortcut.getCharge.donate()
        self.getVehicleStatus { vehicle, error in
            if let error = error {
                completion(CurrentChargeIntentResponse.failure(error: error))
            } else if let vehicle = vehicle {
                self.setCharge(for: vehicle, completion: completion)
            }
        }
    }
    
    func setCharge(for vehicle: StatusResponse, completion: @escaping (CurrentChargeIntentResponse) -> Void) {
        guard let report = vehicle.payload?.vehicleInfoList?.first?.lastVehicleInfo?.vehicleStatusRpt, let vehicleStatus = report.vehicleStatus else {
            completion(CurrentChargeIntentResponse.failure(error: "Couldn't check charge status. Open the app to try again."))
            return
        }
        
        if let evStatus = vehicleStatus.evStatus, let targetSocAC = evStatus.targetSOC?[1].targetSOClevel, let targetSocDC = evStatus.targetSOC?[0].targetSOClevel, let charge = evStatus.batteryStatus, let isCharging = evStatus.batteryCharge, let pluggedIn = evStatus.batteryPlugin, let chargeTime = evStatus.remainChargeTime?.first?.timeInterval?.value, let drvDistance = vehicleStatus.evStatus?.drvDistance?.first, let range = drvDistance.rangeByFuel?.totalAvailableRange?.value {
            let name = vehicle.payload?.vehicleInfoList?.first?.lastVehicleInfo?.vehicleNickName ?? vehicle.payload?.vehicleInfoList?.first?.vehicleConfig?.vehicleDetail?.vehicle?.trim?.modelName ?? "Niro"
            
            defaults?.set(charge, forKey: "IntentChargeState")
            defaults?.set(isCharging, forKey: "IntentIsCharging")
            defaults?.set(pluggedIn, forKey: "IntentIsPluggedIn")
            defaults?.set(targetSocAC, forKey: "IntentTargetSOCAC")
            defaults?.set(targetSocDC, forKey: "IntentTargetSOCDC")
            defaults?.set(chargeTime, forKey: "IntentChargeTime")
            defaults?.set(range, forKey: "IntentDriveRange")

            completion(CurrentChargeIntentResponse.success(name: name, range: NSNumber(value: range), percentage: NSNumber(value: charge)))
        }
    }
    
    func getVehicleStatus(completion: @escaping (StatusResponse?, String?) -> Void) {
        func getStatus() {
            APIRouter.shared.post(endpoint: .status, body: ["vehicleConfigReq": [
                "airTempRange": "0",
                "maintenance": "0",
                "seatHeatCoolOption": "1",
                "vehicle": "1",
                "vehicleFeature": "0"
            ], "vehicleInfoReq": [
                "drivingActivty": "1",
                "dtc": "1",
                "enrollment": "1",
                "functionalCards": "0",
                "location": "1",
                "vehicleStatus": "1",
                "weather": "1"],
                "vinKey": [APIRouter.shared.vinKey]], authorized: true) { [weak self] response, error in
                guard let self = self else { return }
                if let data = response?.data, let vehicle = try? APIRouter.shared.jsonDecoder.decode(StatusResponse.self, from: data) {
                    self.updateStatus()
                    completion(vehicle, nil)
                }
            }
        }
        
        func getVehicle() {
            APIRouter.shared.get(endpoint: .vehicles) { response, error in
                if let data = response?.data, let vehicles = try? APIRouter.shared.jsonDecoder.decode(VehiclesResponse.self, from: data), let vinKey = vehicles.payload?.vehicleSummary?.first?.vehicleKey {
                    APIRouter.shared.vinKey = vinKey
                    getStatus()
                } else {
                    completion(nil, "Open the app to login and then try again.")
                }
            }
        }
        
        if APIRouter.shared.sessionId == nil {
            if let username = keychain.string(forKey: .usernameKey), let password = keychain.string(forKey: .passwordKey) {
                APIRouter.shared.login(username: username, password: password) { error in
                    if let error = error {
                        completion(nil, error)
                    } else {
                        getVehicle()
                    }
                }
            } else {
                completion(nil, "Open the app to login and then try again.")
            }
        } else {
            getVehicle()
        }
    }
    
    func updateStatus() {
        APIRouter.shared.post(endpoint: .updateStatus, body: ["requestType":0], authorized: true) { _,_ in }
    }
    
    func getAddress(latitude: Double, longitude: Double, completion: @escaping (String) -> ()) {
        var center : CLLocationCoordinate2D = CLLocationCoordinate2D()
        let ceo: CLGeocoder = CLGeocoder()
        center.latitude = latitude
        center.longitude = longitude
        
        let loc: CLLocation = CLLocation(latitude:center.latitude, longitude: center.longitude)
        
        ceo.reverseGeocodeLocation(loc, completionHandler:
                                    {(placemarks, error) in
            if let message = error?.localizedDescription {
                log.error("reverse geodcode fail: \(message)")
            }
            let pm = placemarks! as [CLPlacemark]
            
            if pm.count > 0 {
                let pm = placemarks![0]
                if let name = pm.name {
                    completion("\(name)")
                } else if let name = pm.name, let subThoroughfare = pm.subThoroughfare, let thoroughfare = pm.thoroughfare, let locality = pm.locality, let admin = pm.administrativeArea, let zip = pm.postalCode {
                    completion("\(name) \(subThoroughfare) \(thoroughfare) \(locality), \(admin) \(zip)")
                } else if let subThoroughfare = pm.subThoroughfare, let thoroughfare = pm.thoroughfare, let locality = pm.locality, let admin = pm.administrativeArea, let zip = pm.postalCode {
                    completion("\(subThoroughfare) \(thoroughfare) \(locality), \(admin) \(zip)")
                } else if let subThoroughfare = pm.subThoroughfare, let thoroughfare = pm.thoroughfare {
                    completion("\(subThoroughfare) \(thoroughfare)")
                } else {
                    completion("Latitude \(latitude) and longitude \(longitude)")
                }
            }
        })
    }
    
}
