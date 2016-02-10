//
//  Pin+CoreDataProperties.swift
//  VirtualTourist
//
//  Created by Bill Dawson on 2/10/16.
//  Copyright © 2016 Bill Dawson. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Pin {

    @NSManaged var latitude: NSNumber?
    @NSManaged var longitude: NSNumber?
    @NSManaged var lastFetchedPageNumber: NSNumber?
    @NSManaged var photos: NSOrderedSet?

}
