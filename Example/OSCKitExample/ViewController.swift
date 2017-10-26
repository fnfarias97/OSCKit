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

        self.ssidLabel.text = self.sdk.currentSSID
//        async {
//            do {
//                try await(self.sdk.waitForInitialization())
//            } catch(let error) {
//                print(error)
//            }
//            self.sdk.startLivePreview { (image) in
//                DispatchQueue.main.async {
//                    self.image.image = image
//                }
//            }
//        }
        self.sdk.takePicture().then(execute: {
            self.sdk.getImage(url: $0)
        }).then(on: .main) { (image: UIImage) -> Void in
            self.image.image = image
         }

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

