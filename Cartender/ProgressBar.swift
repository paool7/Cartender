//
//  ProgressBar.swift
//  Cartender
//
//  Created by Paul Dippold on 11/18/21.
//

import Foundation
import UIKit

@IBDesignable
class ProgressBar: UIView {
    @IBInspectable var color: UIColor = .gray {
        didSet { setNeedsDisplay() }
    }

    var progress: CGFloat = 0 {
        didSet { setNeedsDisplay() }
    }

    private let progressView = UIView()
    private let backgroundMask = CAShapeLayer()
    
    let highColor = UIColor(red: 12/255.0, green: 206/255.0, blue: 107/255.0, alpha: 1.0)
    let lowColor = UIColor(red: 222/255.0, green: 26/255.0, blue: 26/255.0, alpha: 1.0)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayers()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayers()
    }

    private func setupLayers() {
        self.backgroundColor = .gray
        self.insertSubview(progressView, at: 0)
    }

    override func draw(_ rect: CGRect) {
        backgroundMask.path = UIBezierPath(roundedRect: rect, cornerRadius: rect.height * 0.25).cgPath
        layer.mask = backgroundMask

        let progressRect = CGRect(origin: .zero, size: CGSize(width: rect.width * progress, height: rect.height))

        progressView.frame = progressRect
        let color = progress < 0.30 ? lowColor : highColor
        progressView.backgroundColor = color
    }
}
