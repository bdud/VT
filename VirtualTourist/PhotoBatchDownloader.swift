//
//  PhotoBatchDownloader.swift
//  VirtualTourist
//
//  Created by Bill Dawson on 1/26/16.
//  Copyright © 2016 Bill Dawson. All rights reserved.
//

import UIKit
import CoreData

typealias PhotoBatchDownloaderCallback = (success: Bool, photos: NSOrderedSet) -> Void

@objc protocol PhotoBatchDownloaderDelegate {
    optional func downloaderDidEncounterError(_: String, whileDownloadingPhoto photo: Photo)
    optional func downloaderDidDownloadPhoto(_: Photo)
}

class PhotoBatchDownloader {

    private let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    var photos: NSOrderedSet
    var callback: PhotoBatchDownloaderCallback!
    var errors: [String] = [String]()
    var remaining: Int

    weak var delegate: PhotoBatchDownloaderDelegate?

    init(photos: NSOrderedSet, callback: PhotoBatchDownloaderCallback) {
        self.photos = photos
        self.callback = callback
        remaining = photos.count
    }

    func begin() {
        print("Fetching photos from flickr")
        photos.forEach { (element: AnyObject) -> () in
            let photo = element as! Photo
            let destinationUrl = appDelegate.documentsDirectory.URLByAppendingPathComponent(photo.fileName!)
            let downloader = FlickrImageDownloader(url: photo.remoteUrl!, destinationUrl: destinationUrl, callback: { (errorMessage) -> Void in
                let remaining = --self.remaining
                defer {
                    if remaining == 0 {
                        self.callback(success: (self.errors.count == 0), photos: self.photos)
                    }
                }
                guard errorMessage == nil else {
                    self.errors.append(errorMessage!)
                    self.delegate?.downloaderDidEncounterError?(errorMessage!, whileDownloadingPhoto: photo)
                    return
                }
                CoreDataManager.sharedInstance().saveContext()
                self.delegate?.downloaderDidDownloadPhoto?(photo)

            })
            downloader.begin()
        }
    }
}
