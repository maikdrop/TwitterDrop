/*
 MIT License

Copyright (c) 2021 Maik Müller (maikdrop) <maik_mueller@me.com>

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 
 Abstract:
 The class offers functions in order to interact with the Hashtag entity of the database.
 */

import UIKit
import CoreData
import MyTwitterDrop

public class Hashtag: NSManagedObject {
    
    /**
     Creates hashtags.
     
     - Parameter tweet: A tweet from Twitter.
     - Parameter context: The context of the database.
     
     - Returns: The created hashtags.
     */
    static func createHashtag(matching tweet: MyTwitterDrop.Tweet, in context: NSManagedObjectContext) -> [Hashtag] {
        
        var hashtags = [Hashtag]()
       
        if let tweetHashtags = tweet.hashtags {
            for hashtag in tweetHashtags {
                let newHashtag = Hashtag(context: context)
                newHashtag.text = hashtag.text
                newHashtag.indices = hashtag.indices
                hashtags.append(newHashtag)
            }
        }
        return hashtags
    }
}
