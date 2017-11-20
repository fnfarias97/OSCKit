//
//  ViewController.swift
//  OSCKitExample
//
//  Created by Zhigang Fang on 5/11/17.
//  Copyright © 2017 matrix. All rights reserved.
//

import UIKit
import OSCKit
import AwaitKit

class ViewController: UIViewController {
    @IBOutlet weak var ssidLabel: UILabel!
    @IBOutlet weak var image: UIImageView!

    let sdk = OSCKit()
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        async { () -> Void in
            try await(self.sdk.waitForInitialization())
            let initialized = Date()
            let url = try await(self.sdk.takePicture(format: .largeImage))
            try await(self.sdk.getImage(url: url, progress: {
                print($0)
            }))
            print(Date().timeIntervalSince(initialized))
        }

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

