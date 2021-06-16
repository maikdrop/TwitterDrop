/*
 MIT License
 
 Copyright (c) 2021 Maik Müller (maikdrop) <maik_mueller@me.com>
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 
 Abstract:
 Helper struct for reading from database.
 */

import Foundation
import MyTwitterDrop
import CoreData
import UIKit

struct DBHelper {
    
    // MARK: - Properties
    static let shared = DBHelper()
    
    private init() { }
    
    // MARK: - Properties
    var container: NSPersistentContainer? = AppDelegate.persistentContainer
    
    /**
     Looks up in the database for the profile image of Twitter users.
     
     - Parameter twitterUsers: The Twitter users from a Twitter request.
     - Parameter completion: Calls back with the Twitter users, whose profile image couldn't be found in the database as well as the users, whose profile image could be found.
     
     */
    func lookUpInDatabase(for twitterUsers: Set<MyTwitterDrop.User>, completion: @escaping (_ notInDB: Set<MyTwitterDrop.User>, _ inDB: Dictionary<MyTwitterDrop.User, UIImage>) -> Void) {
        
        var twitterUsersToLookup = twitterUsers
        
        var twitterUsersNotInDB = Set<MyTwitterDrop.User>()
        var twitterUsersInDB = Dictionary<MyTwitterDrop.User, UIImage>()
        
        container?.performBackgroundTask { context in
            
            for twitterUser in twitterUsers {

                twitterUsersToLookup.remove(twitterUser)
                
                if let image = checkForImage(from: twitterUser, in: context) {
                    
                    twitterUsersInDB[twitterUser] = image
               
                } else {
                    
                    twitterUsersNotInDB.insert(twitterUser)
                }
                
                if twitterUsersToLookup.isEmpty {
                    
                    completion(twitterUsersNotInDB, twitterUsersInDB)
                }
            }
        }
    }
    
    func loadTweetsFromDatabase(with searchTxt: String, completion: @escaping ([MyTwitterDrop.Tweet]) -> Void) {
        
        container?.performBackgroundTask { context in
            
            if let fetchedTweets = try? Tweet.findTweets(matchingMention: searchTxt, in: context) {
                
                let newTweets = TwitterUtility.mapTweets(from: fetchedTweets)
                
                if !newTweets.isEmpty {
                    
                    completion(newTweets)
                    
                    return
                }
            }
            completion([])
        }
    }
    
    /**
     Looks up in the database for tweets of a Twitter user timeline.
     
     - Parameter userId: The user id of the twitter user.
     - Parameter completion: Calls back with the found tweets.
     */
    func lookUpInDatabaseForTimeline(of userId: String, completion: @escaping ([MyTwitterDrop.Tweet]) -> Void) {
        
        container?.performBackgroundTask { context in
            
            if let timelineTweets = try? Tweet.findTweets(matchingTimelineUserId: userId, in: context){
                
                let newTweets = TwitterUtility.mapTweets(from: timelineTweets)
                
                if !newTweets.isEmpty {
                    
                    completion(newTweets)
                    
                    return
                }
            }
            completion([])
        }
    }
}

// MARK: - Private utility methods
extension DBHelper {
    
    /**
     Returns the profile image of a Twitter user.
     
     - Parameter twitterUser: A fetched Twitter user from the database.
     
     - Returns: The profile image from the Twitter user.
     */
    private func getImage(from twitterUser: TwitterUser) -> UIImage? {
      
     //   "1224987056847368193"
        if let imageData = twitterUser.profileImage, let image = UIImage(data: imageData) {
            
            return image
        }
        return nil
    }
    
    /**
     Returns the profile image of a Twitter user from the database.
     
     - Parameter twitterUser: A Twitter user from a Twitter request.
     - Parameter context: The context of the database.
     
     - Returns: The profile image from the Twitter user.
     */
    private func checkForImage(from twitterUser: MyTwitterDrop.User, in context: NSManagedObjectContext) -> UIImage? {
     
        if twitterUser.identifier == Authentication.loggedInUserId && twitterUser != TwitterUtility.unverifiedUser {
           
            if let user = try? TwitterUser.findOrCreateTwitterUser(matching: twitterUser, in: context), let image = getImage(from: user) {
                
                return image
            }
            try? context.save()
            
        } else {
           
            if let user = try? TwitterUser.findTwitterUser(matchingUserId: twitterUser.identifier, in: context), let image = getImage(from: user) {
              
                return image
            }
        }
        
        return nil
    }
}
