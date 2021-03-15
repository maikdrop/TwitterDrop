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
    
    deinit { print("DEINIT - OfflineTimelineTVC") }
    
    // MARK: - Overriden methods from base class
    override func setProfileImage(for userID: String, image: UIImage) {
        super.setProfileImage(for: userID, image: image)
        updateDatabase(for: userID, with: image)
    }
    
    override func credentialCheckFailed() {
        if isConnected {
            super.credentialCheckFailed()
        } else {
            setProfileImageFromDB()
            self.tableView.refreshControl?.endRefreshing()
        }
    }
    
    override func insertTweets(_ newTweets: [MyTwitterDrop.Tweet]) {
        updateDatabase(with: newTweets)
        super.insertTweets(newTweets)
    }
    
    override func fetchProfileImage(for users: Set<MyTwitterDrop.User>, completionHandler: @escaping () -> Void) {
        
        if users.count == 1 && users.first?.id == Authorize.loggedUserID {
            updateDatabase(with: users.first!)
        }
        lookUpDatabase(for: users) { [weak self] usersNotInDB in
            self?.superFetchProfileImage(for: usersNotInDB, completionHandler: completionHandler)
        }
    }
}

// MARK - Default methods
extension OfflineTimelineTVC {
 
    override func viewDidLoad() {
        super.viewDidLoad()
        startNetworkMonitor()
        loadTweetsFromDatabase { [weak self] loadedTweets in
            self?.superInsertTweets(tweets: loadedTweets)
            DispatchQueue.main.async {
                self?.superCheckUserCredentials()
            }
        }
    }
}

// MARK: - Private DB handling methods
private extension OfflineTimelineTVC {

    private func lookUpDatabase(for users: Set<MyTwitterDrop.User>, completionHandler: @escaping (Set<MyTwitterDrop.User>) -> Void) {
        var usersToLookUp = users
        var userImagesNotInDB = Set<MyTwitterDrop.User>()
        container?.performBackgroundTask { context in
            for user in users {
                usersToLookUp.remove(user)
                if let twitterUser = try? TwitterUser.findTwitterUser(userID: user.id, in: context) {
                    if let imageData = twitterUser.profileImage, let image = UIImage(data: imageData) {
                        Self.cache.insert(image, forKey: user.id)
                    } else {
                        userImagesNotInDB.insert(user)
                    }
                } else {
                    userImagesNotInDB.insert(user)
                }
                if usersToLookUp.isEmpty {
                    completionHandler(userImagesNotInDB)
                }
            }
        }
    }
    
    private func superFetchProfileImage(for users: Set<MyTwitterDrop.User>, completionHandler: @escaping () -> Void) {
        super.fetchProfileImage(for: users, completionHandler: completionHandler)
    }
    
    private func superCheckUserCredentials() {
        super.checkUserCredentials()
    }
    
    private func superInsertTweets(tweets: [MyTwitterDrop.Tweet]) {
        super.insertTweets(tweets)
    }
    
    private func loadTweetsFromDatabase(completion: @escaping ([MyTwitterDrop.Tweet]) -> Void) {
        container?.performBackgroundTask { [weak self] context in
            if let fetchedTweets = try? Tweet.findTweets(in: context) {
                if let tweetsToDisplay = self?.createTweets(from: fetchedTweets) {
                    completion(tweetsToDisplay)
                } else {
                    completion([])
                }
            } else {
                completion([])
            }
        }
    }
    
    private func createTweets(from dbTweets: [Tweet]) -> [MyTwitterDrop.Tweet] {
        var tweets = [MyTwitterDrop.Tweet]()
        for dbTweet in dbTweets {
            if let twitterUser = dbTweet.tweeter, let text = dbTweet.text, let created = dbTweet.created, let unique = dbTweet.unique {
                let screenName = twitterUser.screenName ?? ""
                let name = twitterUser.name ?? ""
                let id = twitterUser.id ?? ""
                let profileImageUrl = twitterUser.profileImageUrl ?? ""
                let user = MyTwitterDrop.User(screenName: screenName, name: name, id: id, verified: twitterUser.verified, profileImageURL: profileImageUrl)
                let tweet = MyTwitterDrop.Tweet(text: text, user: user, created: created, identifier: unique)
                tweets.append(tweet)
            }
        }
        return tweets
    }
    
    private func updateDatabase(with user: MyTwitterDrop.User) {
        container?.performBackgroundTask { context in
            _ = try? TwitterUser.findOrCreateTwitterUser(matching: user, in: context)
            // TODO Error Handling
            try? context.save()
        }
    }
    
    private func updateDatabase(for userID: String, with profileImage: UIImage) {
        container?.performBackgroundTask { context in
            _ = try? TwitterUser.updateTwitterUser(userID: userID, with: profileImage, context: context)
            // TODO Error Handling
            try? context.save()
        }
    }
    
    private func updateDatabase(with tweets: [MyTwitterDrop.Tweet]) {
        container?.performBackgroundTask { context in
            for tweet in tweets {
                _ = try? Tweet.findOrCreateTweet(matching: tweet, in: context)
            }
            try? context.save()
        }
    }
    
    private func setProfileImageFromDB() {
        if let userID = Authorize.loggedUserID, let context = container?.viewContext {
            if let user = try? TwitterUser.findTwitterUser(userID: userID, in: context) {
                if let imageData = user.profileImage, let profileImage = UIImage(data: imageData) {
                    super.setProfileImage(for: userID, image: profileImage)
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
//            print(path.isExpensive)
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

// MARK: - Constants
private extension OfflineTimelineTVC {
    
    private var queueLbl: String { "Monitor" }
}