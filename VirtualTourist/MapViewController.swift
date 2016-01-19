//
//  MapViewController.swift
//  VirtualTourist
//
//  Created by Bill Dawson on 1/19/16.
//  Copyright © 2016 Bill Dawson. All rights reserved.
//

import UIKit
import MapKit

private let PIN_REUSE_ID = "pinReuseId"

class MapViewController: UIViewController, MKMapViewDelegate {

    // MARK: - Outlets

    @IBOutlet weak var editButton: UIBarButtonItem!
    @IBOutlet weak var mapView: MKMapView!

    // MARK: - Properties

    var longPressRecognizer: UILongPressGestureRecognizer!

    // MARK: UIViewController
    override func viewDidLoad() {
        super.viewDidLoad()
        setupLongPress()
        mapView.delegate = self
    }

    // MARK: - Actions
    
    @IBAction func editTouchUp(sender: AnyObject) {
    }

    // MARK: - MapKit

    func makeAnnotation(coordinate: CLLocationCoordinate2D) -> MKAnnotation {
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        return annotation
    }

    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        let view = (mapView.dequeueReusableAnnotationViewWithIdentifier(PIN_REUSE_ID) ?? MKPinAnnotationView(annotation: annotation, reuseIdentifier: PIN_REUSE_ID)) as! MKPinAnnotationView
        view.annotation = annotation
        view.animatesDrop = true
        return view
    }

    // MARK: - Gestures

    func longPress(recognizer: UIGestureRecognizer) {
        if recognizer.state == .Began {
            print("Long press")
            let pressPoint = recognizer.locationInView(mapView)
            let coord : CLLocationCoordinate2D = mapView.convertPoint(pressPoint, toCoordinateFromView: mapView)
            mapView.addAnnotation(makeAnnotation(coord))
        }
    }

    func setupLongPress() {
        longPressRecognizer = UILongPressGestureRecognizer(target: self, action: "longPress:")
        mapView.addGestureRecognizer(longPressRecognizer)
    }

}

