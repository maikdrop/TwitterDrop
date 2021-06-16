/*
 MIT License

Copyright (c) 2021 Maik Müller (maikdrop) <maik_mueller@me.com>

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 
 Abstract:
 Source: www.swiftbysundell.com/articles/lightweight-presenters-in-swift/
 */

import UIKit
import MyTwitterDrop
import OAuthSwift

struct TweetSearchNaviPresenter {
    
    typealias Twitter = AppStrings.Timeline
    
    /**
     Presents a list of searched tweets.
     
     - Parameter oauthSwift: The authentication object with user credentials for a Twitter request.
     - Parameter viewController: The presenting view controller.
     */
    func presentTweets(oauthSwift: OAuth1Swift, in viewController: UIViewController?) {

        let tweetTVC = OfflineTweetSearchTVC(oauthSwift: oauthSwift)
        tweetTVC.navigationItem.largeTitleDisplayMode = .never

        let navigationController = UINavigationController(rootViewController: tweetTVC)

        tweetTVC.navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: navigationController,
            action: #selector(UIViewController.dismissWithAnimation)
        )
        
        navigationController.modalPresentationStyle = .fullScreen
        navigationController.modalTransitionStyle = .coverVertical
       
        viewController?.present(navigationController, animated: true)
    }
}
