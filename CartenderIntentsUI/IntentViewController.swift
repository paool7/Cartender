//
//  IntentViewController.swift
//  CartenderIntentsUI
//
//  Created by Paul Dippold on 4/6/22.
//

import IntentsUI
import MapKit

class IntentViewController: UIViewController, INUIHostedViewControlling {
    @IBOutlet var batteryContainer: ProgressBar!
    @IBOutlet var primaryLabel: UILabel!
    @IBOutlet var secondaryLabel: UILabel!
    @IBOutlet var mapView: MKMapView!

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    func configureView(for parameters: Set<INParameter>, of interaction: INInteraction, interactiveBehavior: INUIInteractiveBehavior, context: INUIHostedViewContext, completion: @escaping (Bool, Set<INParameter>, CGSize) -> Void) {
        if let _ = interaction.intent as? CurrentChargeIntent {
            self.setChargeDetails()
            completion(true, parameters, CGSize(width: self.maxSize.width, height: 134))
        } else if let _ = interaction.intent as? CurrentLocationIntent {
            self.setLocationDetails()
            completion(true, parameters, CGSize(width: self.maxSize.width, height: 234))
        } else if let _ = interaction.intent as? CurrentTemperatureIntent {
            let isClimateOn = self.setClimateDetails()
            completion(true, parameters, CGSize(width: self.maxSize.width, height: isClimateOn ? 134 : 50))
        }
    }
    
    func setClimateDetails() -> Bool {
        mapView.isHidden = true
        primaryLabel.isHidden = false
        batteryContainer.isHidden = true
        secondaryLabel.isHidden = false

        guard let isClimateOn = defaults?.bool(forKey: "IntentClimateOn"), let temp = defaults?.integer(forKey: "IntentTemperature") else {
            return false
        }
        if !isClimateOn {
            self.primaryLabel.text = "Climate Control Off"
            self.secondaryLabel.isHidden = true
        } else {
            self.primaryLabel.text = "\(temp)°"
            var enabledString = ""
            if let defrost = defaults?.bool(forKey: "IntentDefrost") {
                enabledString.append(contentsOf: defrost ? "Defrost On" : "Defrost Off")
            }
            if let windowHeat = defaults?.bool(forKey: "IntentWIndowHeat") {
                enabledString.append(contentsOf: " • ")
                enabledString.append(contentsOf: windowHeat ? "Rear Defrost On" : "Rear Defrost Off")
            }
            if let wheelHeat = defaults?.bool(forKey: "IntentWheelHeat") {
                enabledString.append(contentsOf: "\n")
                enabledString.append(contentsOf: wheelHeat ? "Heated Wheel On" : "Heated Wheel Off")
            }
            self.secondaryLabel.text = enabledString
        }
        return isClimateOn
    }
    
    func setLocationDetails() {
        mapView.isHidden = false
        primaryLabel.isHidden = true
        batteryContainer.isHidden = true
        secondaryLabel.isHidden = true

        DispatchQueue.main.async {
            if let lat = defaults?.double(forKey: "IntentLatitude"), let long = defaults?.double(forKey: "IntentLongitude") {
                let center = CLLocationCoordinate2D(latitude: CLLocationDegrees(lat), longitude: CLLocationDegrees(long))
                let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005))
                let annotation = MKPointAnnotation()
                annotation.coordinate = center
                self.mapView.addAnnotation(annotation)
                self.mapView.setRegion(region, animated: true)
            }
        }
    }
    
    func setChargeDetails() {
        mapView.isHidden = true
        primaryLabel.isHidden = false
        batteryContainer.isHidden = false
        secondaryLabel.isHidden = false

        guard let charge = defaults?.double(forKey: "IntentChargeState"), let charging = defaults?.bool(forKey: "IntentIsCharging"), let chargeTime = defaults?.integer(forKey: "IntentChargeTime"), let pluggedIn = defaults?.bool(forKey: "IntentIsPluggedIn"), let ACRatio = defaults?.double(forKey: "IntentTargetSOCAC"), let DCRatio = defaults?.double(forKey: "IntentTargetSOCDC"), let range = defaults?.integer(forKey: "IntentDriveRange") else {
            return
        }
        secondaryLabel.text = "\(charge)% • \(range)mi"
        batteryContainer.progress = CGFloat(charge)/100.0
        batteryContainer.target = CGFloat(ACRatio)/100.0
        var chargeString = ""
        if pluggedIn {
            if charging {
                if chargeTime == 0 {
                    chargeString.append("Finished Charging")
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
        } else {
            chargeString = "Unplugged • AC: \(ACRatio)% • DC: \(DCRatio)%"
        }
        secondaryLabel.text = chargeString
    }
    
    var maxSize: CGSize {
        return self.extensionContext!.hostedViewMaximumAllowedSize
    }
}
