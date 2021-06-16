/*
 MIT License

Copyright (c) 2021 Maik Müller (maikdrop) <maik_mueller@me.com>

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 
 Abstract:
 Custom cell to display a Twitter user in a table view. -> based on source: Stanford - Developing iOS 10 Apps with Swift - 9. Table View: https://www.youtube.com/watch?v=78LWmmDxr4k
 */

import UIKit

class TweeterTableViewCell: UITableViewCell {
    
    static let identifier = AppStrings.TweeterCell.identifier
    static var nib: UINib { UINib(nibName: String(describing: self), bundle: nil) }
    
    @IBOutlet private weak var tweeterTitleLbl: UILabel!
    @IBOutlet private weak var tweeterTweetsCountLbl: UILabel!
    
    var tweetCount: Int = 0 {
        didSet {
            tweeterTweetsCountLbl.text = "\(tweetCount) Tweet\((tweetCount == 1) ? "" : "s")"
        }
    }
    
    var tweeter: TwitterUser? {
        didSet {
            updateUI()
        }
    }
    
    /**
     Updates the UI of the cell in order to display the conetent of the tweeter.
     */
    private func updateUI() {
        
        tweeterTitleLbl?.text = "@\(tweeter?.handle ?? "") (\(tweeter?.name ?? "")) \((tweeter?.verified ?? false) ? " ✅" : "")"
            
        if let id = tweeter?.unique {
            
            var profileImage = TwitterUtility.cache.value(forKey: id)
            
            if profileImage == nil, let imageData = tweeter?.profileImage, let image = UIImage(data: imageData) {
                
                TwitterUtility.cache.insert(image, forKey: id)
                
                profileImage = image
            }
            
            imageView?.image = profileImage?.resizeImage(for: imageSize)
        }
    }
}

// MARK: - Constants
extension TweeterTableViewCell {
    
    private var imageSize: CGSize { CGSize(width: 45, height: 45) }
}

