//
//  Photo.swift
//  VirtualTourist
//
//  Created by Bill Dawson on 1/19/16.
//  Copyright © 2016 Bill Dawson. All rights reserved.
//

import CoreData
import UIKit

typealias ImageLoadCallback = (errorMessage: String?, image: UIImage?) -> Void

class Photo: NSManagedObject {

    // MARK: - Unmanaged Properties

    private var cachedImage: UIImage?
    private var callbacks: [ImageLoadCallback] = [ImageLoadCallback]()
    private let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate

    // MARK: - Initializers

    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }

    init(pin: Pin, url: String, fileName: String, insertIntoManagedObjectContext context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        self.remoteUrl = url
        self.pin = pin
        self.fileName = fileName
    }

    // MARK: - Image management

    func isImageAvailableLocally() -> Bool {
        if let _ = cachedImage {
            return true
        }

        guard let fileName = fileName else {
            return false
        }

        return NSFileManager.defaultManager().fileExistsAtPath(appDelegate.documentsDirectory.URLByAppendingPathComponent(fileName).path!)
    }

    func image(callback: ImageLoadCallback) {
        // Check cachedImage
        if let cachedImage = cachedImage {
            callback(errorMessage: nil, image: cachedImage)
            return
        }

        callbacks.append(callback)

        // * Check file system
        guard let fileName = fileName else {
            print("No local file name stored for photo at url: \(remoteUrl)")
            return
        }

        let localUrl = appDelegate.documentsDirectory.URLByAppendingPathComponent(fileName)

        if NSFileManager.defaultManager().fileExistsAtPath(localUrl.path!) {
            createCachedImage(localUrl.path!)
        }
    }

    func createCachedImage(path: String) {
        cachedImage = UIImage(contentsOfFile: path)
        if let image = cachedImage {
            for callback in callbacks {
                callback(errorMessage: nil, image: image)
            }
        }
        else {
            print("Image didn't get created!")
        }
    }

    func clearCachedImage() {
        cachedImage = nil
    }

}
