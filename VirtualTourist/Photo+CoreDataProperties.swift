//
//  Photo+CoreDataProperties.swift
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

extension Photo {

    @NSManaged var url: String?
    @NSManaged var pin: Pin?

}
