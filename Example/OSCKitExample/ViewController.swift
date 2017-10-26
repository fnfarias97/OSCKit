//
//  ViewController.swift
//  OSCKitExample
//
//  Created by Zhigang Fang on 5/11/17.
//  Copyright © 2017 matrix. All rights reserved.
//

import UIKit
import OSC
import AwaitKit

class ViewController: UIViewController {
    @IBOutlet weak var ssidLabel: UILabel!
    @IBOutlet weak var image: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        self.ssidLabel.text = OSCKit.shared.currentSSID
        async {
            try await(OSCKit.shared.waitForSession())
            try await(OSCKit.shared.usingVersion2_1())
            OSCKit.shared.startLivePreview { (image) in
                DispatchQueue.main.async {
                    self.image.image = image
                }
            }
        }

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

