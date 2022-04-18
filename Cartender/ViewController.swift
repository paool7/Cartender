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
import Intents
import IntentsUI
import NotificationBannerSwift

class ViewController: UIViewController, INUIAddVoiceShortcutButtonDelegate, INUIAddVoiceShortcutViewControllerDelegate, INUIEditVoiceShortcutViewControllerDelegate {
    
    @IBOutlet var batteryContainer: ProgressBar!
    @IBOutlet var mapView: MKMapView!
    @IBOutlet var climateButton: UIButton!
    @IBOutlet var chargeButton: UIButton!
    @IBOutlet var chargeTimeLabel: UILabel!
    @IBOutlet var chargeStatusLabel: UILabel!
    @IBOutlet var odometerLabel: UILabel!
    @IBOutlet var rangeLabel: UILabel!
    @IBOutlet var lockUnlockButton: UIButton!
    @IBOutlet var tempDownButton: UIButton!
    @IBOutlet var tempLabel: UIButton!
    @IBOutlet var tempUpButton: UIButton!
    @IBOutlet var lockLabel: UILabel!
    @IBOutlet var nicknameLabel: UILabel!
    @IBOutlet var doorLabel: UILabel!
    @IBOutlet var backgroundImageView: UIImageView!
    @IBOutlet var settingsButton: UIButton!
    @IBOutlet var shortcutStackView: UIStackView!
    @IBOutlet var showMoreArrow: UIImageView!
    @IBOutlet var heatedButton: UIButton!
    @IBOutlet var defrostButton: UIButton!

    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    @IBOutlet var syncTimeLabel: UILabel!
    @IBOutlet var syncButton: UIButton!
    
    var name = "Niro"
    var latitude: Double?
    var longitude: Double?
    var showAllShortcuts = false
    var climateOn = false
    
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
                let config = UIImage.SymbolConfiguration(scale: .medium)
                self.lockUnlockButton.setImage(UIImage(systemName: !self.isLocked ? "lock" : "lock.open", withConfiguration: config), for: .normal)
                self.lockUnlockButton.setTitle(self.isLocked ? "Unlock" : "Lock", for: .normal)
                self.lockLabel.text = !self.isLocked ? "Unlocked" : "Locked"
                self.lockLabel.textColor = !self.isLocked ? .systemRed : .white
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
                    //self.climateSwitch.onTintColor = self.temp > 69 ? self.redColor : self.blueColor
                }
            }
        }
    }
    
    var chargeMax = 50 {
        didSet {
            DispatchQueue.main.async {
                self.batteryContainer.target = CGFloat(self.chargeMax)/100.0
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { [unowned self] notification in
            if APIRouter.shared.sessionId == nil {
                self.login {}
            } else {
                self.getVehicles(completion: nil)
            }
        }
        
        APIRouter.shared.logoutHandler = {
            self.login {}
        }
        
        for i in 0..<Shortcut.allCases.count {
            self.addButtonFor(Shortcut.allCases[i])
            if i < 2 {
                self.shortcutStackView.arrangedSubviews[i].isHidden = false
            }
        }
        
        self.backgroundImageView.image = UIImage(named: "Drive-\(Calendar.current.component(.weekday, from: Date()))")

        syncButton.tintColor = .systemCyan
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        chargeButton.layer.cornerRadius = chargeButton.frame.height/2
        climateButton.layer.cornerRadius = climateButton.frame.height/2
        lockUnlockButton.layer.cornerRadius = lockUnlockButton.frame.height/2
        heatedButton.layer.cornerRadius = heatedButton.frame.width/2
        defrostButton.layer.cornerRadius = defrostButton.frame.width/2
        tempUpButton.layer.cornerRadius = tempUpButton.frame.width/2
        tempDownButton.layer.cornerRadius = defrostButton.frame.width/2
    }
    
    @IBAction func tappedHeatedWheel(_ sender: UIButton) {
        sender.isSelected.toggle()
        if !sender.isSelected {
            self.heatedButton.tintColor = .white
        } else {
            self.heatedButton.tintColor = .systemRed
        }
    }
    
    @IBAction func tappedDefrost(_ sender: UIButton) {
        sender.isSelected.toggle()
        if !sender.isSelected {
            self.defrostButton.tintColor = .white
        } else {
            self.defrostButton.tintColor = .systemRed
        }
    }
    
    @IBAction func tappedTempDown(_ sender: UIButton) {
        if temp > 62 {
            temp-=1
        }
    }
    
    @IBAction func tappedTempUp(_ sender: UIButton) {
        if temp < 82 {
            temp+=1
        }
    }
    
    @IBAction func tappedLockUnlock(_ sender: UIButton) {
        self.lockUnlockButton.alpha = 0.5
        self.lockUnlockButton.isEnabled = false
        self.lockLabel.text = isLocked ? "Unlocking..." : "Locking..."
        self.setLock(lock: !isLocked)
    }
    
    @IBAction func switchedCharge(_ sender: UIButton) {
        sender.isSelected.toggle()
        if sender.isSelected {
            self.startCharge {
                self.setChargeStatus(true, true)
            }
        } else {
            self.stopCharge {
                self.setChargeStatus(false, true)
            }
        }
    }
    
    func login(completion: (() -> ())?) {
        if let username = keychain.string(forKey: .usernameKey), let password = keychain.string(forKey: .passwordKey) {
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
                
                let alert = UIAlertController(title: "Login", message: "Your login information is stored securely on your device and is only sent to Kia to login.", preferredStyle: .alert)
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
    
    func setChargeStatus(_ isOn: Bool, _ pluggedIn: Bool) {
        DispatchQueue.main.async {
            let config = UIImage.SymbolConfiguration(scale: .medium)
            if pluggedIn {
                self.chargeButton.setImage(UIImage(systemName: !isOn ? "bolt" : "bolt.slash", withConfiguration: config), for: .normal)
                self.chargeButton.setTitle(!isOn ? "Start" : "Stop", for: .normal)
            } else {
                self.chargeButton.setImage(nil, for: .normal)
                self.chargeButton.setTitle("Unplugged", for: .normal)
            }
            self.chargeButton.alpha = isOn ? 1.0 : 0.5
            self.chargeButton.isEnabled = isOn ? true : false
        }
    }
    
    func setChargeDetails(charging: Bool, pluggedIn: Bool, ratio: Int, chargeTime: Int) {
        var chargeString = ""
        self.chargeMax = ratio
        self.setChargeStatus(charging, pluggedIn)
        if pluggedIn {
            if charging {
                if chargeTime == 0 {
                    chargeString.append("Charged to: \(ratio)%")
                } else {
                    let chargeHours = chargeTime/60
                    let chargeMinutes = chargeTime-(chargeHours*60)
                    let unit = chargeHours == 1 ? "hr" : "hrs"
                    let minuteUnit = chargeHours == 1 ? "min" : "mins"
                    let minuteString = chargeMinutes > 0 ? " \(chargeMinutes) \(minuteUnit)" : ""
                    chargeString.append("\(chargeHours) \(unit)\(minuteString) to")
                }
            } else {
                chargeString.append("Not Charging")
            }
            self.chargeTimeLabel.isHidden = false
        } else {
            self.chargeTimeLabel.isHidden = true
            self.chargeButton.alpha = 0.5
            self.chargeButton.isEnabled = false
        }
        chargeTimeLabel.text = chargeString
    }
    
    @IBAction func switchedClimate(_ sender: UIButton) {
        self.chargeButton.alpha = 0.5
        self.chargeButton.isEnabled = false
        if !climateOn {
            self.startClimate(completion: nil)
        } else {
            if !sender.isSelected {
                self.stopClimate(completion: nil)
            }
        }
    }
    
    func setClimateStatus(_ isOn: Bool) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.climateButton.isEnabled = true
            self.climateButton.alpha = 1.0
            self.climateButton.setTitle(isOn ? "Stop" : "Start", for: .normal)
            self.climateOn = isOn
            self.tempUpButton.alpha = 1.0
            self.tempDownButton.alpha = 1.0
            self.tempLabel.alpha = 1.0
            self.heatedButton.alpha = 1.0
            self.defrostButton.alpha = 1.0
            
            self.heatedButton.isEnabled = true
            self.defrostButton.isEnabled = true
            self.tempUpButton.isEnabled = true
            self.tempDownButton.isEnabled = true
        }
    }
    
    func getVehicles(completion: (() -> ())?) {
        self.isSyncing = true
        APIRouter.shared.get(endpoint: .vehicles) { [weak self] response, error in
            if let data = response?.data, let vehicles = try? APIRouter.shared.jsonDecoder.decode(VehiclesResponse.self, from: data), let vinKey = vehicles.payload?.vehicleSummary?.first?.vehicleKey {
                    APIRouter.shared.vinKey = vinKey
                    self?.vehicleStatus()
            }
            completion?()
        }
    }
    
    @IBAction func sync() {
        self.updateStatus()
    }
    
    func updateStatus() {
        self.isSyncing = true
        APIRouter.shared.post(endpoint: .updateStatus, body: ["requestType":0], authorized: true) { [weak self] response, error in
            if let data = response?.data, let vehicle = try? APIRouter.shared.jsonDecoder.decode(UpdateStatusResponse.self, from: data) {
                DispatchQueue.main.async {
                    self?.isSyncing = false
                    guard let report = vehicle.payload?.vehicleStatusRpt, let vehicleStatus = report.vehicleStatus else { return }
                    self?.set(vehicleStatus: vehicleStatus, syncDateUTC: vehicleStatus.evStatus?.syncDate?.utc)
                }
            }
        }
    }
    
    func vehicleStatus() {
        self.isSyncing = true
        APIRouter.shared.post(endpoint: .status, body: ["vehicleConfigReq": [
            "airTempRange": "0",
            "maintenance": "0",
            "seatHeatCoolOption": "1",
            "vehicle": "1",
            "vehicleFeature": "0"
        ], "vehicleInfoReq": [
            "drivingActivty": "0",
            "dtc": "1",
            "enrollment": "1",
            "functionalCards": "0",
            "location": "1",
            "vehicleStatus": "1",
            "weather": "1"],
            "vinKey": [APIRouter.shared.vinKey]], authorized: true) { [weak self] response, error in
            guard let self = self else { return }
            if defaults?.bool(forKey: "VehicleConfigOnFirstLogin") == false {
                defaults?.set(true, forKey: "VehicleConfigOnFirstLogin")
                if let text = response?.text {
                    log.info(text)
                }
            }
            if let data = response?.data, let vehicle = try? APIRouter.shared.jsonDecoder.decode(StatusResponse.self, from: data) {
                self.updateStatus()
                DispatchQueue.main.async {
                    guard let report = vehicle.payload?.vehicleInfoList?.first?.lastVehicleInfo?.vehicleStatusRpt, let vehicleStatus = report.vehicleStatus else { return }
                    self.set(vehicleStatus: vehicleStatus, syncDateUTC: vehicleStatus.evStatus?.syncDate?.utc)
                    
                    let name = vehicle.payload?.vehicleInfoList?.first?.lastVehicleInfo?.vehicleNickName ?? vehicle.payload?.vehicleInfoList?.first?.vehicleConfig?.vehicleDetail?.vehicle?.trim?.modelName ?? "Niro"
                    self.name = name
                    self.nicknameLabel.text = name

                    if let mileage = vehicle.payload?.vehicleInfoList?.first?.vehicleConfig?.vehicleDetail?.vehicle?.mileage {
                        self.odometerLabel.text = "\(mileage) miles"
                    }
                    if let location = vehicle.payload?.vehicleInfoList?.first?.lastVehicleInfo?.location, let lat = location.coord?.lat, let long = location.coord?.lon {
                        self.latitude = lat
                        self.longitude = long
                        
                        let center = CLLocationCoordinate2D(latitude: CLLocationDegrees(lat), longitude: CLLocationDegrees(long))
                        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005))
                        let formatter = DateFormatter()
                        formatter.dateFormat = "yyyyMMddHHmmss"
                        formatter.timeZone = TimeZone(abbreviation: "UTC")
                        var atString = ""
                        if let syncDateUTC = location.syncDate?.utc, let syncDate = formatter.date(from: syncDateUTC) {
                            formatter.timeZone = TimeZone.current
                            if Calendar.current.isDateInToday(syncDate) {
                                formatter.dateFormat = "h:mm a"
                            } else {
                                formatter.dateFormat = "MM/dd, h:mm a"
                            }
                            let dateString = formatter.string(from: syncDate)
                            atString = "\nat \(dateString)"
                        }
                        self.getAddress(latitude: lat, longitude: long) { address in
                            let annotation = MKPointAnnotation()
                            annotation.coordinate = center
                            annotation.title = "\(address)\(atString)"
                            self.mapView.addAnnotation(annotation)
                        }
                        self.mapView.setRegion(region, animated: true)
                        
                        self.mapView.isUserInteractionEnabled = true
                        let gesture:UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.openMap))
                        gesture.numberOfTapsRequired = 1
                        self.mapView.addGestureRecognizer(gesture)
                    }
                }
            }
        }
    }
    
    @objc func openMap() {
        if let latitude = latitude, let longitude = longitude {
            let url = "http://maps.apple.com/maps?ll=\(latitude),\(longitude)&q=\(name)"
            UIApplication.shared.open(URL(string: url)!, options: [:], completionHandler: nil)
        }
    }
    
    func set(vehicleStatus: VehicleStatus, syncDateUTC: String?) {
        if let evStatus = vehicleStatus.evStatus, let dcTargetSoc = evStatus.targetSOC?[0].targetSOClevel, let acTargetSoc = evStatus.targetSOC?[1].targetSOClevel, let charge = evStatus.batteryStatus, let isCharging = evStatus.batteryCharge, let pluggedIn = evStatus.batteryPlugin, let chargeTime = evStatus.remainChargeTime?.first?.timeInterval?.value, let drvDistance = vehicleStatus.evStatus?.drvDistance?.first, let range = drvDistance.rangeByFuel?.totalAvailableRange?.value {
            self.chargeStatusLabel.text = "\(charge)% • \(range)mi"
            self.batteryContainer.progress = CGFloat(charge)/100.0
            let largeConfig = UIImage.SymbolConfiguration(scale: .large)
            self.chargeButton.setImage(UIImage(systemName: !isCharging ? "bolt" : "bolt.slash", withConfiguration: largeConfig), for: .selected)
            self.setChargeDetails(charging: isCharging, pluggedIn: pluggedIn != 0, ratio: acTargetSoc, chargeTime: chargeTime)
            MaxCharge.AC = acTargetSoc
            MaxCharge.DC = dcTargetSoc
        }

        if let climate = vehicleStatus.climate, let climateOn = climate.airCtrl {
            self.setClimateStatus(climateOn)
            self.temp = Int(climate.airTemp?.value ?? "0") ?? 0
        }
        if let locked = vehicleStatus.doorLock {
            self.isLocked = locked
        }

        if let doorStatus = vehicleStatus.doorStatus {
            self.doorLabel.textColor = .red
            if doorStatus.hood == 0, doorStatus.trunk == 0, doorStatus.frontLeft == 0, doorStatus.frontRight == 0, doorStatus.backLeft == 0, doorStatus.backRight == 0 {
                self.doorLabel.text = "Closed"
                self.doorLabel.textColor = .white
            } else if doorStatus.hood != 0 {
                self.doorLabel.text = "Hood Open"
            } else if doorStatus.trunk != 0 {
                self.doorLabel.text = "Trunk Open"
            } else {
                self.doorLabel.text = "Open"
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
        APIRouter.shared.get(endpoint: lock ? .lock : .unlock) { [weak self] response, error in
            guard let self = self else {
                self?.isSyncing = false
                return
            }
            if error != nil {
                self.isSyncing = false
            } else if  let headers = response?.headers, let xid = headers["Xid"] {
                APIRouter.shared.checkActionStatus(xid: xid) { error in
                    if error == nil {
                        self.commandSuccess(endpoint: lock ? .lock : .unlock)
                    }
                    self.isSyncing = false
                    self.isLocked = lock
                }
            } else {
                self.isSyncing = false
            }
        }
    }
    
    func startCharge(completion: @escaping () -> ()) {
        self.isSyncing = true
        APIRouter.shared.post(endpoint: .startCharge, body: ["chargeRatio": 100], authorized: true) { [weak self] response, error in
            if error != nil {
                self?.isSyncing = false
                completion()
            } else if let headers = response?.headers, let xid = headers["Xid"] {
                APIRouter.shared.checkActionStatus(xid: xid) { error in
                    if error == nil {
                        self?.commandSuccess(endpoint: .startCharge)
                    }
                    self?.isSyncing = false
                    completion()
                }
            }
        }
    }
    
    func stopCharge(completion: @escaping () -> ()) {
        self.isSyncing = true
        APIRouter.shared.get(endpoint: .stopCharge) { [weak self] response, error in
            self?.isSyncing = false
            if error != nil {
                self?.isSyncing = false
                completion()
            } else if let headers = response?.headers, let xid = headers["Xid"] {
                APIRouter.shared.checkActionStatus(xid: xid) { error in
                    if error == nil {
                        self?.commandSuccess(endpoint: .stopCharge)
                    }
                    completion()
                }
            }
        }
    }
    
    func startClimate(completion: (() -> ())?) {
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
                    "steeringWheel": self.heatedButton.isSelected ? 1 : 0
                ],
                "ignitionOnDuration": [
                    "unit": 4,
                    "value": defaults?.integer(forKey: "ClimateDuration") ?? 30
                ]
            ]
        ]
        APIRouter.shared.post(endpoint: .startClimate, body: body, authorized: true) { [weak self] response, error in
            guard let self = self else {
                self?.isSyncing = false
                completion?()
                return
            }
            if error != nil {
                self.isSyncing = false
                completion?()
            } else if let headers = response?.headers, let xid = headers["Xid"] {
                APIRouter.shared.checkActionStatus(xid: xid) { error in
                    if error == nil {
                        self.commandSuccess(endpoint: .startClimate)
                    }
                    self.isSyncing = false
                    self.setClimateStatus(true)
                    completion?()
                }
            }
        }
    }
    
    func stopClimate(completion: (() -> ())?) {
        self.isSyncing = true
        APIRouter.shared.get(endpoint: .stopClimate) { [weak self] response, error in
            guard let self = self else {
                self?.isSyncing = false
                completion?()
                return
            }
            if error != nil {
                self.isSyncing = false
                completion?()
            } else if let headers = response?.headers, let xid = headers["Xid"] {
                APIRouter.shared.checkActionStatus(xid: xid) { error in
                    if error == nil {
                        self.commandSuccess(endpoint: .stopClimate)
                    }
                    self.isSyncing = false
                    self.setClimateStatus(false)
                    completion?()
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
            if let message = error?.localizedDescription {
                log.error(message, context: nil)
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
    
    func commandSuccess(endpoint: Endpoint) {
        DispatchQueue.main.async {
            let banner = FloatingNotificationBanner(title: "Success!", subtitle: endpoint.successMessage(), style: .success)
            banner.show()
        }
    }
}

// MARK: Shortcuts
extension ViewController {
    func addButtonFor(_ shortcut: Shortcut) {
        let addShortcutButton = INUIAddVoiceShortcutButton(style: .blackOutline)
        addShortcutButton.delegate = self
        addShortcutButton.shortcut = INShortcut(intent: shortcut.intent)
        
        let label = UILabel()
        label.textColor = .white
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.text = "\(shortcut.rawValue)"
        
        let buttonStack = UIStackView(arrangedSubviews: [label, addShortcutButton])
        buttonStack.spacing = 4
        buttonStack.axis = .horizontal
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([addShortcutButton.widthAnchor.constraint(equalToConstant: (self.view.frame.width-36)/2)])
        buttonStack.isHidden = true
        shortcutStackView.addArrangedSubview(buttonStack)
    }
    
    @IBAction func tappSeeMoreShortcuts(_ sender: UIButton) {
        if showAllShortcuts {
            showMoreArrow.image = UIImage(systemName: "chevron.right")
            UIView.animate(withDuration: 0.2) {
                for i in 2..<self.shortcutStackView.arrangedSubviews.count {
                    self.shortcutStackView.arrangedSubviews[i].isHidden = true
                }
            }
        } else {
            showMoreArrow.image = UIImage(systemName: "chevron.up")
            UIView.animate(withDuration: 0.2) {
                for view in self.shortcutStackView.arrangedSubviews {
                    view.isHidden = false
                }
            }
        }
        showAllShortcuts = !showAllShortcuts
    }
    
    func present(_ addVoiceShortcutViewController: INUIAddVoiceShortcutViewController, for addVoiceShortcutButton: INUIAddVoiceShortcutButton) {
        if let shortcut = addVoiceShortcutButton.shortcut {
            let viewController = INUIAddVoiceShortcutViewController(shortcut: shortcut)
            viewController.modalPresentationStyle = .formSheet
            viewController.delegate = self
            present(viewController, animated: true, completion: nil)
        }
    }
    
    func present(_ editVoiceShortcutViewController: INUIEditVoiceShortcutViewController, for addVoiceShortcutButton: INUIAddVoiceShortcutButton) {
        INVoiceShortcutCenter.shared.getAllVoiceShortcuts { [weak self] (voiceShortcutsFromCenter, error) in
            guard let voiceShortcutsFromCenter = voiceShortcutsFromCenter, let self = self else {
                return
            }
            
            if let shortcut = voiceShortcutsFromCenter.first(where: {
                $0.shortcut.intent?.intentDescription == addVoiceShortcutButton.shortcut?.intent?.intentDescription
            }) {
                DispatchQueue.main.async {
                    let viewController = INUIEditVoiceShortcutViewController(voiceShortcut: shortcut)
                    viewController.modalPresentationStyle = .formSheet
                    viewController.delegate = self
                    self.present(viewController, animated: true, completion: nil)
                }
            }
        }
    }
    
    func editVoiceShortcutViewController(_ controller: INUIEditVoiceShortcutViewController, didUpdate voiceShortcut: INVoiceShortcut?, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    func editVoiceShortcutViewController(_ controller: INUIEditVoiceShortcutViewController, didDeleteVoiceShortcutWithIdentifier deletedVoiceShortcutIdentifier: UUID) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    func editVoiceShortcutViewControllerDidCancel(_ controller: INUIEditVoiceShortcutViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    func addVoiceShortcutViewController(_ controller: INUIAddVoiceShortcutViewController, didFinishWith voiceShortcut: INVoiceShortcut?, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    func addVoiceShortcutViewControllerDidCancel(_ controller: INUIAddVoiceShortcutViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
}
