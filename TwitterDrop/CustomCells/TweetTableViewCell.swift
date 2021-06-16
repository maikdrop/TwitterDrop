/*
 MIT License

Copyright (c) 2021 Maik Müller (maikdrop) <maik_mueller@me.com>

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 
 Abstract:
 Custom cell to display tweets in a table view. -> based on source: Stanford - Developing iOS 10 Apps with Swift - 9. Table View: https://www.youtube.com/watch?v=78LWmmDxr4k
 */

import UIKit
import MyTwitterDrop

class TweetTableViewCell: UITableViewCell {

    // MARK: - Properties
    @IBOutlet weak var tweetProfileImageView: UIImageView!
    @IBOutlet private weak var tweetCreatedLbl: UILabel!
    @IBOutlet private weak var tweetUserLbl: UILabel!
    @IBOutlet private weak var tweetTextLbl: UILabel!
    
    static let identifier = AppStrings.TweetCell.identifier

    static var nib: UINib { UINib(nibName: String(describing: self), bundle: nil) }
        
    var tweet: MyTwitterDrop.Tweet? {
        didSet {
            updateUI()
        }
    }
    
    /**
     Updates the UI of the cell in order to display the conetent of the tweet.
     */
    private func updateUI() {
        
        tweetUserLbl?.text = tweet?.user.description
       
        if let retweet = tweet?.retweet, let words = tweet?.text.words, words.count > 1 {
            tweetTextLbl?.text = words[0] + " " + words[1] + " " + retweet.text
        } else {
            tweetTextLbl?.text = tweet?.text
        }
    
        if let userId = tweet?.user.identifier, let profileImage = TwitterUtility.cache.value(forKey: userId) {
            tweetProfileImageView?.image = profileImage
        }
        
        if let creationDate = tweet?.created {
            tweetCreatedLbl?.text = formatDate(creationDate, with: Self.dateFormat)
        } else {
            tweetCreatedLbl?.text = nil
        }
    }
}

// MARK: - Constants
extension TweetTableViewCell {
    
    static var estimatedImageHeight: CGFloat { 100.0 }
    private static var dateFormat: String { "dd.MM.yyyy HH:mm:ss" }
}
