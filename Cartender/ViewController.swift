//
//  ViewController.swift
//  Cartender
//
//  Created by Paul Dippold on 11/15/21.
//

import UIKit
import MapKit
import Intents
import Contacts
import IntentsUI
import SwiftHTTP
import SwiftKeychainWrapper
import NotificationBannerSwift

class ViewController: UIViewController, INUIAddVoiceShortcutButtonDelegate, INUIAddVoiceShortcutViewControllerDelegate, INUIEditVoiceShortcutViewControllerDelegate {
    
    // MARK: Outlets
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet var batteryContainer: ProgressBar!
    
    @IBOutlet var chargeStatusLabel: UILabel!
    @IBOutlet var chargeTimeLabel: UILabel!
    @IBOutlet var nicknameLabel: UILabel!
    @IBOutlet var odometerLabel: UILabel!
    @IBOutlet var syncTimeLabel: UILabel!
    @IBOutlet var rangeLabel: UILabel!
    @IBOutlet var lockLabel: UILabel!
    @IBOutlet var doorLabel: UILabel!
    
    @IBOutlet var lockUnlockButton: UIButton!
    @IBOutlet var tempDownButton: UIButton!
    @IBOutlet var settingsButton: UIButton!
    @IBOutlet var climateButton: UIButton!
    @IBOutlet var defrostButton: UIButton!
    @IBOutlet var chargeButton: UIButton!
    @IBOutlet var tempUpButton: UIButton!
    @IBOutlet var heatedButton: UIButton!
    @IBOutlet var syncButton: UIButton!
    @IBOutlet var tempLabel: UIButton!
    
    @IBOutlet var backgroundImageView: UIImageView!
    @IBOutlet var shortcutStackView: UIStackView!
    @IBOutlet var showMoreArrow: UIImageView!
    
    @IBOutlet var mapView: MKMapView!
    
    @IBOutlet var mainStackView: UIStackView!
    
    // MARK: Variables
    var name = "Niro"
    var latitude: Double?
    var longitude: Double?
    var showAllShortcuts = false
    
    var climateOn = false {
        didSet {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.climateButton.setTitle(self.climateOn ? "Stop" : "Start", for: .normal)
            }
        }
    }
    
    var isSyncing = false {
        didSet {
            DispatchQueue.main.async {
                self.activityIndicator.isHidden = !self.isSyncing
                self.syncTimeLabel.isHidden = self.isSyncing
                self.syncButton.isHidden = self.isSyncing
                self.shortcutStackView.alpha = self.isSyncing ? 0.5 : 1.0
                self.shortcutStackView.isUserInteractionEnabled = !self.isSyncing
                
                self.tempUpButton.alpha = self.isSyncing ? 0.5 : 1.0
                self.tempDownButton.alpha = self.isSyncing ? 0.5 : 1.0
                self.heatedButton.alpha = self.isSyncing ? 0.5 : 1.0
                self.defrostButton.alpha = self.isSyncing ? 0.5 : 1.0
                self.settingsButton.alpha = self.isSyncing ? 0.5 : 1.0
                self.lockUnlockButton.alpha = self.isSyncing ? 0.5 : 1.0
                self.climateButton.alpha = self.isSyncing ? 0.5 : 1.0
                
                self.heatedButton.isEnabled = !self.isSyncing
                self.defrostButton.isEnabled = !self.isSyncing
                self.tempUpButton.isEnabled = !self.isSyncing
                self.tempDownButton.isEnabled = !self.isSyncing
                self.settingsButton.isEnabled = !self.isSyncing
                self.lockUnlockButton.isEnabled = !self.isSyncing
                self.climateButton.isEnabled = !self.isSyncing
                
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
    
    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { [weak self] notification in
            guard let self = self else { return }
            if APIRouter.shared.sessionId == nil {
                self.login(completion: nil)
            } else {
                self.getVehicles(completion: nil)
            }
        }
        
        APIRouter.shared.logoutHandler = {
            self.login(completion: nil)
        }
        
        for i in 0..<Shortcut.allCases.count {
            self.addButtonFor(Shortcut.allCases[i])
            if i < 2 {
                self.shortcutStackView.arrangedSubviews[i].isHidden = false
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        syncButton.tintColor = .systemCyan
        heatedButton.layer.cornerRadius = heatedButton.frame.width/2
        tempUpButton.layer.cornerRadius = tempUpButton.frame.width/2
        tempDownButton.layer.cornerRadius = tempDownButton.frame.width/2
        chargeButton.layer.cornerRadius = chargeButton.frame.height/2
        defrostButton.layer.cornerRadius = defrostButton.frame.width/2
        climateButton.layer.cornerRadius = climateButton.frame.height/2
        lockUnlockButton.layer.cornerRadius = lockUnlockButton.frame.height/2
        backgroundImageView.image = UIImage(named: "Drive-\(Calendar.current.component(.weekday, from: Date()))")
        
        self.mapView.isUserInteractionEnabled = true
        let gesture:UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.openMap))
        gesture.numberOfTapsRequired = 1
        self.mapView.addGestureRecognizer(gesture)
    }
    
    // MARK: Actions
    @IBAction func sync() {
        self.updateStatus()
    }
    
    @IBAction func tappedCharge(_ sender: UIButton) {
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
    
    @IBAction func tappedClimate(_ sender: UIButton) {
        if !climateOn {
            self.startClimate(completion: nil)
        } else {
            if !sender.isSelected {
                self.stopClimate(completion: nil)
            }
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
    
    @IBAction func tappedHeatedWheel(_ sender: UIButton) {
        sender.isSelected.toggle()
        if !sender.isSelected {
            self.heatedButton.tintColor = .white
        } else {
            self.heatedButton.tintColor = .systemRed
        }
    }
    
    @IBAction func tappedLockUnlock(_ sender: UIButton) {
        self.lockLabel.text = isLocked ? "Unlocking..." : "Locking..."
        self.setLock(lock: !isLocked)
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
    
    // MARK: API Helpers
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
        }
        chargeTimeLabel.text = chargeString
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
    
    func set(vehicleStatus: VehicleStatus?) {
        if let evStatus = vehicleStatus?.evStatus, let dcTargetSoc = evStatus.targetSOC?[0].targetSOClevel, let acTargetSoc = evStatus.targetSOC?[1].targetSOClevel, let charge = evStatus.batteryStatus, let isCharging = evStatus.batteryCharge, let pluggedIn = evStatus.batteryPlugin, let chargeTime = evStatus.remainChargeTime?.first?.timeInterval?.value, let drvDistance = evStatus.drvDistance?.first, let range = drvDistance.rangeByFuel?.totalAvailableRange?.value {
            self.chargeStatusLabel.text = "\(charge)% • \(range)mi"
            self.batteryContainer.progress = CGFloat(charge)/100.0
            let largeConfig = UIImage.SymbolConfiguration(scale: .large)
            self.chargeButton.setImage(UIImage(systemName: !isCharging ? "bolt" : "bolt.slash", withConfiguration: largeConfig), for: .selected)
            self.setChargeDetails(charging: isCharging, pluggedIn: pluggedIn != 0, ratio: acTargetSoc, chargeTime: chargeTime)
            MaxCharge.AC = acTargetSoc
            MaxCharge.DC = dcTargetSoc
        }
        
        if let climate = vehicleStatus?.climate, let climateOn = climate.airCtrl {
            self.climateOn = climateOn
            self.temp = Int(climate.airTemp?.value ?? "0") ?? 0
        }
        if let locked = vehicleStatus?.doorLock {
            self.isLocked = locked
        }
        
        if let doorStatus = vehicleStatus?.doorStatus {
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
        if let syncDateUTC = vehicleStatus?.evStatus?.syncDate?.utc, let syncDate = formatter.date(from: syncDateUTC) {
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
    
    @objc func openMap() {
        if let latitude = latitude, let longitude = longitude {
            if let urlCheck = URL(string:"comgooglemaps://"), (UIApplication.shared.canOpenURL(urlCheck)) {
                let urlString = "comgooglemaps://?q=\(latitude),\(longitude)"
                if let url = URL(string: urlString) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                } else {
                    log.error(urlString)
                }
            } else {
                let urlString = "maps://?ll=\(latitude),\(longitude)&q=\(name)"
                let altUrlString = "maps://?saddr=&daddr=\(latitude),\(longitude)"
                if let url = URL(string: urlString), UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                } else if let altUrl = URL(string: altUrlString), UIApplication.shared.canOpenURL(altUrl) {
                    UIApplication.shared.open(altUrl, options: [:], completionHandler: nil)
                } else {
                    log.error(urlString)
                }
            }
        }
    }
    
    // MARK: API Requests
    func login(completion: (() -> ())?) {
        DispatchQueue.main.async {
            var vc: UIViewController = self
            if let topVC = UIApplication.shared.keyWindowPresentedController {
                vc = topVC
            }
            
            if let username = keychain.string(forKey: .usernameKey), let password = keychain.string(forKey: .passwordKey) {
                APIRouter.shared.login(username: username, password: password) { [weak self] error in
                    if let error = error {
                        let errorAlert = UIAlertController(title: "Error", message: error, preferredStyle: .alert)
                        let errorAction = UIAlertAction(title: "Ok", style: .cancel) { _ in
                            self?.login(completion: completion)
                        }
                        errorAlert.addAction(errorAction)
                        
                        DispatchQueue.main.async {
                            vc.present(errorAlert, animated: true, completion: nil)
                        }
                    } else {
                        self?.getVehicles(completion: completion)
                    }
                }
            } else {
                DispatchQueue.main.async {
                    var usernameField = UITextField()
                    var passwordField = UITextField()
                    
                    let alert = UIAlertController(title: "Login", message: "Your login information is stored securely on your device and is only sent to Kia to login.", preferredStyle: .alert)
                    alert.addTextField { alertTextField in
                        alertTextField.placeholder = "Email or phone number"
                        usernameField = alertTextField
                    }
                    alert.addTextField { alertTextField in
                        alertTextField.placeholder = "Password"
                        alertTextField.isSecureTextEntry = true
                        passwordField = alertTextField
                    }
                    
                    let action = UIAlertAction(title: "Done", style: .default) { action in
                        if let username = usernameField.text, let password = passwordField.text, !username.isEmpty, !password.isEmpty {
                            APIRouter.shared.login(username: username, password: password) { [weak self] error in
                                if let error = error {
                                    let errorAlert = UIAlertController(title: "Error", message: error, preferredStyle: .alert)
                                    let errorAction = UIAlertAction(title: "Ok", style: .cancel) { _ in
                                        self?.login(completion: completion)
                                    }
                                    errorAlert.addAction(errorAction)
                                    
                                    DispatchQueue.main.async {
                                        vc.present(errorAlert, animated: true, completion: nil)
                                    }
                                } else {
                                    self?.getVehicles(completion: completion)
                                }
                            }
                        } else {
                            var message = "Check your login details and try again."
                            if usernameField.text?.isEmpty == true && passwordField.text?.isEmpty == true {
                                message = "Please enter your email or phone number and password."
                            } else if usernameField.text?.isEmpty == true {
                                message = "Please enter your email or phone number."
                            } else if passwordField.text?.isEmpty == true {
                                message = "Please enter your password."
                            }
                            let errorAlert = UIAlertController(title: message, message: "", preferredStyle: .alert)
                            let errorAction = UIAlertAction(title: "Ok", style: .cancel) { _ in
                                self.login(completion: completion)
                            }
                            errorAlert.addAction(errorAction)
                            
                            DispatchQueue.main.async {
                                vc.present(errorAlert, animated: true, completion: nil)
                            }
                        }
                    }
                    
                    alert.addAction(action)
                    DispatchQueue.main.async {
                        vc.present(alert, animated: true, completion: nil)
                    }
                }
            }
        }
    }
    
    func getVehicles(completion: (() -> ())?) {
        self.isSyncing = true
        APIRouter.shared.get(endpoint: .vehicles, checkAction: false) { [weak self] data, error in
            if let vehicles = try? APIRouter.shared.jsonDecoder.decode(VehiclesResponse.self, from: data), let vinKey = vehicles.payload?.vehicleSummary?.first?.vehicleKey {
                APIRouter.shared.vinKey = vinKey
                self?.vehicleStatus()
            }
            completion?()
        }
    }
    
    func updateStatus() {
        self.isSyncing = true
        APIRouter.shared.post(endpoint: .updateStatus, body: ["requestType":0], authorized: true, checkAction: false) { [weak self] data, error in
            if let vehicle = try? APIRouter.shared.jsonDecoder.decode(UpdateStatusResponse.self, from: data) {
                DispatchQueue.main.async {
                    self?.isSyncing = false
                    guard let vehicleStatus = vehicle.payload?.vehicleStatusRpt?.vehicleStatus else { return }
                    self?.set(vehicleStatus: vehicleStatus)
                }
            }
        }
    }
    
    func vehicleStatus() {
        self.isSyncing = true
        let body: [String: Any] = ["vehicleConfigReq": [
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
                    "vinKey": [APIRouter.shared.vinKey]]
        APIRouter.shared.post(endpoint: .status, body: body, authorized: true, checkAction: false) { [weak self] data, error in
            self?.updateStatus()
            guard let self = self else { return }
            let vehicle = try? APIRouter.shared.jsonDecoder.decode(StatusResponse.self, from: data)
            DispatchQueue.main.async {
                let vehicleStatus = vehicle?.payload?.vehicleInfoList?.first?.lastVehicleInfo?.vehicleStatusRpt?.vehicleStatus
                
                self.set(vehicleStatus: vehicleStatus)
                
                let name = vehicle?.payload?.vehicleInfoList?.first?.lastVehicleInfo?.vehicleNickName ?? vehicle?.payload?.vehicleInfoList?.first?.vehicleConfig?.vehicleDetail?.vehicle?.trim?.modelName ?? "Niro"
                self.name = name
                self.nicknameLabel.text = name
                
                if let mileage = vehicle?.payload?.vehicleInfoList?.first?.vehicleConfig?.vehicleDetail?.vehicle?.mileage {
                    self.odometerLabel.text = "\(mileage) miles"
                }
                if let location = vehicle?.payload?.vehicleInfoList?.first?.lastVehicleInfo?.location, let lat = location.coord?.lat, let long = location.coord?.lon {
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
                }
            }
            
        }
    }
    
    // MARK: API Actions
    func setLock(lock: Bool) {
        self.isSyncing = true
        APIRouter.shared.get(endpoint: lock ? .lock : .unlock, checkAction: true) { [weak self] data, error in
            self?.isSyncing = false
            guard let self = self, error == nil else {
                self?.isLocked = !lock
                return
            }
            self.commandSuccess(endpoint: lock ? .lock : .unlock)
            self.isLocked = lock
        }
    }
    
    func startCharge(completion: @escaping () -> ()) {
        self.isSyncing = true
        APIRouter.shared.post(endpoint: .startCharge, body: ["chargeRatio": 100], authorized: true, checkAction: true) { [weak self] response, error in
            self?.isSyncing = false
            if error != nil {
                completion()
            } else {
                self?.commandSuccess(endpoint: .startCharge)
                completion()
            }
        }
    }
    
    func stopCharge(completion: @escaping () -> ()) {
        self.isSyncing = true
        APIRouter.shared.get(endpoint: .stopCharge, checkAction: true) { [weak self] response, error in
            self?.isSyncing = false
            if error != nil {
                completion()
            } else {
                self?.commandSuccess(endpoint: .stopCharge)
                completion()
            }
        }
    }
    
    func startClimate(completion: (() -> ())?) {
        self.isSyncing = true
        var climateDuration = defaults?.integer(forKey: "ClimateDuration") ?? 30
        climateDuration = climateDuration == 0 ? 30 : climateDuration
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
                    "value": climateDuration
                ]
            ]
        ]
        APIRouter.shared.post(endpoint: .startClimate, body: body, authorized: true, checkAction: true) { [weak self] response, error in
            self?.isSyncing = false
            guard let self = self, error == nil else {
                completion?()
                return
            }
            self.commandSuccess(endpoint: .startClimate)
            self.climateOn = true
            completion?()
        }
    }
    
    func stopClimate(completion: (() -> ())?) {
        self.isSyncing = true
        APIRouter.shared.get(endpoint: .stopClimate, checkAction: true) { [weak self] response, error in
            self?.isSyncing = false
            guard let self = self, error != nil else {
                completion?()
                return
            }
            self.commandSuccess(endpoint: .stopClimate)
            self.climateOn = false
            completion?()
        }
    }
    
    func commandSuccess(endpoint: Endpoint) {
        DispatchQueue.main.async {
            let banner = FloatingNotificationBanner(title: "Success!", subtitle: endpoint.successMessage(), style: .success)
            banner.show(cornerRadius: 8)
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

extension UIApplication {
    var keyWindowPresentedController: UIViewController? {
        var viewController = self.keyWindow?.rootViewController
        
        // If root `UIViewController` is a `UITabBarController`
        if let presentedController = viewController as? UITabBarController {
            // Move to selected `UIViewController`
            viewController = presentedController.selectedViewController
        }
        
        // Go deeper to find the last presented `UIViewController`
        while let presentedController = viewController?.presentedViewController {
            // If root `UIViewController` is a `UITabBarController`
            if let presentedController = presentedController as? UITabBarController {
                // Move to selected `UIViewController`
                viewController = presentedController.selectedViewController
            } else {
                // Otherwise, go deeper
                viewController = presentedController
            }
        }
        
        return viewController
    }
    
}
