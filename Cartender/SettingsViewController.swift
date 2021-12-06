//
//  SettingsViewController.swift
//  Cartender
//
//  Created by Paul Dippold on 11/19/21.
//

import UIKit

class SettingsViewController: UIViewController, UIColorPickerViewControllerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UserDefaults.standard.colorFor(key: "BackgroundColor") ?? .systemBackground
    }
    
    @IBAction func dismiss() {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func chooseBackground() {
        let picker = UIColorPickerViewController()
        picker.title = "Background"
        picker.selectedColor = .background
        picker.delegate = self
        self.present(picker, animated: true, completion: nil)
    }
    
    @IBAction func chooseSecondaryBackground() {
        let picker = UIColorPickerViewController()
        picker.selectedColor = UIColor(named: "BackgroundColor") ?? .background
        picker.delegate = self
        picker.title = "SecondaryBackground"
        self.present(picker, animated: true, completion: nil)
    }

    @IBAction func chooseForeground() {
        let picker = UIColorPickerViewController()
        picker.selectedColor = UIColor(red: 12/255.0, green: 206/255.0, blue: 107/255.0, alpha: 1.0)
        picker.delegate = self
        self.present(picker, animated: true) {
            UserDefaults.standard.set(color: picker.selectedColor, forKey: "ForegroundColor")
        }
    }
    
    @IBAction func chooseSecondaryForeground() {
        let picker = UIColorPickerViewController()
        picker.selectedColor = UIColor(red: 222/255.0, green: 26/255.0, blue: 26/255.0, alpha: 0.80)
        picker.delegate = self
        self.present(picker, animated: true) {
            UserDefaults.standard.set(color: picker.selectedColor, forKey: "SecondaryForegroundColor")
        }
    }
    
    func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
        if viewController.title == "Background" {
            self.view.backgroundColor = viewController.selectedColor
            (self.presentingViewController as? ViewController)?.view.backgroundColor = viewController.selectedColor
            UserDefaults.standard.set(color: viewController.selectedColor, forKey: "BackgroundColor")
        } else if viewController.title == "SecondaryBackground" {
            UserDefaults.standard.set(color: viewController.selectedColor, forKey: "SecondaryBackgroundColor")
            (self.presentingViewController as? ViewController)?.containerView.backgroundColor = viewController.selectedColor
            (self.presentingViewController as? ViewController)?.containerView2.backgroundColor = viewController.selectedColor
            (self.presentingViewController as? ViewController)?.containerView3.backgroundColor = viewController.selectedColor
            (self.presentingViewController as? ViewController)?.containerView4.backgroundColor = viewController.selectedColor
            (self.presentingViewController as? ViewController)?.containerView5.backgroundColor = viewController.selectedColor

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
        print("Error UserDefaults")
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
        print("Error UserDefaults")
      }
    }
    set(colorData, forKey: key)
  }
}

