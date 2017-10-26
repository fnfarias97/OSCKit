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

    let sdk = OSCKit()
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

//        async {
//            print(try await(OSCKit.shared.usingVersion2_1()))
//        }
        self.ssidLabel.text = self.sdk.currentSSID
        async {
            do {
                try await(self.sdk.waitForInitialization())
            } catch(let error) {
                print(error)
            }
            self.sdk.startLivePreview { (image) in
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

