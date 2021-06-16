/*
 MIT License

Copyright (c) 2021 Maik Müller (maikdrop) <maik_mueller@me.com>

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

import Foundation

enum AppStrings {
    
    enum AppDelegate {
        static let containerName = "TwitterDrop"
        static let installKey = "alreadyInstalled"
    }
    
    enum Authorize {
        static let storyboardName = "Authorize"
        static let identifier = "AuthorizeVC"
        static let callBackURL = "mytwitter://oauth-callback/twitter"
    }
    
    enum Alert {
        static let logoutTitle = ""
        static let logoutBtn = "Logout"
        static let cancelBtn = "Cancel"
        static let retryBtn = "Retry"
        static let okBtn = "Ok"
        static let settingsBtn = "Settings"
        static let authorizeFailedTitle = "Authorization failed"
        static let authorizeFailedMsg = "Do you want to try it again?"
    }
    
    enum Network {
        static let loadingTweets = "Loading Tweets..."
    }
    
    enum SystemImages {
        static let magnifyingGlass = "magnifyingglass"
    }
    
    enum Timeline {
        static let title = "Timeline"
        static let storyboardName = "Twitter"
        static let tweetTimelineIdentifier = "TweetTimelineTVC"
        static let noConnection = "No Internet Connection"
        static let alertTitle = "Attention"
        static let logoutAlertMsg = "Are you sure you want to logout?"
        static let logoutErrorAlertMsg = "Error occured while logout."
        static let sectionTitleOlderTweets = "Older Tweets"
        static let sectionTitleLatestTweets = "Latest Tweets"
        
        static let userIdPredicateFormat = "userId = %@"
    }
    
    enum Tweeter {
        static let title = "Tweeters"
        static let placeholder = "Search Tweeters"
        static let textPredicate = "text contains[c] %@ and tweeter = %@"
        static let firstLetterPredicate = "text contains[c] %@ and tweeter beginswith %@"
        static let uniquePredicateFormat = "unique = %@"
    }
    
    enum Tweet {
        static let textPredicate = "any tweets.text contains[c] %@"
        static let timelinePredicate = "any timeline.userId = %@"
        static let sortDescriptorKey = "created"
        static let uniquePredicateFormat = "unique = %@"
    }

    enum TweetCell {
        static let identifier = "TweetTableViewCell"
        static let sectionTitleOld = "Old Tweets"
        static let sectionTitleRecent = "Recent Tweets"
    }
    
    enum TweeterCell {
        static let identifier = "TweeterTableViewCell"
    }
    
    enum TweetSearch {
        static let title = "Tweets"
        static let placeholder = "Search Tweets"
        static let tweeterBtnTitle = "Tweeter"
        static let sortDescriptorKey = "handle"
        static let noConnectionAlertTitle = "Turn Off Airplane Mode or Use Wi-Fi to Access Data"
    }
}
