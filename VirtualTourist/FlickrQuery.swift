//
//  FlickrQuery.swift
//  VirtualTourist
//
//  Created by Bill Dawson on 1/20/16.
//  Copyright © 2016 Bill Dawson. All rights reserved.
//

import Foundation

extension FlickrClient {
    struct QueryState {
        let baseComponents: [String: String] = [
            QueryKeys.ApiKey: QueryValues.ApiKey,
            QueryKeys.Method: QueryValues.PhotoSearchMethod,
            QueryKeys.Extras: QueryValues.UrlExtra,
            QueryKeys.NoJsonCallback: QueryValues.NoJsonCallbackValue,
            QueryKeys.Format: QueryValues.Format
        ]
        var page: Int!
        var totalPages: Int = 0
        var longitude: Double!
        var latitude: Double!

        init(page: Int, latitude: Double, longitude: Double) {
            self.page = page
            self.latitude = latitude
            self.longitude = longitude
        }

        func url() -> NSURL? {
            var components = baseComponents
            components[QueryKeys.Page] = String(page)
            components[QueryKeys.PerPage] = QueryValues.PerPage
            components[QueryKeys.Latitude] = String(latitude)
            components[QueryKeys.Longitude] = String(longitude)

            let queryItems = Array(components.keys).map { (key: String) -> NSURLQueryItem in
                return NSURLQueryItem(name: key, value: components[key])
            }

            let urlc = NSURLComponents(URL: Constants.BaseUrl, resolvingAgainstBaseURL: false)
            urlc?.queryItems = queryItems
            return urlc?.URL
        }
    }
}