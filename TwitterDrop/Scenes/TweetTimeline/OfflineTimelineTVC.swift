/*
 MIT License

Copyright (c) 2021 Maik Müller (maikdrop) <maik_mueller@me.com>

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 
 Abstract:
 The class is responsible for writing into and reading from database. New data (tweets and profile images) coming from the base class are used to update the database. Fetched data from the database will be used to call base class methods.
 */

import UIKit
import CoreData
import MyTwitterDrop

class OfflineTimelineTVC: TweetTimelineTableViewController {
    
    // MARK: - Properties
    var container: NSPersistentContainer? = AppDelegate.persistentContainer
    
    deinit { print("DEINIT - OfflineTimelineTVC") }
    
    // MARK: - Overriden methods from base class
    
    /**
     Fetches tweets from the database and inserts them in the data source.
     
     - Parameter request: The tweets request.
     */
    override func fetchTweets(for request: Request) {
       
        if let id = Authentication.loggedInUserId {
          
            if tweets.isEmpty {
                
                DBHelper.shared.lookUpInDatabaseForTimeline(of: id) { [weak self] fetchedTweets in
                    
                    self?.superInsertTweets(tweets: fetchedTweets)
                    
                    if fetchedTweets.isEmpty {
                        
                        self?.superFetchTweets(for: request)
                        
                    } else {
                        
                        request.min_id = fetchedTweets.first?.identifier
                        
                        if let newerRequest = request.newer {
                            
                            self?.superFetchTweets(for: newerRequest)
                        }
                    }
                }
            } else {
                
                self.superFetchTweets(for: request)
            }
        }
    }
    
    /**
     Updates the database with new tweets and inserts them into the data source.
     
     - Parameter newTweets: The tweets to update in the database.
     */
    override func insertTweets(_ newTweets: [MyTwitterDrop.Tweet]) {
        
        if let id = Authentication.loggedInUserId {
         
            updateDatabase(with: newTweets, for: id)
        }
        super.insertTweets(newTweets)
    }

    /**
     Fetches the profile image of Twitter users from the database and updates the UI. If a profile image wasn't found, it will be fetched from the internet.
     
     - Parameter twitterUsers: The Twitter users from a Twitter request.
     */
    override func getProfileImage(for twitterUsers: Set<MyTwitterDrop.User>) {
        
        DBHelper.shared.lookUpInDatabase(for: twitterUsers) { [weak self] twitterUsersNotInDB, twitterUsersInDB in
           
            self?.superGetProfileImage(for: twitterUsersNotInDB)
            
            for (twitterUserInDB, profileImage) in twitterUsersInDB {

                self?.superUpdateProfileImage(profileImage, for: twitterUserInDB)
                
                TwitterUtility.checkForNewProfileImage(of: twitterUserInDB) { isAvailable in
                    
                    if !isAvailable && Network.shared.isConnected {
                        
                    // - in order to get the current profile image URL, the whole twitter user has to be fetched from Twitter again
                    // - this request doesnt't exist anymore in the standard Twitter API
                        
//                        self?.superGetProfileImage(for: Set([fetchedTwitterUser]))
                    }
                }
            }
        }
    }
    
    /**
     Updates a Twitter user in the database with a new profile image.
     
     - Parameter image: The profile image of the Twitter user.
     - Parameter twitterUserId: The user id of the Twitter user.
     */
    override func updateProfileImage(_ image: UIImage, for twitterUser: MyTwitterDrop.User) {
        super.updateProfileImage(image, for: twitterUser)

        updateDatabase(with: image, for: twitterUser)
    }
}

// MARK: - Private methods for updating the database
private extension OfflineTimelineTVC {
    
    /**
     Updates the profile image of a Twitter user in the database.
     
     - Parameter profileImage: The profile image of the Twitter user.
     - Parameter userId: The user id of the Twitter user.
     */
    private func updateDatabase(with profileImage: UIImage, for twitterUser: MyTwitterDrop.User) {
       
        container?.performBackgroundTask { context in
            
            // TODO Error Handling
            if profileImage != TwitterUtility.defaultProfileImage {
  
                _ = try? TwitterUser.updateTwitterUser(matching: twitterUser, with: profileImage, in: context)
                
                try? context.save()
            }
        }
    }
    
    /**
     Updates the timeline of a Twitter user with new tweets in the database.
     
     - Parameter tweets: The new Tweets of the Timeline.
     - Parameter userId: The user id of the Twitter user.
     */
    private func updateDatabase(with tweets: [MyTwitterDrop.Tweet], for userId: String) {
        
        container?.performBackgroundTask { context in
           
            for tweet in tweets {
                
                // TODO Error Handling
                _ = try? Timeline.findOrCreateTimeline(matching: userId, tweet: tweet, in: context)
            }
            try? context.save()
        }
    }
}

// MARK: - Call base class methods when self is weak.
private extension OfflineTimelineTVC {
    
    private func superGetProfileImage(for twitterUsers: Set<MyTwitterDrop.User>) {
        super.getProfileImage(for: twitterUsers)
    }
    
    private func superUpdateProfileImage(_ image: UIImage, for twitterUser: MyTwitterDrop.User) {
        super.updateProfileImage(image, for: twitterUser)
    }
    
    private func superFetchTweets(for request: MyTwitterDrop.Request) {
        super.fetchTweets(for: request)
    }
    
    private func superInsertTweets(tweets: [MyTwitterDrop.Tweet]) {
        super.insertTweets(tweets)
    }
}
