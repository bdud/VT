//
//  MapViewController.swift
//  VirtualTourist
//
//  Created by Bill Dawson on 1/19/16.
//  Copyright © 2016 Bill Dawson. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController, MKMapViewDelegate, NSFetchedResultsControllerDelegate {
    enum Mode {
        case Browse
        case Edit
    }

    struct Constants {
        static let PinReuseId = "pinReuseId"
        static let EditTitle = "Edit"
        static let DoneTitle = "Done"
        static let AnimationDuration = 0.4
        static let PhotosSegueId = "SegueToPhotos"
        static let MapRegionKey = "MapRegionKey"
        static let DeletePinsText = "Tap Pins to Delete"
        static let DeletePinsBackColor = UIColor.redColor()
        static let NoMorePinsText = "No Remaining Pins"
        static let NoMorePinsBackColor = UIColor.darkGrayColor()
    }

    // MARK: - Outlets

    @IBOutlet weak var editButton: UIBarButtonItem!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var deleteLabel: UILabel!

    // MARK: - Properties

    var longPressRecognizer: UILongPressGestureRecognizer!
    var mode: Mode = .Browse
    var lastSelectedPin: Pin?
    var trackMapRegionChanges: Bool = false

    // MARK: UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()
        setupLongPress()
        mapView.delegate = self
        resultsController.delegate = self
        loadPins()
        enableEditButton()
    }


    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        setMapRegion()
        trackMapRegionChanges = true
    }

    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        trackMapRegionChanges = false
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        guard segue.identifier! == Constants.PhotosSegueId else {
            return
        }
        guard let controller = segue.destinationViewController as? PhotosCollectionViewController else {
            print("Unexpected segue destination controller")
            return
        }

        guard let pin = lastSelectedPin else {
            print("No selected pin")
            return
        }

        controller.pin = pin
        mapView.deselectAnnotation(pin, animated: false)

    }

    // MARK: - Actions
    
    @IBAction func editTouchUp(sender: AnyObject) {
        toggleEditMode()
    }

    // MARK: - MapKit

    func makeAnnotation(coordinate: CLLocationCoordinate2D) -> MKAnnotation {
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        return annotation
    }

    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        let view = (mapView.dequeueReusableAnnotationViewWithIdentifier(Constants.PinReuseId) ?? MKPinAnnotationView(annotation: annotation, reuseIdentifier: Constants.PinReuseId)) as! MKPinAnnotationView
        view.annotation = annotation
        view.animatesDrop = true
        return view
    }

    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        assertMainThread()
        if mode == .Edit {
            CoreDataManager.sharedInstance().context.deleteObject(view.annotation as! NSManagedObject)
            CoreDataManager.sharedInstance().saveContext()
            if resultsController.sections?[0].numberOfObjects == 0 {

                // Stop editing, there's nothing left

                deleteLabel.backgroundColor = Constants.NoMorePinsBackColor
                deleteLabel.text = Constants.NoMorePinsText

                let delay = dispatch_time(DISPATCH_TIME_NOW, Int64(NSEC_PER_SEC)) // 1 sec
                dispatch_after(delay, dispatch_get_main_queue(), { () -> Void in
                    if self.mode == .Edit {
                        // Simulate stopping edit.
                        self.editTouchUp(self)
                    }
                })
            }
        }
        else {
            lastSelectedPin = view.annotation as? Pin
            performSegueWithIdentifier(Constants.PhotosSegueId, sender: self)
        }
    }

    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        if (!trackMapRegionChanges) {
            return
        }

        let newRegion = mapView.region
        let array: [Double] = [newRegion.center.latitude, newRegion.center.longitude, newRegion.span.latitudeDelta, newRegion.span.longitudeDelta]
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setObject(array, forKey: Constants.MapRegionKey)
        defaults.synchronize()
    }

    // MARK: - Gestures

    func longPress(recognizer: UIGestureRecognizer) {
        if recognizer.state == .Began {
            let pressPoint = recognizer.locationInView(mapView)
            let coord : CLLocationCoordinate2D = mapView.convertPoint(pressPoint, toCoordinateFromView: mapView)
            let _ = Pin(coordinate: coord, context: sharedContext)
            CoreDataManager.sharedInstance().saveContext()
        }
    }

    func setupLongPress() {
        longPressRecognizer = UILongPressGestureRecognizer(target: self, action: "longPress:")
        mapView.addGestureRecognizer(longPressRecognizer)
    }

    // MARK: - Data

    lazy var sharedContext: NSManagedObjectContext = {
        return CoreDataManager.sharedInstance().context
    }()

    lazy var resultsController: NSFetchedResultsController = {
        let request = NSFetchRequest(entityName: "Pin")
        request.sortDescriptors = [NSSortDescriptor(key: "latitude", ascending: true)]
        return NSFetchedResultsController(fetchRequest: request, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
    }()

    // MARK: - Misc

    func setMapRegion() {
        if let array = NSUserDefaults.standardUserDefaults().objectForKey(Constants.MapRegionKey) as? [Double] {
            let coord = CLLocationCoordinate2D(latitude: array[0], longitude: array[1])
            let region = MKCoordinateRegionMake(coord, MKCoordinateSpanMake(array[2], array[3]))
            mapView.setRegion(region, animated: true)
        }
    }

    func loadPins() {
        assertMainThread()
        do {
            try resultsController.performFetch()
        }
        catch {
            let error = error as NSError
            print("Error fetching pins from data store: \(error): \(error.userInfo)")
            return
        }
        mapView.addAnnotations(resultsController.fetchedObjects as! [Pin])
    }

    func toggleEditMode() {
        assertMainThread()
        mode = (mode == .Edit) ? Mode.Browse : Mode.Edit

        let height: CGFloat = deleteLabel.frame.height
        if mode == .Browse {
            editButton.title = Constants.EditTitle
            slideMapViewY(0.0)
        }
        else {
            deleteLabel.backgroundColor = Constants.DeletePinsBackColor
            deleteLabel.text = Constants.DeletePinsText

            editButton.title = Constants.DoneTitle
            slideMapViewY(height)
        }
    }

    func slideMapViewY(buffer: CGFloat) {
        assertMainThread()
        view.layoutIfNeeded()
        for constraint in self.mapView.constraintsAffectingLayoutForAxis(.Vertical) {
            if constraint.firstItem is MKMapView || constraint.secondItem is MKMapView {
                if constraint.firstAttribute == NSLayoutAttribute.Top || constraint.secondAttribute == NSLayoutAttribute.Top {
                    constraint.constant = -buffer
                }
                else if constraint.firstAttribute == NSLayoutAttribute.Bottom || constraint.secondAttribute == NSLayoutAttribute.Bottom {
                    constraint.constant = buffer
                }
            }
        }
        UIView.animateWithDuration(Constants.AnimationDuration) {
            self.view.layoutIfNeeded()
        }
    }

    func enableEditButton() {
        assertMainThread()
        editButton.enabled = resultsController.sections![0].numberOfObjects > 0
    }

    func assertMainThread() {
        assert(NSThread.isMainThread())
    }


    // MARK: - NSFetchedResultsControllerDelegate

    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        assertMainThread()
        switch type {
        case .Insert:
            mapView.addAnnotation(anObject as! Pin)
        case .Delete:
            mapView.removeAnnotation(anObject as! Pin)
        case .Update:
            mapView.removeAnnotation(anObject as! Pin)
            mapView.addAnnotation(anObject as! Pin)
        default:
            break
        }

        enableEditButton()
    }

}

