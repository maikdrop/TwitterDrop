/*
 MIT License

Copyright (c) 2021 Maik Müller (maikdrop) <maik_mueller@me.com>

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

import UIKit
import CoreData
import MyTwitterDrop

public class Tweet: NSManagedObject {

    static func findOrCreateTweet(matching twitterInfo: MyTwitterDrop.Tweet, in context: NSManagedObjectContext) throws -> Tweet {
        
        let request: NSFetchRequest<Tweet> = Tweet.fetchRequest()
        request.predicate = NSPredicate(format: "unique = %@", twitterInfo.identifier)
        
        do {
            let matches = try context.fetch(request)
            if matches.count > 0 {
                assert(matches.count == 1, "Tweet.findOrCreateTweet -- database inconsistency!")
                return matches[0]
            }
        } catch {
            throw error
        }
        
        let tweet = Tweet(context: context)
        tweet.unique = twitterInfo.identifier
        tweet.text = twitterInfo.text
        tweet.created = twitterInfo.created
        tweet.hashtags = NSOrderedSet(array: Hashtag.createHashtag(matching: twitterInfo, in: context))
        tweet.urls = NSOrderedSet(array: Url.createUrl(matching: twitterInfo, in: context))
        tweet.userMentions = NSOrderedSet(array: UserMention.createUserMention(matching: twitterInfo, in: context))
        // TODO Error Handling
        tweet.tweeter = try? TwitterUser.findOrCreateTwitterUser(matching: twitterInfo.user, in: context)
        return tweet
    }
    
    static func findTweets(in context: NSManagedObjectContext) throws -> [Tweet]? {
        
        let request: NSFetchRequest<Tweet> = Tweet.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "created", ascending: false)]

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
}
