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

class PhotosCollectionViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

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

    override func viewDidLoad() {
        super.viewDidLoad()
        automaticallyAdjustsScrollViewInsets = false

        collectionView.dataSource = self
        collectionView.delegate = self

        // Register cell classes
        collectionView!.registerNib(UINib(nibName: cellNib, bundle: nil), forCellWithReuseIdentifier: reuseIdentifier)

        fetchPhotosIfNeeded()
        positionMap()
    }


    // MARK: UICollectionViewDataSource

    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }


    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let pin = pin, photos = pin.photos {
            print("\(photos.count) photos in section")
            return photos.count
        }
        else {
            return 0
        }
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! PhotoCollectionViewCell
    
        // Configure the cell
        print("\(cell)")
    
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

    // MARK: - Data

    lazy var sharedContext: NSManagedObjectContext = {
        return CoreDataManager.sharedInstance().context
    }()

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

        print("Fetching from Flickr")
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
                if let url = entry[FlickrClient.JSONKeys.Url] as? String {
                    let _ = Photo(pin: self.pin!, url: url, insertIntoManagedObjectContext: self.sharedContext)
                }
            })
            CoreDataManager.sharedInstance().saveContext()
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
