//
//  FlickrImageDownloader.swift
//  VirtualTourist
//
//  Created by Bill Dawson on 1/22/16.
//  Copyright © 2016 Bill Dawson. All rights reserved.
//

import UIKit

typealias ImageDownloadCallback = (errorMessage: String?) -> Void

class FlickrImageDownloader {
    private var task: NSURLSessionDownloadTask?
    private var callback: ImageDownloadCallback!
    private var url: NSURL!
    private var destinationUrl: NSURL!

    // MARK: - Initializers

    init(url: String, destinationUrl: NSURL, callback: ImageDownloadCallback) {
        self.url = NSURL(string: url)!
        self.callback = callback
        self.destinationUrl = destinationUrl
    }


    // MARK: - Network

    func begin() {
        task = ClientConvenience.sharedInstance().downloadTaskWithRequest(NSURLRequest(URL: url), andDestinationUrl: destinationUrl, andCompletionHandler: callback)
        task!.resume()
    }


    func isRunning() -> Bool {
        if let task = task where task.state == NSURLSessionTaskState.Running {
            return true
        }
        return false
    }
}
