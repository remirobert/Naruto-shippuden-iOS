//
//  RRProgressDownload.swift
//  naruto-download
//
//  Created by Remi Robert on 02/12/14.
//  Copyright (c) 2014 remirobert. All rights reserved.
//

import UIKit

class RRProgressDownload: UIView {
    private var startAngle: Double = M_PI * 1.5;
    private var endAngle: Double = (M_PI * 1.5) + (M_PI * 2);
    private var percentLabel = UILabel()
    var percent: Float!  = 0 {
        didSet {
            if self.percent >= 100 {
                self.displayPlayButton()
            }
        }
    }
    var playButton = UIButton()

    private func displayPlayButton() {
        UIView.animateWithDuration(0.5, animations: { () -> Void in
            self.playButton.frame = CGRectMake(self.frame.size.width / 2 - self.frame.size.width / 4,
                self.frame.size.width / 2 - self.frame.size.width / 4,
                self.frame.size.width / 2, self.frame.size.width / 2)
        })
    }
    
    private func initAngleProgress() {
        self.backgroundColor = UIColor.clearColor()
        self.startAngle = M_PI * 1.5;
        self.endAngle = self.startAngle + (M_PI * 2);
        self.playButton.frame = CGRectMake(self.frame.size.width / 2, self.frame.size.width / 2,
            0, 0)
        self.playButton.backgroundColor = UIColor.greenColor()
        
        self.percentLabel.frame = CGRectMake(5, self.frame.size.height / 2 - 10, self.frame.size.width - 10, 20)
        self.percentLabel.textAlignment = NSTextAlignment.Center
        self.percentLabel.textColor = UIColor.grayColor()
        self.percentLabel.font = UIFont(name: self.percentLabel.font.fontName, size: 14)
        self.addSubview(self.percentLabel)
        self.addSubview(self.playButton)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.initAngleProgress()
    }
    
    override init() {
        super.init()
        self.initAngleProgress()
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func drawRect(rect: CGRect) {
        self.percentLabel.text = "\(Int(self.percent))"
        var bezierPath: UIBezierPath = UIBezierPath().bezierPathByReversingPath()
        bezierPath.addArcWithCenter(CGPointMake(rect.size.width / 2, rect.size.height / 2), radius: rect.size.width / 2 - 7,
            startAngle: CGFloat(self.startAngle),
            endAngle: CGFloat((self.endAngle - startAngle) * (Double(self.percent) / 100.0) +
                self.startAngle), clockwise: true)
        bezierPath.lineWidth = 5
        UIColor.grayColor().setStroke()
        bezierPath.stroke()
        
    }
}
