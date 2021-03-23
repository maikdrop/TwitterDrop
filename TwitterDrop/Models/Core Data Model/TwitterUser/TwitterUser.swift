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

public class TwitterUser: NSManagedObject {
    
    static func findOrCreateTwitterUser(matching twitterInfo: MyTwitterDrop.User, in context: NSManagedObjectContext) throws -> TwitterUser {
        
        let request: NSFetchRequest<TwitterUser> = TwitterUser.fetchRequest()
        request.predicate = NSPredicate(format: "handle = %@", twitterInfo.screenName)
        
        do {
            let matches = try context.fetch(request)
            if matches.count > 0 {
                assert(matches.count == 1, "TwitterUser.findOrCreateTwitterUser -- database inconsistency!")
                return matches[0]
            }
        } catch {
            throw error
        }
        
        let twitterUser = TwitterUser(context: context)
        twitterUser.handle = twitterInfo.screenName
        twitterUser.name = twitterInfo.name
        twitterUser.unique = twitterInfo.identifier
        twitterUser.verified = twitterInfo.verified
        twitterUser.profileImageUrl = twitterInfo.profileImageURL.string
        return twitterUser
    }
    
    static func findTwitterUser(userID: String, in context: NSManagedObjectContext) throws -> TwitterUser? {
        
        let request: NSFetchRequest<TwitterUser> = TwitterUser.fetchRequest()
        request.predicate = NSPredicate(format: "unique = %@", userID)
        
        do {
            let matches = try context.fetch(request)
            if matches.count > 0 {
                assert(matches.count == 1, "TwitterUser.findTwitterUser -- database inconsistency!")
                return matches[0]
            }
        } catch {
            throw error
        }
        return nil
    }
    
    static func updateTwitterUser(userID: String, with image: UIImage, context: NSManagedObjectContext) throws -> TwitterUser? {
        
        let request: NSFetchRequest<TwitterUser> = TwitterUser.fetchRequest()
        request.predicate = NSPredicate(format: "unique = %@", userID)
        
        do {
            let matches = try context.fetch(request)
            if matches.count > 0 {
                assert(matches.count == 1, "TwitterUser.updateTwitterUser -- database inconsistency!")
                if matches[0].profileImage != image.pngData() {
                    matches[0].profileImage = image.pngData()
                }
                return matches[0]
            }
        } catch {
            throw error
        }
        return nil
    }
    

}
