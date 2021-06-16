/*
 MIT License

Copyright (c) 2021 Maik Müller (maikdrop) <maik_mueller@me.com>

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 
 Abtstract:
 The class shows the filtering results of tweeters.
 */

import UIKit
import CoreData

class TweeterSearchResultsTableViewController: UITableViewController {
    
    // MARK: - Properties
    var filteredTweeters = [TwitterUser]()
    var mention: String?
    var container: NSPersistentContainer? = AppDelegate.persistentContainer
    
    weak var suggestedTweeterDelegate: SuggestedTweeterDelegate?
}

// MARK: - Default view controller methods
extension TweeterSearchResultsTableViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
      
        tableView.register(TweeterTableViewCell.nib, forCellReuseIdentifier: TweeterTableViewCell.identifier)
    }
}

// MARK: - Table view data source and delegate methods
extension TweeterSearchResultsTableViewController {
    
    // Data Source
    override func numberOfSections(in tableView: UITableView) -> Int {
       
        1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        filteredTweeters.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: TweeterTableViewCell.identifier, for: indexPath)
        
        let tweeter = filteredTweeters[indexPath.row]
        
        if let tweeterCell = cell as? TweeterTableViewCell {
            
            tweeterCell.tweeter = tweeter
            
            if mention != nil, let context = container?.viewContext, let tweetCount = try? Tweet.tweetCount(with: mention!, by: tweeter, in: context) {
                
                tweeterCell.tweetCount = tweetCount
            }
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        guard let suggestedTweeterDelegate = suggestedTweeterDelegate else { return }
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        let selectedTweeter = filteredTweeters[indexPath.row]
        
        suggestedTweeterDelegate.didSelectTweeter(selectedTweeter)

    }
    
    // Delegate
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        if tableView.isDragging {
            
            suggestedTweeterDelegate?.didScrollThroughTweeters()
        }
    }
}
