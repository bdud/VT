//
//  Photo.swift
//  VirtualTourist
//
//  Created by Bill Dawson on 1/19/16.
//  Copyright © 2016 Bill Dawson. All rights reserved.
//

import Foundation
import CoreData


class Photo: NSManagedObject {

    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }

    init(pin: Pin, url: String, insertIntoManagedObjectContext context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        self.url = url
        self.pin = pin
    }

    var fileName: String? {
        guard let urlString = self.url, url = NSURL(string: urlString) else {
            return nil
        }

        let path = url.path?.stringByReplacingOccurrencesOfString("/", withString: ".")
        return "\(url.host).\(path)"
    }

}
