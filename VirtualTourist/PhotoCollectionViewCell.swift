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

    func setImage(image: UIImage?) {
        assert(NSThread.isMainThread())
        if let image = image {
            imageView.image = image
            activityIndicator.stopAnimating()
        }
        else {
            imageView.image = nil
            activityIndicator.startAnimating()
        }
    }
    
}
