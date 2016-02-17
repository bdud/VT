//
//  PhotoCollectionViewCell.swift
//  VirtualTourist
//
//  Created by Bill Dawson on 1/22/16.
//  Copyright © 2016 Bill Dawson. All rights reserved.
//

import UIKit

class PhotoCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    override var selected: Bool {
        didSet {
            self.imageView.layer.opacity = selected ? 0.4 : 1.0
        }
    }

    func setImage(image: UIImage?) {
        assert(NSThread.isMainThread())
        if let image = image {
            imageView.image = image
            showIndicator(false)
        }
        else {
            imageView.image = nil
            showIndicator(true)
        }
    }

    func showIndicator(show: Bool) {
        assert(NSThread.isMainThread())

        imageView.hidden = show
        activityIndicator.hidden = !show

        if show {
            activityIndicator.startAnimating()
        }
        else {
            activityIndicator.stopAnimating()
        }
    }

    func hideIndicatorIfImage() {
        assert(NSThread.isMainThread())
        if let _ = imageView.image {
            showIndicator(false)
        }
    }


}
