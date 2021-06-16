/*
 MIT License

Copyright (c) 2021 Maik Müller (maikdrop) <maik_mueller@me.com>

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

import Foundation
import UIKit

// MARK: - Search results updating protocol
extension TweetersTableViewController: UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {
        
        var filtered = [TwitterUser]()
        
        let strippedString = searchController.searchBar.text!.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        searchController.showsSearchResultsController = !strippedString.isEmpty
        
        if !strippedString.isEmpty {
            
            tweeters.forEach { (_, value) in
                
                filtered += value.filter { tweeter in
                    
                    tweeterIsIncluded(in: strippedString, tweeter: tweeter)
                }
            }
            
            if let resultsController = searchController.searchResultsController as? TweeterSearchResultsTableViewController {
                
                resultsController.filteredTweeters = filtered
                resultsController.mention = mention
                resultsController.tableView.reloadData()
            }
        }
    }
    
    private func tweeterIsIncluded(in searchText: String, tweeter: TwitterUser) -> Bool {
        
        if let handle = tweeter.handle?.lowercased(), let name = tweeter.name?.lowercased() {
            
            if searchText.count <= handle.count, handle[searchText.count] == searchText {
                
                    return true
            }
            
            if searchText.count <= name.count {
                
                return name[searchText.count] == searchText
            }
        }
        return false
    }
}
