/*
 MIT License

Copyright (c) 2021 Maik Müller (maikdrop) <maik_mueller@me.com>

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

import Foundation
import UIKit

extension UITableViewController {
    
    /**
     Updates all visible cells with the profile image of the tweeter according to the tweeter of the displayed tweet in these cells.
     */
    func updateVisibleCells() {
        
        if let visibleCells = self.tableView.visibleCells as? [TweetTableViewCell] {
            
            visibleCells.forEach { cell in
                
                if let id = cell.tweet?.user.identifier {
                    
                    cell.tweetProfileImageView.image = TwitterUtility.cache.value(forKey: id)
                }
            }
        }
    }
    
    /**
     Updates the last visible cell with the profile image according to the tweeter of the displayed tweet in this cell.
     */
    func updateLastVisibleCell() {
        
        if let visibleCells = self.tableView.visibleCells as? [TweetTableViewCell] {
            
            if let cell = visibleCells.last, let id = cell.tweet?.user.identifier, let image = TwitterUtility.cache.value(forKey: id) {
                
                if cell.tweetProfileImageView != image {
                    
                    cell.tweetProfileImageView.image = image
                }
            }
        }
    }
}
