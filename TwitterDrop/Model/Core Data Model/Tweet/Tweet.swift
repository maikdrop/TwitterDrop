/*
 MIT License

Copyright (c) 2021 Maik Müller (maikdrop) <maik_mueller@me.com>

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 
 Abstract:
 The class offers functions in order to interact with the Tweet entity of the database.
 */

import UIKit
import CoreData
import MyTwitterDrop

public class Tweet: NSManagedObject {

    /**
     Finds or creates a tweet in the database.
     
     - Parameter tweet: A tweet from Twitter.
     - Parameter context: The context of the database.
     
     - Returns: The created or found tweet in the database that matches the given tweet from Twitter.
     */
    static func findOrCreateTweet(matching tweet: MyTwitterDrop.Tweet, in context: NSManagedObjectContext) throws -> Tweet {

        let request: NSFetchRequest<Tweet> = Tweet.fetchRequest()
        request.predicate =
            NSPredicate(format: AppStrings.Tweet.uniquePredicateFormat, tweet.identifier)
        
        do {
            let matches = try context.fetch(request)
            
            if matches.count > 0 {
                
                assert(matches.count == 1, "Tweet.findOrCreateTweet -- database inconsistency!")
                
                return matches[0]
            }
        } catch {
            throw error
        }
      
        let tweetForDB = Tweet(context: context)
        tweetForDB.unique = tweet.identifier
        let words = tweet.text.words
        if let retweet = tweet.retweet, words.count > 1 {
            tweetForDB.text = words[0] + " " + words[1] + " " + retweet.text
        } else {
            tweetForDB.text = tweet.text
        }
        tweetForDB.created = tweet.created
        tweetForDB.hashtags = NSSet(array: Hashtag.createHashtag(matching: tweet, in: context))
        tweetForDB.urls = NSSet(array: Url.createUrl(matching: tweet, in: context))
        tweetForDB.userMentions = NSSet(array: UserMention.createUserMention(matching: tweet, in: context))
        tweetForDB.tweeter = try? TwitterUser.findOrCreateTwitterUser(matching: tweet.user, in: context)
        return tweetForDB
    }
    
    /**
     Find tweets in the database.
     
     - Parameter mention: The mention in the tweet.
     - Parameter context: The context of the database.
     
     - Returns: The tweets that have the mention in their texts.
     */
    static func findTweets(matchingMention mention: String, in context: NSManagedObjectContext) throws -> [Tweet]? {
        
        let request: NSFetchRequest<Tweet> = Tweet.fetchRequest()
        request.sortDescriptors =
            [NSSortDescriptor(key: AppStrings.Tweet.sortDescriptorKey, ascending: false)]
        request.predicate = NSPredicate(format: AppStrings.Tweet.textPredicate, mention)

        do {
            let matches = try context.fetch(request)
            if !matches.isEmpty {
                return matches
            }
        } catch {
            throw error
        }
        return nil
    }
    
    /**
     Find tweets in the database.
     
     - Parameter timelineUserId: The user id of the timeline owner.
     - Parameter context: The context of the database.
     
     - Returns: The tweets belonging to the timeline of the Twitter user.
     */
    static func findTweets(matchingTimelineUserId id: String, in context: NSManagedObjectContext) throws -> [Tweet]? {
        
        let request: NSFetchRequest<Tweet> = Tweet.fetchRequest()
        request.sortDescriptors =
            [NSSortDescriptor(key: AppStrings.Tweet.sortDescriptorKey, ascending: false)]
        request.predicate = NSPredicate(format: AppStrings.Tweet.timelinePredicate, id)
        
        do {
            let matches = try context.fetch(request)
            if !matches.isEmpty {
                return matches
            }
        } catch {
            throw error
        }
        return nil
    }
    
    /**
     Returns the count of tweets from a tweeter.
     
     - Parameter mention: The mention in the tweet.
     - Parameter twitterUser: The tweeter of the tweets.
     - Parameter context: The context of the database.
     
     - Returns: The count of tweets by a tweeter containing the given mention in their texts.
     */
    static func tweetCount(with mention: String, by twitterUser: TwitterUser, in context: NSManagedObjectContext) throws -> Int? {
        
        let request: NSFetchRequest<Tweet> = Tweet.fetchRequest()
        request.predicate = NSPredicate(format: AppStrings.Tweeter.textPredicate, mention, twitterUser)
        
        do {
            
            return try context.count(for: request)
            
        } catch {
            throw error
        }
    }
}
