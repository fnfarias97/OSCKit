//
//  ViewController.swift
//  OSCKitExample
//
//  Created by Zhigang Fang on 5/11/17.
//  Copyright © 2017 matrix. All rights reserved.
//

import UIKit
import OSC

class ViewController: UIViewController {
    @IBOutlet weak var ssidLabel: UILabel!
    @IBOutlet weak var image: UIImageView!

    var ssidObservationCancellation: (() -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.


        ssidObservationCancellation = OSCKit.shared.ssid {[weak self] (ssid) in
            guard let `self` = self else { return }

            self.ssidLabel.text = ssid
            print(ssid)
            if ssid?.hasPrefix("THETA") == true {
                OSCKit.shared.waitForSession().then(execute: { () -> Void in
                    print("Connected")
                    OSCKit.shared.startLivePreview { (image) in
                        self.image.image = image
                    }
                })
            }
        }

    }

    deinit {
        self.ssidObservationCancellation?()
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

