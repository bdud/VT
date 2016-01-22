//
//  ClientConstants.swift
//
//  Created by Bill Dawson on 11/10/15.
//  Copyright © 2015 Bill Dawson. All rights reserved.
//

import Foundation

extension ClientConvenience {
    struct HTTPHeaderKeys {
        static let Accept = "Accept"
        static let ContentType = "Content-Type"
    }

    struct HTTPHeaderValues {
        static let JSON = "application/json"
    }

    struct ErrorStrings {
        static let Connection = "The server could not be reached. Please check your Internet connection and try again."
        static let General = "There was a problem communicating with the server."
        static let ServerData = "The server returned unexpected data."

        static func forError(error: NSError) -> String {
            guard error.domain == NSURLErrorDomain else {
                return self.General
            }

            let code = error.code

            switch code {
            case NSURLErrorCannotFindHost, NSURLErrorCannotConnectToHost, NSURLErrorNetworkConnectionLost, NSURLErrorNotConnectedToInternet:
                return self.Connection
            default:
                return self.General
            }
        }

    }
}
