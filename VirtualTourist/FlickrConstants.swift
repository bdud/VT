//
//  FlickrConstants.swift
//  VirtualTourist
//
//  Created by Bill Dawson on 1/20/16.
//  Copyright © 2016 Bill Dawson. All rights reserved.
//

import Foundation

extension FlickrClient {
    struct QueryKeys {
        static let Method = "method"
        static let ApiKey = "api_key"
        static let Extras = "extras"
        static let NoJsonCallback = "nojsoncallback"
        static let Format = "format"
        static let Latitude = "lat"
        static let Longitude = "lon"
        static let ContentType = "content_type"
        static let PerPage = "per_page"
        static let Page = "page"
    }

    struct QueryValues {
        static let PhotoSearchMethod = "flickr.photos.search"
        static let ApiKey = "6d8d83bb9efc878a046ecf37682018de"
        static let UrlExtra = "url_q"
        static let NoJsonCallbackValue = "1"
        static let Format = "json"
        static let ContentTypePhotosOnly = "1"
        static let PerPage = "21"
    }

    struct JSONKeys {
        static let Photos = "photos"
        static let Page = "page"
        static let Pages = "pages"
        static let Photo = "photo"
        static let Url = "url_q"
        static let ID = "id"

    }

    struct Constants {
        static let BaseUrl = NSURL(string: "https://api.flickr.com/services/rest")!
    }

    struct ErrorStrings {
        static let Url = "There was a problem preparing the network request."
    }
}