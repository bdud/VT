import Foundation


class ClientConvenience {

    func preparePostRequest(url: NSURL, jsonDataDictionary: [NSString: AnyObject]) -> NSMutableURLRequest? {
        let request: NSMutableURLRequest = NSMutableURLRequest(URL: url)
        request.HTTPMethod = "POST"
        request.setValue(HTTPHeaderValues.JSON, forHTTPHeaderField: HTTPHeaderKeys.Accept)
        request.setValue(HTTPHeaderValues.JSON, forHTTPHeaderField: HTTPHeaderKeys.ContentType)

        guard let jsonData = try? NSJSONSerialization.dataWithJSONObject(jsonDataDictionary, options: NSJSONWritingOptions(rawValue: 0)) else {
            print("Unable to convert POST data to JSON")
            return nil
        }

        request.HTTPBody = jsonData

        return request

    }

    func performDataTaskWithRequest(request: NSURLRequest, andCompletionHandler handler: (success: Bool, httpStatusCode: Int?, errorMessage: String?, responseData: NSData?) -> Void) {
        let session = NSURLSession.sharedSession()
        let task = session.dataTaskWithRequest(request) { (data, response, error) -> Void in
            guard error == nil else {
                handler(success: false, httpStatusCode: nil, errorMessage: ErrorStrings.forError(error!), responseData: nil)
                return
            }

            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
                if let response = response as? NSHTTPURLResponse {
                    print("Invalid response. Status code: \(response.statusCode)")
                    handler(success: false, httpStatusCode: response.statusCode, errorMessage: ErrorStrings.General, responseData: data)
                } else if let response = response {
                    print("No HTTP URL response received. Actual response: \(response)")
                    handler(success: false, httpStatusCode: nil, errorMessage: ErrorStrings.General, responseData: data)
                } else {
                    print("No response received (NSHttpURLResponse is nil)")
                    handler(success: false, httpStatusCode: nil, errorMessage: ErrorStrings.General, responseData: data)
                }
                return
            }

            guard let data = data else {
                print("No data was returned by server")
                handler(success: false, httpStatusCode: statusCode, errorMessage: ErrorStrings.ServerData, responseData: nil)
                return
            }

            handler(success: true, httpStatusCode: statusCode, errorMessage: nil, responseData: data);

        }

        task.resume()
    }

    // MARK: Class (static) functions

    class func sharedInstance() -> ClientConvenience {
        struct Singleton {
            static var instance = ClientConvenience()
        }
        return Singleton.instance
    }
}