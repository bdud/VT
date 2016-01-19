//
//  Pin+MKAnnotation.swift
//  VirtualTourist
//
//  Created by Bill Dawson on 1/19/16.
//  Copyright © 2016 Bill Dawson. All rights reserved.
//

import Foundation
import MapKit

extension Pin: MKAnnotation {
    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: self.latitude!.doubleValue, longitude: self.longitude!.doubleValue)
    }
}
