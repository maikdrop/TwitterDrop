/*
 MIT License

Copyright (c) 2021 Maik Müller (maikdrop) <maik_mueller@me.com>

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 
 Abstract:
 The class offers the possibility to look for tweets from Twitter.
 */

import UIKit
import MyTwitterDrop
import OAuthSwift

class TweetSearchTableViewController: UITableViewController, HandleTweets {
    
    // MARK: - Properties
    private let loadingVC = LoadingViewController()
    private(set) var tweets = [Array<MyTwitterDrop.Tweet>]()
    private let oauthSwift: OAuth1Swift
    private var lastTwitterRequest: MyTwitterDrop.Request?
    private lazy var activityIndicator = configureActivityIndicator()
    
    private(set) var searchBar = UISearchBar.search
    
    var searchText: String? {
        didSet {
            tweets.removeAll()
            tableView.reloadData()
            if !searchBar.isFirstResponder {
                if let request = twitterRequest() {
                    fetchTweets(for: request)
                }
            }
        }
    }
    
    // MARK: - Create a tweet timeline
    init(oauthSwift: OAuth1Swift) {
        self.oauthSwift = oauthSwift
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit { print("DEINIT - TweetSearchTableViewController") }
    
    // MARK: - API in order to subclass functionality for tweets and profile images
    
    /**
     Fetches tweets from Twitter via network request and inserts them in the data source.
     
     - Parameter request: The tweets request.
     */
    func fetchTweets(for request: MyTwitterDrop.Request) {
        
        if tweets.isEmpty { add(loadingVC) }
        
        lastTwitterRequest = request
        
        request.fetchTweets() { [weak self] newTweets in
            
            if request == self?.lastTwitterRequest {
                
                if newTweets.isEmpty {
                    
                    self?.removeActivityIndicator()
                    
                } else {
                    
                    let tweeters = Set(newTweets.map { $0.user })
                    
                    self?.insertTweets(newTweets)
                    
                    self?.getProfileImage(for: tweeters)
                }
            }
        }
    }
    
    /**
     Inserts tweets into data source and updates the UI.
     
     - Parameter tweets: Tweets to insert.
     */
    func insertTweets(_ newTweets: [MyTwitterDrop.Tweet]) {
       
        if !newTweets.isEmpty {
            
            tweets.append(newTweets)
            
            let sectionToInsert = tweets.count - 1
            
            let animation = sectionToInsert > 0 ? UITableView.RowAnimation.none : UITableView.RowAnimation.fade
            
            DispatchQueue.main.async {
                
                self.navigationItem.rightBarButtonItem?.isEnabled = true
                
                self.removeActivityIndicator()
                
                self.tableView.insertSections([sectionToInsert], with: animation)
            }
        }
    }
    
    /**
     Fetches the profile image of Twitter users via network request.
     
     - Parameter twitterUsers: The Twitter users from a Twitter request.
     */
    func getProfileImage(for tweeters: Set<MyTwitterDrop.User>) {
        
        tweeters.forEach { tweeter in
            
            TwitterUtility.getProfileImage(from: tweeter) { [weak self] data in
                
                self?.updateProfileImage(data.image, for: data.twitterUser)
            }
        }
    }
    
    /**
     Updates the profile image of a Twitter user in the UI.
     
     - Parameter image: The profile image of the Twitter user.
     - Parameter twitterUserId: The user id of the Twitter user.
     */
    func updateProfileImage(_ image: UIImage, for twitterUser: MyTwitterDrop.User) {
      
        TwitterUtility.cache.insert(image, forKey: twitterUser.identifier)
        
        DispatchQueue.main.async {
            
            if self.tweets.count > 1 {
                
                self.updateLastVisibleCell()
                
            } else {
                
                self.updateVisibleCells()
            }
        }
    }
}

// MARK: - Default view controller methods
extension TweetSearchTableViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView = UITableView.tweets
        
        configureTweeterBtn()
        configureSearchBar()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        tableView.tableHeaderView = searchBar
        navigationItem.title = AppStrings.TweetSearch.title
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if tableView.tableFooterView == nil {
            
            tableView.tableFooterView = configureFooterView()
        }
    }
}

// MARK: - Table View
extension TweetSearchTableViewController {
    
    // Data Source
    override func numberOfSections(in tableView: UITableView) -> Int {
        
        tweets.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        tweets[section].count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: AppStrings.TweetCell.identifier, for: indexPath)
        
        let tweet: MyTwitterDrop.Tweet = tweets[indexPath.section][indexPath.row]
        
        if let tweetCell = cell as? TweetTableViewCell {
            tweetCell.tweet = tweet
        }
        
        return cell
    }
    
    // Delegate
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        if !tweets.isEmpty, tableViewIsMovingByUser {
            
            searchBar.endEditing(true)
            
            if shouldReload, !activityIndicator.isAnimating {
                
                activityIndicator.startAnimating()
                
                if Network.shared.isConnected {
                    
                    if let request = lastTwitterRequest?.older {
                        
                        fetchTweets(for: request)
                    }
                    
                } else {
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {

                        self.removeActivityIndicator()
                        self.tableView.scrollToRow(at: self.tableView.indexPathsForVisibleRows!.last!, at: .bottom, animated: true)
                    }
                    
                    infoAlertWithLinkToSettings(title: AppStrings.TweetSearch.noConnectionAlertTitle, message: "")
                }
            }
        }
    }
}

// MARK: - Private target methods
private extension TweetSearchTableViewController {
    
    /**
    Shows all tweeters from tweets.
     
     - Parameter request: The tweets request.
     */
    @objc private func showTweeters() {
        
        searchBar.endEditing(true)
        
        TweeterNaviPresenter().presentTweeter(from: searchText ?? "", in: self)
    }
}

// MARK: - Private utility methods for tweet fetching
private extension TweetSearchTableViewController {
    
    /**
     Returns a Twitter request.
     
     - Returns: The Twitter request, which is used to fetch the tweets that the user is looking for.
     */
    private func twitterRequest() -> MyTwitterDrop.Request? {
        
        if let query = searchText, !query.isEmpty {
           
            return MyTwitterDrop.Request(oauthSwift: oauthSwift, search: query, count: tweetCount)
        
        }
        return nil
    }
    
    /**
     Removes all activity indicators from the UI.
     */
    private func removeActivityIndicator() {
        
        self.loadingVC.remove()
        self.activityIndicator.stopAnimating()
    }
}


// MARK: - Private configuration methods for UI elements
private extension TweetSearchTableViewController {
    
    /**
     Configures the search bar.
     */
    private func configureSearchBar() {
        searchBar.delegate = self
        searchBar.placeholder = AppStrings.TweetSearch.placeholder
        searchBar.becomeFirstResponder()
    }
    
    /**
     Configures the tweeter button on the right side of the navigation bar.
     */
    private func configureTweeterBtn() {
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: AppStrings.TweetSearch.tweeterBtnTitle,
            style: .plain,
            target: self,
            action: #selector(showTweeters)
        )
        navigationItem.rightBarButtonItem?.isEnabled = false
    }
    
    /**
     Configures the activity indicator at the bottom of the table view.
     */
    private func configureActivityIndicator() -> UIActivityIndicatorView {
        let activityIndicator = UIActivityIndicatorView(style: .medium)
        activityIndicator.hidesWhenStopped = true
        return activityIndicator
    }

    /**
     Configures a footer view for the table view with a activity indicator.
     */
    private func configureFooterView() -> UIView {
        let width = tableView.frame.size.width
        let footerView = UIView(frame: CGRect(x: 0, y: 0, width: width, height: ActivityIndicator.height))
        activityIndicator.center = CGPoint(x: footerView.center.x, y: footerView.center.y - ActivityIndicator.verticalOffset)
        footerView.addSubview(activityIndicator)
        return footerView
    }
}

// MARK: - Constants
private extension TweetSearchTableViewController {
    
    private var tweetCount: Int { 20 }
    
    private var shouldReload: Bool {
        tableView.contentOffset.y >= (tableView.contentSize.height - tableView.frame.size.height)
    }
    
    private var tableViewIsMovingByUser: Bool {
        tableView.isDragging && (tableView.isDecelerating || tableView.isTracking)
    }
    
    struct ActivityIndicator {
        static let height: CGFloat = 30
        static let verticalOffset: CGFloat = 10
    }
}
