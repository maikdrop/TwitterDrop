/*
 MIT License

Copyright (c) 2021 Maik Müller (maikdrop) <maik_mueller@me.com>

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 
 Abstract:
 The class offers functions in order to interact with the Timeline entity of the database.
 */

import UIKit
import CoreData
import MyTwitterDrop

public class Timeline: NSManagedObject {

    /**
     Finds or creates a timeline for a Twitter user in the database with the belonging tweet and tweeter.
     
     - Parameter userId: The user id of the Twitter user.
     - Parameter tweet: The tweet which will be added to the timeline of the Twitter user.
     - Parameter context: The context of the database.
     
     - Returns: The timeline of the Twitter user with all belonging tweets.
     */
    static func findOrCreateTimeline(matching userId: String, tweet: MyTwitterDrop.Tweet, in context: NSManagedObjectContext) throws -> Timeline {
        
        let request: NSFetchRequest<Timeline> = Timeline.fetchRequest()
        request.predicate =
            NSPredicate(format: AppStrings.Timeline.userIdPredicateFormat, userId)
        
        do {
            let matches = try context.fetch(request)
            
            if matches.count > 0 {
                
                assert(matches.count == 1, "Timeline.findOrCreateTimeline -- database inconsistency!")
                
                if let tweet = try? Tweet.findOrCreateTweet(matching: tweet, in: context) {
                    
                    matches[0].addToTweets(tweet)
                }
                return matches[0]
            }
        } catch {
            throw error
        }
        
        let timeline = Timeline(context: context)
        timeline.userId = userId
        
        if let tweet = try? Tweet.findOrCreateTweet(matching: tweet, in: context) {
            
            timeline.tweets = NSSet(object: tweet)
        }
        return timeline
    }
}
