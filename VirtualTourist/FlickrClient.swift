//
//  FlickrClient.swift
//  VirtualTourist
//
//  Created by Bill Dawson on 1/20/16.
//  Copyright © 2016 Bill Dawson. All rights reserved.
//

import Foundation


class FlickrClient {

    func queryPhotosByLocation(query: QueryState, callback: (errorMessage: String?, result: FlickrClient.Result?) -> Void) {
        guard let url = query.url() else {
            print("Unable to build url for query")
            callback(errorMessage: ErrorStrings.Url, result: nil)
            return
        }

        let request = NSMutableURLRequest(URL: url)
        request.setValue(ClientConvenience.HTTPHeaderValues.JSON, forHTTPHeaderField: ClientConvenience.HTTPHeaderKeys.Accept)

        ClientConvenience.sharedInstance().performDataTaskWithRequest(request) { (success, httpStatusCode, errorMessage, responseData) -> Void in
            guard success else {
                print("request failed: \(httpStatusCode), \(errorMessage)")
                if let data = responseData {
                    if let stringData = NSString(data: data, encoding: NSUTF8StringEncoding) {
                        print("Despite failure, data was returned: \(stringData)")
                    }
                }
                let errorString = errorMessage ?? ClientConvenience.ErrorStrings.General
                callback(errorMessage: errorString, result: nil)
                return

            }

            guard let data = responseData else {
                print("No response data")
                callback(errorMessage: ClientConvenience.ErrorStrings.ServerData, result: nil)
                return
            }

            do {
                var parsed: AnyObject?
                try parsed = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions(rawValue: 0))

                guard let jsonDict = parsed as? [String: AnyObject] else {
                    print("Could not convert the data to a dictionary")
                    callback(errorMessage: ClientConvenience.ErrorStrings.ServerData, result: nil)
                    return
                }

                guard let resultInstance = Result.fromDictionary(jsonDict) else {
                    print("Could not build Result instance from dictionary")
                    callback(errorMessage: ClientConvenience.ErrorStrings.ServerData, result: nil)
                    return
                }

                callback(errorMessage: nil, result: resultInstance)

            }
            catch {
                let error = error as NSError
                print("JSON Error: \(error.localizedDescription) \(error.userInfo)")
                callback(errorMessage: ClientConvenience.ErrorStrings.ServerData, result: nil)
                return
            }
        }
    }

    // MARK: - Singleton

    class func sharedInstance() -> FlickrClient {
        struct Singleton {
            static let instance = FlickrClient()
        }
        return Singleton.instance
    }

}