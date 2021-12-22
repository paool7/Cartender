//
//  ViewController.swift
//  Cartender
//
//  Created by Paul Dippold on 11/15/21.
//

import UIKit
import SwiftHTTP
import MapKit
import Contacts
import SwiftKeychainWrapper

class ViewController: UIViewController {
    @IBOutlet var batteryContainer: ProgressBar!
    @IBOutlet var mapView: MKMapView!
    @IBOutlet var wheelButton: UIButton!
    @IBOutlet var seatButton: UIButton!
    @IBOutlet var defrostButton: UIButton!
    @IBOutlet var carView: UIImageView!
    @IBOutlet var chargeStepper: UIStepper!
    @IBOutlet var chargeRatioLabel: UILabel!
    @IBOutlet var chargeTimeLabel: UILabel!
    @IBOutlet var chargeStatusLabel: UILabel!
    @IBOutlet var odometerLabel: UILabel!
    @IBOutlet var rangeLabel: UILabel!
    @IBOutlet var lockUnlockButton: UIButton!
    @IBOutlet var tempDownButton: UIButton!
    @IBOutlet var tempLabel: UIButton!
    @IBOutlet var tempUpButton: UIButton!
    @IBOutlet var chargeSwitch: UISwitch!
    @IBOutlet var climateSwitch: UISwitch!
    @IBOutlet var chargeIcon: UIImageView!
    @IBOutlet var lockLabel: UILabel!
    @IBOutlet var nicknameLabel: UILabel!
    @IBOutlet var doorLabel: UILabel!
    @IBOutlet var setButton: UIButton!
    @IBOutlet var locationLabel: UILabel!
    
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    @IBOutlet var syncTimeLabel: UILabel!
    @IBOutlet var syncButton: UIButton!
    
    @IBOutlet var containerView: UIView!
    @IBOutlet var containerView2: UIView!
    @IBOutlet var containerView3: UIView!
    @IBOutlet var containerView4: UIView!
    @IBOutlet var containerView5: UIView!
    
    let jsonDecoder = JSONDecoder()
    
    var isSyncing = false {
        didSet {
            DispatchQueue.main.async {
                self.activityIndicator.isHidden = !self.isSyncing
                self.syncTimeLabel.isHidden = self.isSyncing
                self.syncButton.isHidden = self.isSyncing
                if !self.isSyncing {
                    self.activityIndicator.stopAnimating()
                } else {
                    self.activityIndicator.startAnimating()
                }
            }
        }
    }
    
    var isLocked = true {
        didSet {
            DispatchQueue.main.async {
                self.lockUnlockButton.alpha = 1.0
                self.lockUnlockButton.isEnabled = true
                self.lockUnlockButton.setImage(UIImage(named: !self.isLocked ? "Lock" : "Unlock"), for: .normal)
                self.lockLabel.text = !self.isLocked ? "Unlocked" : "Locked"
                self.lockLabel.textColor = !self.isLocked ? self.redColor : UIColor(named: "BodyColor")
            }
        }
    }
    var temp: Int = 0 {
        didSet {
            DispatchQueue.main.async {
                if self.temp == 0 {
                    self.tempLabel.setTitle("", for: .normal)
                } else {
                    self.tempLabel.setTitle(" \(self.temp)°", for: .normal)
                    self.climateSwitch.onTintColor = self.temp > 69 ? self.redColor : self.blueColor
                }
            }
        }
    }
    let lightRedColor = UIColor(red: 222/255.0, green: 26/255.0, blue: 26/255.0, alpha: 1.0)
    let redColor = UIColor(red: 222/255.0, green: 26/255.0, blue: 26/255.0, alpha: 0.80)
    let blueColor = UIColor(red: 158/255.0, green: 183/255.0, blue: 229/255.0, alpha: 0.80)
    let yellowColor = UIColor(red: 247/255.0, green: 231/255.0, blue: 51/255.0, alpha: 0.80)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let backgroundColor = UserDefaults.standard.colorFor(key: "BackgroundColor") {
            self.view.backgroundColor = backgroundColor
        }
        if let secondaryBackgroundColor = UserDefaults.standard.colorFor(key: "SecondaryBackgroundColor") {
            self.containerView.backgroundColor = secondaryBackgroundColor
            self.containerView2.backgroundColor = secondaryBackgroundColor
            self.containerView3.backgroundColor = secondaryBackgroundColor
            self.containerView4.backgroundColor = secondaryBackgroundColor
            self.containerView5.backgroundColor = secondaryBackgroundColor
        }
        
        APIRouter.shared.logoutHandler = {
            self.login {
                self.getVehicles(completion: nil)
            }
        }
        
        NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { [unowned self] notification in
            if APIRouter.shared.sessionId == nil {
                self.login {
                    self.getVehicles(completion: nil)
                }
            } else {
                self.getVehicles(completion: nil)
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        wheelButton.layer.cornerRadius = wheelButton.frame.width/2
        seatButton.layer.cornerRadius = seatButton.frame.width/2
        defrostButton.layer.cornerRadius = defrostButton.frame.width/2
        lockUnlockButton.layer.cornerRadius = lockUnlockButton.frame.width/2
    }
    
    @IBAction func tappedHeatedSeat(_ sender: UIButton) {
        self.setButton.isHidden = false
        sender.isSelected.toggle()
        if !sender.isSelected {
            self.seatButton.tintColor = .white
        } else {
            self.seatButton.tintColor = lightRedColor
        }
    }
    
    @IBAction func tappedHeatedWheel(_ sender: UIButton) {
        self.setButton.isHidden = false
        sender.isSelected.toggle()
        if !sender.isSelected {
            self.wheelButton.tintColor = .white
        } else {
            self.wheelButton.tintColor = lightRedColor
        }
    }
    
    @IBAction func tappedDefrost(_ sender: UIButton) {
        self.setButton.isHidden = false
        sender.isSelected.toggle()
        if !sender.isSelected {
            self.defrostButton.tintColor = .white
        } else {
            self.defrostButton.tintColor = lightRedColor
        }
    }
    
    @IBAction func tappedTempDown(_ sender: UIButton) {
        self.setButton.isHidden = false
        if temp > 62 {
            temp-=1
        }
    }
    
    @IBAction func tappedTempUp(_ sender: UIButton) {
        self.setButton.isHidden = false
        if temp < 82 {
            temp+=1
        }
    }
    
    @IBAction func setClimate() {
        self.setButton.isHidden = true
        self.startClimate {
            self.updateStatus()
        }
    }
    
    @IBAction func tappedLockUnlock(_ sender: UIButton) {
        self.lockUnlockButton.alpha = 0.5
        self.lockUnlockButton.isEnabled = false
        self.lockLabel.text = isLocked ? "Unlocking..." : "Locking..."
        self.setLock(lock: !isLocked)
    }
    
    @IBAction func stepperChanged(_ sender: Any) {
        self.setButton.isHidden = false
        let chargeRatio = Int(chargeStepper.value)
        self.batteryContainer.target = chargeStepper.value/100
        chargeRatioLabel.text = "\(chargeRatio)%"
    }
    
    @IBAction func switchedCharge(_ sender: UISwitch) {
        if sender.isOn {
            self.startCharge {
                self.setChargeStatus(true)
            }
        } else {
            self.stopCharge {
                self.setChargeStatus(false)
            }
        }
    }
    
    func login(completion: (() -> ())?) {
            if let username = KeychainWrapper.standard.string(forKey: .usernameKey), let password = KeychainWrapper.standard.string(forKey: .passwordKey) {
                APIRouter.shared.login(username: username, password: password) { [weak self] error in
                    if let error = error {
                        let errorAlert = UIAlertController(title: "Error", message: error, preferredStyle: .alert)
                        let errorAction = UIAlertAction(title: "Ok", style: .cancel) { _ in
                            self?.login(completion: completion)
                        }
                        errorAlert.addAction(errorAction)
                        
                        DispatchQueue.main.async {
                            self?.present(errorAlert, animated: true, completion: nil)
                        }
                    } else {
                        self?.getVehicles(completion: completion)
                    }
                }
            } else {
                var usernameField = UITextField()
                var passwordField = UITextField()
                
                let alert = UIAlertController(title: "Login", message: "Your login information is stored securely on your device is only sent to Kia to login.", preferredStyle: .alert)
                alert.addTextField { alertTextField in
                    alertTextField.placeholder = "Username"
                    usernameField = alertTextField
                }
                alert.addTextField { alertTextField in
                    alertTextField.placeholder = "Password"
                    alertTextField.isSecureTextEntry = true
                    passwordField = alertTextField
                }
                
                let action = UIAlertAction(title: "Done", style: .default) { action in
                    if let username = usernameField.text, let password = passwordField.text {
                        APIRouter.shared.login(username: username, password: password) { [weak self] error in
                            if let error = error {
                                let errorAlert = UIAlertController(title: "Error", message: error, preferredStyle: .alert)
                                let errorAction = UIAlertAction(title: "Ok", style: .cancel) { _ in
                                    self?.login(completion: completion)
                                }
                                errorAlert.addAction(errorAction)
                                
                                DispatchQueue.main.async {
                                    self?.present(errorAlert, animated: true, completion: nil)
                                }
                            } else {
                                KeychainWrapper.standard.set(username, forKey: .usernameKey)
                                KeychainWrapper.standard.set(password, forKey: .passwordKey)
                                self?.getVehicles(completion: completion)
                            }
                        }
                    }
                }
                
                alert.addAction(action)
                DispatchQueue.main.async {
                    self.present(alert, animated: true, completion: nil)
                }
            }
    }
    
    func setChargeStatus(_ isOn: Bool) {
        DispatchQueue.main.async {
            self.chargeIcon.isHidden = isOn ? false : true
            self.chargeStepper.alpha = isOn ? 1.0 : 0.5
            self.chargeStepper.isEnabled = isOn ? true : false
        }
    }
    
    func setChargeDetails(charging: Bool, pluggedIn: Bool, ratio: Int, chargeTime: Int) {
        var chargeString = ""
        if pluggedIn {
            chargeStepper.isHidden = false
            chargeStepper.value = Double(ratio)
            chargeSwitch.isEnabled = true
            if charging {
                if chargeTime == 0 {
                    chargeString.append("Charged to: \(ratio)%")
                } else {
                    chargeRatioLabel.text = "\(ratio)%"
                    let chargeHours = chargeTime/60
                    let chargeMinutes = chargeTime-(chargeHours*60)
                    let unit = chargeHours == 1 ? "hr" : "hrs"
                    let minuteUnit = chargeHours == 1 ? "min" : "mins"
                    let minuteString = chargeMinutes > 0 ? " \(chargeMinutes) \(minuteUnit)" : ""
                    chargeString.append("\n\(chargeHours) \(unit)\(minuteString)")
                }
            } else {
                chargeString.append("Plugged In\nNot Charging")
            }
        } else {
            chargeSwitch.isEnabled = false
            chargeStepper.isHidden = true
            chargeString.append("Unplugged")
        }
        chargeTimeLabel.text = chargeString
    }
    
    @IBAction func switchedClimate(_ sender: UISwitch) {
        setClimateStatus(sender.isOn)
        if !sender.isOn {
            self.stopClimate {}
        }
    }
    
    func setClimateStatus(_ isOn: Bool) {
        climateSwitch.isEnabled = true
        climateSwitch.isOn = isOn
        if isOn {
            tempUpButton.alpha = 1.0
            tempDownButton.alpha = 1.0
            defrostButton.alpha = 1.0
            seatButton.alpha = 1.0
            wheelButton.alpha = 1.0
            tempLabel.alpha = 1.0
            
            tempUpButton.isEnabled = true
            tempDownButton.isEnabled = true
            defrostButton.isEnabled = true
            seatButton.isEnabled = true
            wheelButton.isEnabled = true
        } else {
            tempUpButton.alpha = 0.5
            tempDownButton.alpha = 0.5
            defrostButton.alpha = 0.5
            seatButton.alpha = 0.5
            wheelButton.alpha = 0.5
            tempLabel.alpha = 0.5
            
            tempLabel.isEnabled = false
            tempUpButton.isEnabled = false
            tempDownButton.isEnabled = false
            defrostButton.isEnabled = false
            seatButton.isEnabled = false
            wheelButton.isEnabled = false
        }
    }
    
    func getVehicles(completion: (() -> ())?) {
        self.isSyncing = true
        APIRouter.shared.get(endpoint: .vehicles) { [weak self] response in
            if let vehicles = try? self?.jsonDecoder.decode(VehiclesResponse.self, from: response.data) {
                if let imageName = vehicles.payload?.vehicleSummary?.first?.imagePath?.imageName, let imagePath = vehicles.payload?.vehicleSummary?.first?.imagePath?.imagePath {
                    let urlString = APIRouter().getImage(name: imageName, path: imagePath)
                    if let url = URL(string: urlString) {
                        DispatchQueue.global().async {
                            let data = try? Data(contentsOf: url)
                            DispatchQueue.main.async {
                                self?.carView.contentMode = .scaleAspectFill
                                self?.carView.image = UIImage(data: data!)
                            }
                        }
                    }
                    completion?()
                }
                if let vinKey = vehicles.payload?.vehicleSummary?.first?.vehicleKey {
                    APIRouter.shared.vinKey = vinKey
                    self?.vehicleStatus(token: vinKey)
                }
            }
        }
    }
    
    @IBAction func sync() {
        self.updateStatus()
    }
    
    func updateStatus() {
        self.isSyncing = true
        APIRouter.shared.post(endpoint: .updateStatus, body: ["requestType":0], authorized: true) { [weak self] response in
            if let vehicle = try? self?.jsonDecoder.decode(UpdateStatusResponse.self, from: response.data) {
                DispatchQueue.main.async {
                    guard let report = vehicle.payload?.vehicleStatusRpt, let vehicleStatus = report.vehicleStatus else { return }
                    self?.set(vehicleStatus: vehicleStatus, syncDateUTC: report.reportDate?.utc)
                    self?.isSyncing = false
                }
            }
        }
    }
    
    func vehicleStatus(token: String) {
        self.isSyncing = true
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
            "weather": "0"],
            "vinKey": [token]], authorized: true) { [weak self] response in
            guard let self = self else { return }
            if let vehicle = try? self.jsonDecoder.decode(StatusResponse.self, from: response.data) {
                self.updateStatus()
                DispatchQueue.main.async {
                    guard let report = vehicle.payload?.vehicleInfoList?.first?.lastVehicleInfo?.vehicleStatusRpt, let vehicleStatus = report.vehicleStatus else { return }
                    self.set(vehicleStatus: vehicleStatus, syncDateUTC: report.reportDate?.utc)
                    if let name = vehicle.payload?.vehicleInfoList?.first?.lastVehicleInfo?.vehicleNickName {
                        self.nicknameLabel.text = name
                    }
                    if let mileage = vehicle.payload?.vehicleInfoList?.first?.vehicleConfig?.vehicleDetail?.vehicle?.mileage {
                        self.odometerLabel.text = "\(mileage)mi"
                    }
                    if let location = vehicle.payload?.vehicleInfoList?.first?.lastVehicleInfo?.location, let lat = location.coord?.lat, let long = location.coord?.lon, let driving = vehicleStatus.engine {
                        let center = CLLocationCoordinate2D(latitude: CLLocationDegrees(lat), longitude: CLLocationDegrees(long))
                        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005))
                        self.getAddress(latitude: lat, longitude: long) { address in
                            let annotation = MKPointAnnotation()
                            annotation.coordinate = center
                            annotation.title = !driving ? "\(address)\nParked" : "\(address)"
                            self.mapView.addAnnotation(annotation)
                        }
                        self.mapView.setRegion(region, animated: true)
                        
                        let formatter = DateFormatter()
                        formatter.dateFormat = "yyyyMMddHHmmss"
                        formatter.timeZone = TimeZone(abbreviation: "UTC")
                        if let syncDateUTC = location.syncDate?.utc, let syncDate = formatter.date(from: syncDateUTC) {
                            formatter.timeZone = TimeZone.current
                            if Calendar.current.isDateInToday(syncDate) {
                                formatter.dateFormat = "h:mm a"
                            } else {
                                formatter.dateFormat = "MM/dd, h:mm a"
                            }
                            let dateString = formatter.string(from: syncDate)
                            self.locationLabel.text = "At \(dateString)"
                        }
                    }
                }
            }
        }
    }
    
    func set(vehicleStatus: VehicleStatus, syncDateUTC: String?) {
        if let evStatus = vehicleStatus.evStatus, let targetSoc = evStatus.targetSOC?[1].targetSOClevel, let charge = evStatus.batteryStatus, let isCharging = evStatus.batteryCharge, let pluggedIn = evStatus.batteryPlugin, let chargeTime = evStatus.remainChargeTime?.first?.timeInterval?.value {
            self.chargeStatusLabel.text = "\(charge)%"
            self.batteryContainer.progress = CGFloat(charge)/100.0
            self.chargeIcon.isHidden = !isCharging
            self.chargeSwitch.isOn = isCharging
            self.setChargeStatus(isCharging)
            self.setChargeDetails(charging: isCharging, pluggedIn: pluggedIn != 0, ratio: targetSoc, chargeTime: chargeTime)
        }
        if let climate = vehicleStatus.climate,let climateOn = climate.airCtrl {
            self.setClimateStatus(climateOn)
            self.temp = Int(climate.airTemp?.value ?? "0") ?? 0
        }
        if let locked = vehicleStatus.doorLock {
            self.isLocked = locked
        }
        if let drvDistance = vehicleStatus.evStatus?.drvDistance?.first, let range = drvDistance.rangeByFuel?.totalAvailableRange?.value {
            self.rangeLabel.text = "\(range)mi"
        }
        if let doorStatus = vehicleStatus.doorStatus {
            if doorStatus.hood == 0, doorStatus.trunk == 0, doorStatus.frontLeft == 0, doorStatus.frontRight == 0, doorStatus.backLeft == 0, doorStatus.backRight == 0 {
                self.doorLabel.text = "Doors Closed"
            } else if doorStatus.hood != 0 {
                self.doorLabel.text = "Hood Open"
            } else if doorStatus.trunk != 0 {
                self.doorLabel.text = "Trunk Open"
            } else {
                self.doorLabel.text = "Door Open"
            }
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMddHHmmss"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        if let syncDateUTC = syncDateUTC, let syncDate = formatter.date(from: syncDateUTC) {
            formatter.timeZone = TimeZone.current
            if Calendar.current.isDateInToday(syncDate) {
                formatter.dateFormat = "h:mm a"
            } else {
                formatter.dateFormat = "MM/dd, h:mm a"
            }
            let dateString = formatter.string(from: syncDate)
            self.syncTimeLabel.text = "Synced \(dateString)"
        }
    }
    
    func setLock(lock: Bool) {
        self.isSyncing = true
        APIRouter.shared.get(endpoint: lock ? .lock : .unlock) { [weak self] response in
            if let text = response.text, text.contains(":1003") {
                APIRouter.shared.sessionId = nil
                self?.login {
                    self?.getVehicles {
                        self?.setLock(lock: lock)
                    }
                }
            } else {
                if let headers = response.headers, let xid = headers["Xid"] {
                    APIRouter.shared.checkActionStatus(xid: xid) { [weak self] in
                        self?.isSyncing = false
                        self?.isLocked = lock
                    }
                }
            }
        }
    }
    
    func setChargeLimit(completion: @escaping () -> ()) {
        self.isSyncing = true
        let chargeLimit = Int(self.chargeStepper.value*100)
        APIRouter.shared.post(endpoint: .setChargeLimit, body: [
            "targetSOClist": [
                [
                    "plugType": 0,
                    "targetSOClevel": chargeLimit,
                ],
                [
                    "plugType": 1,
                    "targetSOClevel": chargeLimit,
                ],
            ]
        ], authorized: true) { [weak self] response in
            if let headers = response.headers, let xid = headers["Xid"] {
                APIRouter.shared.checkActionStatus(xid: xid) {
                    self?.isSyncing = false
                    completion()
                }
            }
        }
    }
    
    func startCharge(completion: @escaping () -> ()) {
        self.isSyncing = true
        APIRouter.shared.post(endpoint: .startCharge, body: ["chargeRatio": 100], authorized: true) { [weak self] response in
            if let headers = response.headers, let xid = headers["Xid"] {
                APIRouter.shared.checkActionStatus(xid: xid) {
                    self?.isSyncing = false
                    completion()
                }
            }
        }
    }
    
    func stopCharge(completion: @escaping () -> ()) {
        self.isSyncing = true
        APIRouter.shared.get(endpoint: .stopCharge) { [weak self] response in
            if let headers = response.headers, let xid = headers["Xid"] {
                APIRouter.shared.checkActionStatus(xid: xid) {
                    self?.isSyncing = false
                    completion()
                }
            }
        }
    }
    
    func startClimate(completion: @escaping () -> ()) {
        self.isSyncing = true
        let body = [
            "remoteClimate": [
                "airCtrl": true,
                "airTemp": [
                    "unit": 1,
                    "value": "\(self.temp)"
                ],
                "defrost": self.defrostButton.isSelected,
                "heatingAccessory": [
                    "rearWindow": 0,
                    "sideMirror": 0,
                    "steeringWheel": self.wheelButton.isSelected ? 1 : 0,
                    "heatVentSeat": 1
                ],
                "ignitionOnDuration": [
                    "unit": 4,
                    "value": 5
                ],
            ]
        ]
        APIRouter.shared.post(endpoint: .startClimate, body: body, authorized: true) { [weak self] response in
            if let headers = response.headers, let xid = headers["Xid"] {
                APIRouter.shared.checkActionStatus(xid: xid) {
                    self?.isSyncing = false
                    completion()
                }
            }
        }
    }
    
    func stopClimate(completion: @escaping () -> ()) {
        self.isSyncing = true
        APIRouter.shared.get(endpoint: .stopClimate) { [weak self] response in
            if let headers = response.headers, let xid = headers["Xid"] {
                APIRouter.shared.checkActionStatus(xid: xid) {
                    self?.isSyncing = false
                    completion()
                }
            }
        }
    }
    
    func getAddress(latitude: Double, longitude: Double, completion: @escaping (String) -> ()) {
        var center : CLLocationCoordinate2D = CLLocationCoordinate2D()
        let ceo: CLGeocoder = CLGeocoder()
        center.latitude = latitude
        center.longitude = longitude
        
        let loc: CLLocation = CLLocation(latitude:center.latitude, longitude: center.longitude)
        
        ceo.reverseGeocodeLocation(loc, completionHandler:
                                    {(placemarks, error) in
            if (error != nil)
            {
                print("reverse geodcode fail: \(error!.localizedDescription)")
            }
            let pm = placemarks! as [CLPlacemark]
            
            if pm.count > 0 {
                let pm = placemarks![0]
                if let subThoroughfare = pm.subThoroughfare, let thoroughfare = pm.thoroughfare {
                    completion("\(subThoroughfare) \(thoroughfare)")
                } else {
                    completion("")
                }
            }
        })
        
    }
}

extension Dictionary {
    var json: Data? {
        guard let theJSONData = try? JSONSerialization.data(withJSONObject: self, options: [.prettyPrinted]) else {
            return nil
        }
        
        return theJSONData
        //return String(data: theJSONData, encoding: .ascii)
    }
}

extension String {
    static let usernameKey = "CartenderUserId"
    static let passwordKey = "CartenderUserPass"
}
