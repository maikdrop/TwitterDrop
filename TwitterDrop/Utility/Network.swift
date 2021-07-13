/*
 MIT License

Copyright (c) 2021 Maik Müller (maikdrop) <maik_mueller@me.com>

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 
 Abstract:
 Simple struct to monitor the network connection status and fetch data from a url.
 */

import UIKit
import MyTwitterDrop
import Network

class Network {
    
    // MARK: - Properties
    static let shared = Network()
    private let monitor: NWPathMonitor
    private(set) var isConnected: Bool = true
    
    private init() {
        self.monitor = NWPathMonitor()
        let queue = DispatchQueue.global(qos: .userInteractive)
        monitor.start(queue: queue)
    }
    
    /**
     Starts the monitoring of the network connection status.
     */
    func startNetworkMonitor() {
        
        monitor.pathUpdateHandler = { path in
            
            self.isConnected = path.status == .satisfied
        }
    }
    
    /**
     Stops the monitoring of the network connection status.
     */
    func stopMonitoring() {
        
        monitor.cancel()
    }
    
    /**
     Fetches data from a url.
     
     - Parameter url: The url of the request.
     - Parameter completion: Calls back when the request is completed.
     */
    func fetchData(from url: URL, completion: @escaping (Data?) -> Void) {
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            
            guard error == nil else {
                print(#function)
                print("Error: \(error!.localizedDescription)")
                completion(nil)
                return
            }
            
            guard let responseData = data else {
                print(#function)
                print("Error: did not receive data")
                completion(nil)
                return
            }
            
            completion(responseData)
            
        }.resume()
    }
    
    /**
     Pings a url.
     
     - Parameter url: The url to ping.
     - Parameter completion: Calls back with true if the url is accessible.
     */
    func ping(url: URL, completion: @escaping (Bool) -> Void) {

        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"

        URLSession(configuration: .default).dataTask(with: request) { (_, response, error) in

            guard error == nil else {
                print(#function)
                print("Error: \(error!.localizedDescription)")
                completion(false)
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                completion(false)
                return
            }

            if httpResponse.statusCode == StatusCode.accessForbidden || httpResponse.statusCode == StatusCode.fileNotFound {
              completion(false)
              return
            }
            completion(true)
        }
        .resume()
    }
}

// MARK: - Constants
private extension Network {
    
    private var queueLbl: String { "Monitor" }
    
    private struct StatusCode {
        static var accessForbidden: Int { 403 }
        static var fileNotFound: Int { 404 }
    }
}
