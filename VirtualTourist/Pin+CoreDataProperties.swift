//
//  Pin+CoreDataProperties.swift
//  VirtualTourist
//
//  Created by Bill Dawson on 1/19/16.
//  Copyright © 2016 Bill Dawson. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData
import MapKit

extension Pin {
    @NSManaged var longitude: NSNumber?
    @NSManaged var latitude: NSNumber?
    @NSManaged var photos: NSOrderedSet?

}
