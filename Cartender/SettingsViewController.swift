//
//  SettingsViewController.swift
//  Cartender
//
//  Created by Paul Dippold on 11/19/21.
//

import UIKit
import SwiftHTTP
import NotificationBannerSwift

class SettingsViewController: UIViewController, UIColorPickerViewControllerDelegate {
    @IBOutlet var airDurationStepper: UIStepper!
    @IBOutlet var airDurationLabel: UILabel!
    
    @IBOutlet var chargeACStepper: UIStepper!
    @IBOutlet var chargeACLabel: UILabel!
    @IBOutlet var chargeDCStepper: UIStepper!
    @IBOutlet var chargeDCLabel: UILabel!
    @IBOutlet var chargeButton: UIButton!

    @IBOutlet var accentButton: UIButton!
    
    @IBOutlet var closeButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        //accentButton.tintColor = UserDefaults.standard.colorFor(key: "AccentColor") ?? .systemTeal
        closeButton.tintColor = UserDefaults.standard.colorFor(key: "AccentColor") ?? .systemTeal

        chargeButton.layer.cornerRadius = chargeButton.frame.height/2
        
        chargeACStepper.value = Double(MaxCharge.AC)
        chargeACLabel.text = "\(MaxCharge.AC)%"
        chargeDCStepper.value = Double(MaxCharge.DC)
        chargeDCLabel.text = "\(MaxCharge.DC)%"
        
        let climateDuration = defaults?.integer(forKey: "ClimateDuration") ?? 30
        airDurationStepper.value = Double(climateDuration)
        airDurationLabel.text = "\(climateDuration) mins"
    }
    
    @IBAction func dismiss() {
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK: Charging
    @IBAction func acMaxChanged() {
        let max = Int(chargeACStepper.value)
        let buttonEnabled = (MaxCharge.AC != Int(chargeACStepper.value) || MaxCharge.DC !=  Int(chargeDCStepper.value))
        self.setChargeButton(enabled: buttonEnabled)
        self.chargeACLabel.text = "\(max)%"
    }
    
    @IBAction func dcMaxChanged() {
        let max = Int(chargeDCStepper.value)
        let buttonEnabled = (MaxCharge.AC != Int(chargeACStepper.value) || MaxCharge.DC !=  Int(chargeDCStepper.value))
        self.setChargeButton(enabled: buttonEnabled)
        self.chargeDCLabel.text = "\(max)%"
    }
    
    @IBAction func saveCharge() {
        self.setChargeLimit {
            MaxCharge.AC = Int(self.chargeACStepper.value)
            MaxCharge.DC = Int(self.chargeDCStepper.value)
            let buttonEnabled = (MaxCharge.AC != Int(self.chargeACStepper.value) || MaxCharge.AC !=  Int(self.chargeDCStepper.value))
            self.setChargeButton(enabled: buttonEnabled)
        }
    }
    
    func setChargeButton(enabled: Bool) {
        self.chargeButton.alpha = enabled ? 1.0 : 0.5
        self.chargeButton.isEnabled = enabled
    }
    
    func setChargeLimit(completion: @escaping () -> ()) {
        self.setChargeButton(enabled: false)
        APIRouter.shared.post(endpoint: .setChargeLimit, body: [
            "targetSOClist": [
                [
                    "plugType": 0,
                    "targetSOClevel": MaxCharge.DC,
                ],
                [
                    "plugType": 1,
                    "targetSOClevel": MaxCharge.AC,
                ],
            ]
        ], authorized: true) { response, error in
            if error != nil {
                self.setChargeButton(enabled: true)
                completion()
            } else if let headers = response?.headers, let xid = headers["Xid"] {
                APIRouter.shared.checkActionStatus(xid: xid) { error in
                    if error == nil {
                        self.commandSuccess(endpoint: .setChargeLimit)
                    }
                    completion()
                }
            } else {
                self.setChargeButton(enabled: true)
                completion()
            }
        }
    }
    
    // MARK: Climate Control
    @IBAction func airDurationChanged() {
        self.airDurationLabel.text = "\(Int(airDurationStepper.value)) mins"
        defaults?.set(airDurationStepper.value, forKey: "ClimateDuration")
    }
    
    // MARK: Accent Color
    @IBAction func chooseAccent() {
        let picker = UIColorPickerViewController()
        picker.title = "Accent Color"
        picker.selectedColor = .systemBackground
        picker.delegate = self
        self.present(picker, animated: true, completion: nil)
    }
    
    func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
        if viewController.title == "Accent Color" {
            self.view.backgroundColor = viewController.selectedColor
            (self.presentingViewController as? ViewController)?.view.backgroundColor = viewController.selectedColor
            UserDefaults.standard.set(color: viewController.selectedColor, forKey: "AccentColor")
        }
     }
    
    func commandSuccess(endpoint: Endpoint) {
        DispatchQueue.main.async {
            let banner = FloatingNotificationBanner(title: "Success!", subtitle: endpoint.successMessage(), style: .success)
            banner.show()
        }
    }
}

extension UserDefaults {
  func colorFor(key: String) -> UIColor? {
    var colorReturnded: UIColor?
    if let colorData = data(forKey: key) {
      do {
        if let color = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(colorData) as? UIColor {
          colorReturnded = color
        }
      } catch {
          log.error("Failed to unarchive color")
      }
    }
    return colorReturnded
  }
  
  func set(color: UIColor?, forKey key: String) {
    var colorData: NSData?
    if let color = color {
      do {
        let data = try NSKeyedArchiver.archivedData(withRootObject: color, requiringSecureCoding: false) as NSData?
        colorData = data
      } catch {
          log.error("Failed to archive color")
      }
    }
    set(colorData, forKey: key)
  }
}

