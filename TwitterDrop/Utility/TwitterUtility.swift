/*
 MIT License

Copyright (c) 2021 Maik Müller (maikdrop) <maik_mueller@me.com>

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 
 Abstract:
 The struct offers utility properties and functions.
 */

import Foundation
import UIKit
import MyTwitterDrop

struct TwitterUtility {
    
    // MARK: - Properties
    static let defaultProfileImage: UIImage? = {
        
        if let image = UIImage(systemName: personImage) {
            
            return image.withTintColor(.label)
        }
        return nil
    }()
    
    static let cache = Cache<String, UIImage>()
    
    // can be used when user verification is not possible for example the network is offline
    static let unverifiedUser = User(screenName: "", name: "", id: Authentication.loggedInUserId ?? "", verified: false, profileImageURL: "")
    
    /**
     Fetches the profile image of a Twitter user.
     
     - Parameter twitterUser: The Twitter user that the profile image belongs to.
     - Parameter completion: Calls back with the id and profile image of the Twitter user after the request is completed.
     */
    static func getProfileImage(from twitterUser: MyTwitterDrop.User, completion: @escaping ((twitterUser: MyTwitterDrop.User, image: UIImage)) -> Void) {
        
        if let url = twitterUser.getProfileImage(sizeCategory: .original) {
            
            Network.shared.fetchData(from: url) { imageData in
                
                if let imgData = imageData, let image = UIImage(data: imgData) {
                    
                    completion((twitterUser: twitterUser, image: image))
                }
            }
        }
    }
    
    /**
     Checks if the url of a Twitter users profile image is accessible. If not, the profile image will be fetched from the internet.
     
     - Parameter twitterUser: The Twitter user who has a profile image in the database.
     */
    static func checkForNewProfileImage(of twitterUser: MyTwitterDrop.User, completion: @escaping (Bool) -> Void) {
        
        if let url = URL(string: twitterUser.profileImageUrl) {
            
            Network.shared.ping(url: url) { isAcessible in
                
                if !isAcessible {
                    
                    completion(isAcessible)
                }
            }
        }
    }
    
    /**
     Maps database tweets into MyTwitterDrop tweets.
     
     - Parameter dbTweets: Tweets that are fetched from the database.
     
     - Returns: The mapped tweets.
     */
    static func mapTweets(from dbTweets: [Tweet]) -> [MyTwitterDrop.Tweet] {
        var tweets = [MyTwitterDrop.Tweet]()
        for dbTweet in dbTweets {
            if let twitterUser = dbTweet.tweeter, let text = dbTweet.text, let created = dbTweet.created, let unique = dbTweet.unique {
                let screenName = twitterUser.handle ?? ""
                let name = twitterUser.name ?? ""
                let id = twitterUser.unique ?? ""
                let profileImageUrl = twitterUser.profileImageUrl ?? ""
                let user = MyTwitterDrop.User(screenName: screenName, name: name, id: id, verified: twitterUser.verified, profileImageURL: profileImageUrl)
                let tweet = MyTwitterDrop.Tweet(text: text, user: user, created: created, identifier: unique)
                tweets.append(tweet)
            }
        }
        return tweets
    }
    
    /**
     Maps database tweet into MyTwitterDrop tweet.
     
     - Parameter dbTweet: Tweet that is fetched from the database.
     
     - Returns: The mapped tweet.
     */
    static func mapTweet(from dbTweet: Tweet) -> MyTwitterDrop.Tweet? {
        if let twitterUser = dbTweet.tweeter, let text = dbTweet.text, let created = dbTweet.created, let unique = dbTweet.unique {
            let screenName = twitterUser.handle ?? ""
            let name = twitterUser.name ?? ""
            let id = twitterUser.unique ?? ""
            let profileImageUrl = twitterUser.profileImageUrl ?? ""
            let user = MyTwitterDrop.User(screenName: screenName, name: name, id: id, verified: twitterUser.verified, profileImageURL: profileImageUrl)
            return MyTwitterDrop.Tweet(text: text, user: user, created: created, identifier: unique)
        }
        return nil
    }
}

// MARK: - Constants
private extension TwitterUtility {
    
    private static var personImage = "person.circle"
}
