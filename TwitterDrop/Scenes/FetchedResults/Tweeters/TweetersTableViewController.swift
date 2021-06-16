/*
 MIT License

Copyright (c) 2021 Maik Müller (maikdrop) <maik_mueller@me.com>

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 
 Abstract:
 The class shows a list of tweeters in alphabetical order according to a search term, which is inlcuded in a tweet of the tweeter. The sections of the table view reflecting the first letter of the tweeters in alphabetical order, too. So, each section contains only tweeters with the the same first letter.
 */

import UIKit
import CoreData

class TweetersTableViewController: UITableViewController {
    
    // MARK: - Properties
    var mention: String? { didSet { updateUI() } }
    var container: NSPersistentContainer? = AppDelegate.persistentContainer { didSet {  updateUI() } }

    private let loadingVC = LoadingViewController()
    
    private(set) var tweeters = Dictionary<String, Array<TwitterUser>>()
    private var tweeterSection = Array<String>()
    
    private var fetchedResultsController: NSFetchedResultsController<TwitterUser>?
    private var tweeterSearchResults: TweeterSearchResultsTableViewController!
    private(set) var searchController: UISearchController!
    
    private var sortDescriptor: NSSortDescriptor {
       
        NSSortDescriptor(key: AppStrings.TweetSearch.sortDescriptorKey,
                         ascending: true,
                         selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))
    }
    
    private var predicate: NSPredicate? {
        
        if mention != nil {
            
            return NSPredicate(format: AppStrings.Tweet.textPredicate, mention!)
        }
        return nil
    }
    
    deinit { print("DEINIT - TweetersTableViewController") }
}

// MARK: - Default view controller methods
extension TweetersTableViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(TweeterTableViewCell.nib, forCellReuseIdentifier: TweeterTableViewCell.identifier)
        
        tweeterSearchResults = TweeterSearchResultsTableViewController()
        tweeterSearchResults.suggestedTweeterDelegate = self
        
        configureSearchController()
        configureNavigationItems()
        
        updateUI()
    }
}

// MARK: - Table view data source and delegate methods
extension TweetersTableViewController {
    
    // Data Source
    override func numberOfSections(in tableView: UITableView) -> Int {
      
        return tweeterSection.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        tweeters[tweeterSection[section]]?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: TweeterTableViewCell.identifier, for: indexPath)
        
        let firstLetter = tweeterSection[indexPath.section]
        
        if let tweeter = tweeters[firstLetter]?[indexPath.row], let tweeterCell = cell as? TweeterTableViewCell {
            
            tweeterCell.tweeter = tweeter
            
            if mention != nil, let context = container?.viewContext, let tweetCount = try? Tweet.tweetCount(with: mention!, by: tweeter, in: context) {
                
                tweeterCell.tweetCount = tweetCount
            }
        }
        return cell
    }
    
    // Delegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        let section = tweeterSection[indexPath.section]
        
        if let tweeter = tweeters[section]?[indexPath.row] {
            
           didSelectTweeter(tweeter)
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {

        tweeterSection[section]
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        if tableView.isDragging {
            
            didScrollThroughTweeters()
        }
    }
}

// MARK: - Private utility methods
private extension TweetersTableViewController {
    
    /**
    Fetches data from the database.
     */
    private func fetchData() {
        
        if let context = container?.viewContext, mention != nil {
            
            let request: NSFetchRequest<TwitterUser> = TwitterUser.fetchRequest()
            request.sortDescriptors = [sortDescriptor]
            request.predicate = predicate
            
            fetchedResultsController = configureFetchedResultsController(for: request, in: context)
            
            try? fetchedResultsController?.performFetch()
        }
    }
    
    /**
    Setups the data source of the table view.
     */
    private func setupDataSource() {
        
        self.tweeters.removeAll()
        
        if self.mention != nil {
            
            if var tweeters = self.fetchedResultsController?.fetchedObjects {
                
                for tweeter in tweeters {
                    
                    if let sectionLetter = tweeter.handle?.first?.uppercased() {
                        
                        if self.tweeters[sectionLetter] == nil {
                            
                            self.sort(tweeters: &tweeters, for: sectionLetter)
                        }
                    }
                }
                self.tweeterSection = self.tweeters.keys.sorted(by: <)
            }
        }
    }
    
    /**
    Sorts the tweeters in alphabetical order.
     
     - Parameter tweeters: The tweeters which will be sorted.
     - Parameter sectionLetter: The section letter matches the first letter of the tweeter.
     */
    private func sort(tweeters: inout [TwitterUser], for sectionLetter: String) {

        for (index, tweeter) in tweeters.enumerated().reversed() {
                   
            if let tweeterFirstLetter = tweeter.handle?.first {
                
                if String(tweeterFirstLetter).caseInsensitiveCompare(sectionLetter) == .orderedSame {
                    
                    let letter = sectionLetter.first!.isLetter ? sectionLetter : "#"
                    
                    self.tweeters[letter, default: []].append(tweeter)
                  
                    tweeters.remove(at: index)
                }
            }
        }
    }
    
    private func updateUI() {
        
        if isViewLoaded {
            
            add(loadingVC)
            
            DispatchQueue.global(qos: .userInteractive).async {
                
                self.fetchData()
                self.setupDataSource()
                
                DispatchQueue.main.async {
                    
                    let sectionsToInsert = IndexSet( Array(0..<self.tweeterSection.count) )
                    
                    self.tableView.insertSections(sectionsToInsert, with: .top)
                    
                    self.loadingVC.remove()
                }
            }
        }
    }
}

// MARK: - Private configuration methods
private extension TweetersTableViewController {
    
    /**
     Configures the search controller for filtering tweets.
     */
    private func configureSearchController() {
        
        searchController = UISearchController(searchResultsController: tweeterSearchResults)
        searchController.searchResultsUpdater = self
        searchController.searchBar.delegate = self
        searchController.searchBar.placeholder = AppStrings.Tweeter.placeholder
        searchController.obscuresBackgroundDuringPresentation = false
    }
    
    /**
     Configures the navigation item: searchController and the search bar behavior while the table view is scrolled.
     */
    private func configureNavigationItems() {
        
        navigationItem.searchController = self.searchController
        navigationItem.hidesSearchBarWhenScrolling = false
    }
    
    /**
     Configures a fetched results controller for a database fetch.
     
     - Parameter request: The request that fetches Twitter users.
     - Parameter context: The context of the database.
     
     - Returns: The configured fetched results controller that fetches Twitter users from the database.
     */
    private func configureFetchedResultsController(for request: NSFetchRequest<TwitterUser>, in context: NSManagedObjectContext) -> NSFetchedResultsController<TwitterUser> {

        NSFetchedResultsController<TwitterUser>(
            fetchRequest: request,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil)
    }
}
