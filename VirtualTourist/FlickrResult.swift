//
//  FlickrResult.swift
//  VirtualTourist
//
//  Created by Bill Dawson on 1/21/16.
//  Copyright © 2016 Bill Dawson. All rights reserved.
//

import Foundation

extension FlickrClient {
    struct Result {
        var page: Int
        var totalPages: Int
        var photos: [[String: AnyObject]]

        static func fromDictionary(dict: [String: AnyObject]) -> Result? {

            guard let root = dict[JSONKeys.Photos] as? [String: AnyObject] else {
                print("Could not get '\(JSONKeys.Photos)' value from dictionary")
                return nil
            }

            guard let page = root[JSONKeys.Page] as? Int else {
                print("Could not get '\(JSONKeys.Page)' value from dictionary")
                return nil
            }

            guard let pages = root[JSONKeys.Pages] as? Int else {
                print("Could not get '\(JSONKeys.Pages)' value from dictionary")
                return nil
            }

            guard let photos = root[JSONKeys.Photo] as? [[String: AnyObject]] else {
                print("Could not get '\(JSONKeys.Photo)' value from dictionary")
                return nil
            }

            return Result(page: page, totalPages: pages, photos: photos)
        }

    }

}