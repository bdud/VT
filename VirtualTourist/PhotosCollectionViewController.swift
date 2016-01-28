//
//  PhotosCollectionViewController.swift
//  VirtualTourist
//
//  Created by Bill Dawson on 1/20/16.
//  Copyright © 2016 Bill Dawson. All rights reserved.
//

import UIKit
import CoreData
import MapKit

private let reuseIdentifier = "Cell"
private let cellNib = "PhotoCollectionViewCell"
private let defaultItemCount = 21

class PhotosCollectionViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, PhotoBatchDownloaderDelegate {

    struct Constants {
        static let BackButtonTitle = "Map"
        static let QueryCreationError = "Unable to create Flickr request."
    }

    // MARK: - Outlets

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var mapView: MKMapView!
    
    // MARK: - Properties

    var pin: Pin?
    var flickrQuery: FlickrClient.QueryState?
    var batchDownloader: PhotoBatchDownloader?

    override func viewDidLoad() {
        super.viewDidLoad()
        automaticallyAdjustsScrollViewInsets = false

        collectionView!.registerNib(UINib(nibName: cellNib, bundle: nil), forCellWithReuseIdentifier: reuseIdentifier)
        collectionView.delegate = self
        collectionView.dataSource = self

        // Queue these up just so the segue doesn't look too delayed.
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            self.fetchPhotosIfNeeded()
            self.positionMap()
        }
    }

    // MARK: UICollectionViewDataSource

    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }


    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let pin = pin, photos = pin.photos {
            print("\(photos.count) photos in section")
            return photos.count > 0 ? photos.count : defaultItemCount
        }
        else {
            return defaultItemCount
        }
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! PhotoCollectionViewCell

        if let photos = self.pin?.photos where indexPath.row < photos.count {
            if let photo = photos.objectAtIndex(indexPath.row) as? Photo {
                // Remember our row since we're going to do an async op to get
                // the photo image, and we'll only display it later if in fact we
                // are still sitting in same place. Else all hell breaks loose since
                // cells are recycled.
                cell.tag = indexPath.row

                photo.image({ (errorMessage, image) -> Void in
                    guard errorMessage == nil else {
                        print("Error getting image: \(errorMessage!)")
                        return
                    }

                    // Are we still at the same row or have we scrolled away?
                    // If so, go ahead and set the image.
                    if let image = image {
                        if indexPath.row == cell.tag {
                            dispatch_async(dispatch_get_main_queue()) {
                                cell.setImage(image)
                            }
                        }
                    }
                })
            }
        }

    
        return cell
    }

    // MARK: UICollectionViewDelegate

    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(collectionView: UICollectionView, shouldHighlightItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(collectionView: UICollectionView, shouldShowMenuForItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false
    }

    override func collectionView(collectionView: UICollectionView, canPerformAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) -> Bool {
        return false
    }

    override func collectionView(collectionView: UICollectionView, performAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) {
    
    }
    */

    // MARK: - Data and Downloads

    lazy var sharedContext: NSManagedObjectContext = {
        return CoreDataManager.sharedInstance().context
    }()

    func reloadData() {
        if !NSThread.isMainThread() {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.reloadData()
            })
            return
        }

        assert(NSThread.isMainThread())

        collectionView.reloadData()
    }

    func fetchPhotosIfNeeded() {
        guard let pin = pin else {
            print("No Pin passed to PhotosCollectionViewController")
            return
        }

        if let photos = pin.photos {
            if photos.count > 0 {
                // No Flickr fetch necessary
                print("Already have \(photos.count) photos for this pin, no fetch needed")
                return
            }
        }

        flickrQuery = FlickrClient.QueryState(page: 1, latitude: pin.coordinate.latitude, longitude: pin.coordinate.longitude)

        print("Fetching info from Flickr")
        FlickrClient.sharedInstance().queryPhotosByLocation(flickrQuery!) { (errorMessage, result) -> Void in
            guard errorMessage == nil else {
                Alert.sharedInstance().ok(nil, message: errorMessage!, owner: self, completion: nil)
                return
            }
            guard let result = result else {
                print("No error message, but no result either")
                Alert.sharedInstance().ok(nil, message: ClientConvenience.ErrorStrings.ServerData, owner: self, completion: nil)
                return
            }

            self.flickrQuery!.page = result.page
            self.flickrQuery!.totalPages = result.totalPages

            // Make managed Photo objects.
            result.photos.forEach({ (entry: [String: AnyObject]) -> () in
                if let url = entry[FlickrClient.JSONKeys.Url] as? String, id = entry[FlickrClient.JSONKeys.ID] as? String {
                    let _ = Photo(pin: self.pin!, url: url, fileName: id, insertIntoManagedObjectContext: self.sharedContext)
                }
            })
            CoreDataManager.sharedInstance().saveContext()

            self.reloadData()

            self.batchDownloader = PhotoBatchDownloader(photos: self.pin!.photos!, callback: { (success, photos) -> Void in
                print("Downloads completed")
                self.reloadData()
                self.batchDownloader = nil
            })

            self.batchDownloader?.delegate = self

            self.batchDownloader?.begin()
        }
    }

    // MARK: - Map

    func positionMap() {
        guard let pin = pin else {
            return
        }

        mapView.addAnnotation(pin)
        let region = MKCoordinateRegionMakeWithDistance(pin.coordinate, 5000.0, 5000.0)

        mapView.setRegion(region, animated: true)

    }

    // MARK: - UICollectionViewDelegateFlowLayout

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSizeMake(100.0, 100.0)
    }
}
