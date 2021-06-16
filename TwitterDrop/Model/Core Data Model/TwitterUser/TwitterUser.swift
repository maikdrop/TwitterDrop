/*
 MIT License

Copyright (c) 2021 Maik Müller (maikdrop) <maik_mueller@me.com>

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 
 Abstract:
 The class offers functions in order to interact with the TwitterUser entity of the database.
 */

import UIKit
import CoreData
import MyTwitterDrop

public class TwitterUser: NSManagedObject {
    
    /**
     Finds or creates a Twitter user in the database.
     
     - Parameter twitterUser: A Twitter user from Twitter request.
     - Parameter context: The context of the database.
     
     - Returns: The created or found Twitter user in the database that matches the given Twitter user from Twitter.
     */
    static func findOrCreateTwitterUser(matching twitterUser: MyTwitterDrop.User, in context: NSManagedObjectContext) throws -> TwitterUser {
        
        let request: NSFetchRequest<TwitterUser> = TwitterUser.fetchRequest()
        request.predicate =
            NSPredicate(format: AppStrings.Tweeter.uniquePredicateFormat, twitterUser.identifier)
        
        do {
            let matches = try context.fetch(request)
            if matches.count > 0 {
                assert(matches.count == 1, "TwitterUser.findOrCreateTwitterUser -- database inconsistency!")
                return matches[0]
            }
        } catch {
            throw error
        }
        
        let twitterUserForDB = TwitterUser(context: context)
        twitterUserForDB.handle = twitterUser.screenName
        twitterUserForDB.name = twitterUser.name
        twitterUserForDB.unique = twitterUser.identifier
        twitterUserForDB.verified = twitterUser.verified
        twitterUserForDB.profileImageUrl = twitterUser.getProfileImage(sizeCategory: .original)?.string
        return twitterUserForDB
    }
    
    /**
     Finds a Twitter user in the database.
     
     - Parameter userId: The user id of the Twitter user.
     - Parameter context: The context of the database.
     
     - Returns: The Twitter user that matches the given user id.
     */
    static func findTwitterUser(matchingUserId userId: String, in context: NSManagedObjectContext) throws -> TwitterUser? {

        let request: NSFetchRequest<TwitterUser> = TwitterUser.fetchRequest()
        request.predicate =
            NSPredicate(format: AppStrings.Tweeter.uniquePredicateFormat, userId)
        
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

    /**
     Updates a Twitter user in the database.
     
     - Parameter twitterUser: A Twitter user from Twitter request.
     - Parameter profileImage: The new profile image of the Twitter user.
     - Parameter context: The context of the database.
     
     - Returns: The updated Twitter user.
     */
    static func updateTwitterUser(matching twitterUser: MyTwitterDrop.User, with profileImage: UIImage, in context: NSManagedObjectContext) throws -> TwitterUser? {
        
        let request: NSFetchRequest<TwitterUser> = TwitterUser.fetchRequest()
        request.predicate =
            NSPredicate(format: AppStrings.Tweeter.uniquePredicateFormat, twitterUser.identifier)
       
        do {
            let matches = try context.fetch(request)
            if matches.count > 0 {
                assert(matches.count == 1, "TwitterUser.updateTwitterUser -- database inconsistency!")
                matches[0].profileImage = profileImage.pngData()
                return matches[0]
            }
        } catch {
            throw error
        }
        return nil
    }
}
