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
private let itemsPerRow = 3
private let spacing: CGFloat = 4.0

class PhotosCollectionViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, PhotoBatchDownloaderDelegate {

    struct Constants {
        static let BackButtonTitle = "Map"
        static let QueryCreationError = "Unable to create Flickr request."
    }

    // MARK: - Outlets

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var newCollectionButton: UIButton!
    
    // MARK: - Properties

    var pin: Pin?
    var batchDownloader: PhotoBatchDownloader?

    // MARK: - UIView

    override func viewDidLoad() {
        super.viewDidLoad()
        automaticallyAdjustsScrollViewInsets = false

        collectionView!.registerNib(UINib(nibName: cellNib, bundle: nil), forCellWithReuseIdentifier: reuseIdentifier)
        collectionView.delegate = self
        collectionView.dataSource = self

        fetchPhotosIfNeeded()
        positionMap()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        collectionView.collectionViewLayout.invalidateLayout()
    }

    override func didReceiveMemoryWarning() {
        print("Memory warning received in PhotosCollectionViewController")
        if let pin = pin, photos = pin.photos {
            photos.forEach({ (obj: AnyObject) -> () in
                if let photo = obj as? Photo {
                    photo.clearCachedImage()
                }
            })
        }
    }
    // MARK: - Actions

    @IBAction func newCollectionTouchUp(sender: AnyObject) {

        guard let pin = pin else {
            print("Ignoring request to fetch next page: pin is not set.")
            return
        }

        var pageNumber = pin.lastFetchedPageNumber!.integerValue
        if pageNumber == 0 {
            pageNumber = 1
        }

        collectionView.visibleCells().forEach { (cell: UICollectionViewCell) -> () in
            if let cell = cell as? PhotoCollectionViewCell {
                cell.showIndicator(true)
            }
        }

        performPhotoFetch(FlickrClient.QueryState(page: pageNumber + 1, latitude: pin.coordinate.latitude, longitude: pin.coordinate.longitude))

    }


    // MARK: - UICollectionViewDataSource

    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }


    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let pin = pin, photos = pin.photos {
            return photos.count > 0 ? photos.count : defaultItemCount
        }
        else {
            return defaultItemCount
        }
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! PhotoCollectionViewCell
        cell.setImage(nil)

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

    // MARK: - UICollectionViewDelegate

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
                self.collectionView.reloadData()
            })
        }
        else {
            collectionView.reloadData()
        }
    }

    func performPhotoFetch(flickrQuery: FlickrClient.QueryState) {
        print("Fetching info from Flickr")
        self.enableFetchButton(false)

        FlickrClient.sharedInstance().queryPhotosByLocation(flickrQuery) { (errorMessage, result) -> Void in
            guard errorMessage == nil else {
                Alert.sharedInstance().ok(nil, message: errorMessage!, owner: self, completion: nil)
                self.enableFetchButton(true)
                self.stopActivityIndicators();
                return
            }
            guard let result = result else {
                print("No error message, but no result either")
                Alert.sharedInstance().ok(nil, message: ClientConvenience.ErrorStrings.ServerData, owner: self, completion: nil)
                self.enableFetchButton(true)
                self.stopActivityIndicators();
                return
            }

            self.pin?.lastFetchedPageNumber = result.page

            // We only keep one collection (page) of photos in storage, so if any are there
            // now, delete them.
            if let pin = self.pin, photos = pin.photos {
                for entry in photos {
                    let p = entry as! Photo
                    self.sharedContext.deleteObject(p)
                }
            }

            // Make new managed Photo objects.
            result.photos.forEach({ (entry: [String: AnyObject]) -> () in
                if let url = entry[FlickrClient.JSONKeys.Url] as? String, id = entry[FlickrClient.JSONKeys.ID] as? String {
                    let _ = Photo(pin: self.pin!, url: url, fileName: id, insertIntoManagedObjectContext: self.sharedContext)
                }
            })
            CoreDataManager.sharedInstance().saveContext()

            self.reloadData()

            self.batchDownloader = PhotoBatchDownloader(photos: self.pin!.photos!, callback: { (success, photos) -> Void in
                self.batchDownloader = nil
                if success {
                    print("Downloads completed")
                    self.reloadData()
                    self.enableFetchButton(true)
                }
                else {
                    self.stopActivityIndicators()
                }
            })

            self.batchDownloader?.delegate = self

            self.batchDownloader?.begin()

        }

    }

    func fetchPhotosIfNeeded() {
        assert(NSThread.isMainThread())
        guard let pin = pin else {
            print("No Pin passed to PhotosCollectionViewController")
            return
        }

        if let photos = pin.photos {
            if photos.count > 0 {
                enableFetchButton(true)
                // No Flickr fetch necessary
                print("Already have \(photos.count) photos for this pin, no fetch needed")
                return
            }
        }

        var fetchPage = pin.lastFetchedPageNumber!.integerValue
        if fetchPage == 0 {
            fetchPage = 1
        }

        let flickrQuery = FlickrClient.QueryState(page: fetchPage, latitude: pin.coordinate.latitude, longitude: pin.coordinate.longitude)

        performPhotoFetch(flickrQuery)

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
        let viewWidth = collectionView.frame.size.width
        let totalSpacing = spacing * CGFloat(itemsPerRow + 1)
        var spaceForItems = viewWidth - totalSpacing

        if spaceForItems < 0.0 {
            spaceForItems = 0.0
        }

        let thisItem = spaceForItems / CGFloat(itemsPerRow)

        return CGSizeMake(thisItem, thisItem)
    }

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return CGFloat(spacing)
    }

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return CGFloat(spacing)
    }

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0.0, left: CGFloat(spacing), bottom: 0.0, right: CGFloat(spacing))
    }

    // MARK: UI Changes

    func enableFetchButton(enable: Bool) {
        if !NSThread.isMainThread() {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.newCollectionButton.enabled = enable
            })
        }
        else {
            newCollectionButton.enabled = enable
        }
    }

    func stopActivityIndicators() {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            self.collectionView.visibleCells().forEach({ (cell: UICollectionViewCell) -> () in
                if let cell = cell as? PhotoCollectionViewCell {
                    cell.showIndicator(false)
                }
            })
        }
    }
}
