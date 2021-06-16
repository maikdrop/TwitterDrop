/*
 MIT License

Copyright (c) 2021 Maik Müller (maikdrop) <maik_mueller@me.com>

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 
 Abstract:
 The class shows a list of a tweeters tweets.
 */

import UIKit
import CoreData
import MyTwitterDrop

class TweetersTweetsTableViewController: FetchedResultsTableViewController {
    
    // MARK: - Properties
    var mention: String? { didSet { updateUI() } }
    var tweeter: TwitterUser? { didSet { updateUI() } }
    var container: NSPersistentContainer? = AppDelegate.persistentContainer { didSet { updateUI() } }
    private var profileImageDownloadPending = false
    private var fetchedResultsController: NSFetchedResultsController<Tweet>?
    
    private var sortDescriptor: NSSortDescriptor {
       
        NSSortDescriptor(
            key: AppStrings.Tweet.sortDescriptorKey,
            ascending: false)
    }
    
    private var predicate: NSPredicate? {
        
        if mention != nil, tweeter != nil {
            
            return NSPredicate(format: AppStrings.Tweeter.textPredicate, mention!, tweeter!)
        }
        return nil
    }
    
    deinit { print("DEINIT - TweetersTweetsTableViewController") }
}

// MARK: - Default view controller methods
extension TweetersTweetsTableViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView = UITableView.tweets
    }
}

// MARK: - Table view data source and delegate methods
extension TweetersTweetsTableViewController {
    
    // Data Source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultsController?.sections?.count ?? 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let sections = fetchedResultsController?.sections, sections.count > 0 {
            return sections[section].numberOfObjects
        } else {
            return 0
        }
    }
    
    // Delegate
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: AppStrings.TweetCell.identifier, for: indexPath)
        if let tweet = fetchedResultsController?.object(at: indexPath), let tweetCell = cell as? TweetTableViewCell {
            tweetCell.tweet = TwitterUtility.mapTweet(from: tweet)
        }
        return cell
    }
}

// MARK: - Private utility methods
private extension TweetersTweetsTableViewController {
    
    private func updateUI() {
        
        if let context = container?.viewContext, mention != nil, tweeter != nil {
            
            let request: NSFetchRequest<Tweet> = Tweet.fetchRequest()
            request.sortDescriptors = [sortDescriptor]
            request.predicate = predicate
            
            fetchedResultsController = configureFetchedResultsController(for: request, in: context)
            fetchedResultsController?.delegate = self
            
            try? fetchedResultsController?.performFetch()
            
            tableView.reloadData()
        }
    }
}

// MARK: - Private configuration methods
private extension TweetersTweetsTableViewController {
    
    /**
     Configures a fetched results controller for a database fetch.
     
     - Parameter request: The request to fetch tweets.
     - Parameter context: The context of the database.
     
     - Returns: The configured fetched results controller that fetches tweets from the database.
     */
    private func configureFetchedResultsController(for request: NSFetchRequest<Tweet>, in context: NSManagedObjectContext) -> NSFetchedResultsController<Tweet> {
        
        NSFetchedResultsController<Tweet>(
            fetchRequest: request,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil)
    }
}
