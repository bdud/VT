//
//  Alert.swift
//
//  Created by Bill Dawson on 12/24/15.
//  Copyright © 2015 Bill Dawson. All rights reserved.
//

import UIKit

class Alert: NSObject {

    func ok(title: String?, message: String, owner: UIViewController, completion: (() -> Void)?) {
        dispatch_async(dispatch_get_main_queue()) {
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
            let okButton = UIAlertAction(title: "OK", style: .Default, handler: nil)
            alertController.addAction(okButton)
            owner.presentViewController(alertController, animated: true, completion: completion)
        }
    }

    // MARK: Singleton

    class func sharedInstance() -> Alert {
        struct Singleton {
            static var instance = Alert()
        }
        return Singleton.instance
    }
}
