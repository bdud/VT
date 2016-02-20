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

    private var imageFilePath: String? {
        // Access to managed property needs to be thread-safe.

        var fileName: String?

        sharedContext.performBlockAndWait { () -> Void in
            fileName = self.fileName
        }

        guard fileName != nil else {
            return nil
        }

        return appDelegate.documentsDirectory.URLByAppendingPathComponent(fileName!).path
    }

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

        guard let path = imageFilePath else {
            return false
        }

        return NSFileManager.defaultManager().fileExistsAtPath(path)
    }

    func image(callback: ImageLoadCallback) {
        // Check cachedImage
        if let cachedImage = cachedImage {
            callback(errorMessage: nil, image: cachedImage)
            return
        }

        callbacks.append(callback)

        checkImageReady()
    }

    func checkImageReady() {
        guard let path = imageFilePath  else {
            print("Unable to get full path for image file for photo at url: \(remoteUrl)")
            return
        }

        if NSFileManager.defaultManager().fileExistsAtPath(path) {
            createCachedImage(path)
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

    // MARK: - NSManagedObject

    lazy var sharedContext: NSManagedObjectContext = {
        return CoreDataManager.sharedInstance().context
    }()

    override func prepareForDeletion() {
        super.prepareForDeletion()

        cachedImage = nil

        if let path = imageFilePath {
            let mgr = NSFileManager.defaultManager()
            if mgr.fileExistsAtPath(path) {
                do {
                    try mgr.removeItemAtPath(path)
                }
                catch {
                    let error = error as NSError
                    print("Unable to delete image file when preparing for Photo managed object deletion: \(error) \(error.userInfo)")
                }
            }
        }
    }

}
