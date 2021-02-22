/*
 MIT License

Copyright (c) 2021 Maik Müller (maikdrop) <maik_mueller@me.com>

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

import UIKit
import Network
import CoreData
import MyTwitterDrop

class OfflineTimelineTVC: TweetTimelineTableViewController {
    
    // MARK: - Properties
    var container: NSPersistentContainer? = AppDelegate.persistentContainer
    private lazy var noWifiBtn = createNoDataConBarBtn()
    private let monitor = NWPathMonitor()
    private var isConnected: Bool = true {
        didSet {
            self.navigationItem.leftBarButtonItem = isConnected ? nil : self.noWifiBtn
        }
    }
    
    // MARK: - Overriden methods from base class
    override func fetchProfileImage(from user: MyTwitterDrop.User) {
        super.fetchProfileImage(from: user)
        updateDatabase(with: user)
    }
    
    override func setUserProfileImage(image: UIImage) {
        super.setUserProfileImage(image: image)
        updateDatabase(with: image)
    }
    
    override func credentialCheckFailed() {
        if isConnected {
            super.credentialCheckFailed()
        } else {
            setProfileImageFromDB()
        }
    }
}

// MARK - Default methods
extension OfflineTimelineTVC {
 
    override func viewDidLoad() {
        super.viewDidLoad()
        startNetworkMonitor()
    }
}

// MARK: - Private DB handling methods
private extension OfflineTimelineTVC {
    
    private func updateDatabase(with user: MyTwitterDrop.User) {
        container?.performBackgroundTask { context in
            _ = try? TwitterUser.findOrCreateTwitterUser(matching: user, in: context)
            // TODO Error Handling
            try? context.save()
        }
    }
    
    private func updateDatabase(with profileImage: UIImage) {
        if let loggedUserId = Authorize.loggedUserID {
            container?.performBackgroundTask { context in
                _ = try? TwitterUser.updateTwitterUser(matching: loggedUserId, with: profileImage, context: context)
                // TODO Error Handling
                try? context.save()
            }
        }
    }
    
    private func setProfileImageFromDB() {
        if let loggedUserId = Authorize.loggedUserID, let context = container?.viewContext {
            if let user = try? TwitterUser.findTwitterUser(matching: loggedUserId, in: context) {
                if let imageData = user.profileImage, let profileImage =  UIImage(data: imageData) {
                    super.setUserProfileImage(image: profileImage)
                }
            }
        }
    }
    
}

// MARK: - Private utility methods
private extension OfflineTimelineTVC {
    
    private func startNetworkMonitor() {
        
        monitor.pathUpdateHandler = { path in
            DispatchQueue.main.async {
                if path.status == .satisfied {
                    self.isConnected = true
                } else {
                    self.isConnected = false
                }
            }
            print(path.isExpensive)
        }
        let queue = DispatchQueue(label: queueLbl, qos: .userInteractive)
        monitor.start(queue: queue)
    }
    
    private func createNoDataConBarBtn() -> UIBarButtonItem? {
        let button = UIButton()
        button.setTitle(AppStrings.Twitter.noConnection, for: .normal)
        button.setTitleColor(.red, for: .normal)
        return UIBarButtonItem(customView: button)
    }
    
}

private extension OfflineTimelineTVC {
    
    private var queueLbl: String { "Monitor" }
}
