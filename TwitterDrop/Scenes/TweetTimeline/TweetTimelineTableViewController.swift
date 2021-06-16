/*
 MIT License

Copyright (c) 2021 Maik Müller (maikdrop) <maik_mueller@me.com>

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 
 Abstract:
 The table view controller shows a list of tweets that represents the timeline of a Twitter user. The tweets are fetched from Twitter and the timeline can be refreshed. Additionaly, the Twitter user can be logged out and a new view controller can be displayed in order to look for tweets.
 */

import UIKit
import OAuthSwift
import MyTwitterDrop
import Network

class TweetTimelineTableViewController: UITableViewController, HandleTweets {
    
    // MARK: - Properties
    private let loadingVC = LoadingViewController()
    private let authorize = Authentication(consumerKey: DeveloperCredentials.consumerKey, consumerSecret: DeveloperCredentials.consumerSecret)
    private let oauthSwift: OAuth1Swift
    
    private var lastTwitterRequest: Request?
    private(set) var tweets = [Array<MyTwitterDrop.Tweet>]()
 
    private let logoutHandler: () -> Void
    
    private var verifiedUser: User? {
        didSet {
            if verifiedUser != nil {
                initialTweetsFetch(for: verifiedUser!)
            } else {
                logoutHandler()
            }
        }
    }
    
    // MARK: - Create a tweet timeline
    init(oauthSwift: OAuth1Swift, logoutHandler: @escaping () -> Void) {
        self.oauthSwift = oauthSwift
        self.logoutHandler = logoutHandler
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit { print("DEINIT - TweetTimelineTableViewController") }
    
    // MARK: - API in order to subclass functionality for tweets and profile image of the Twitter user
    
    /**
     Fetches tweets from Twitter via network request and inserts them in the data source.
     
     - Parameter request: The tweets request.
     */
    func fetchTweets(for request: Request) {
      
        if Network.shared.isConnected {
            
            lastTwitterRequest = request
            
            request.fetchTweets() { [weak self] newTweets in
                
                if request == self?.lastTwitterRequest {
                    
                    if newTweets.isEmpty {
                        
                        self?.removeActivityIndicator()
                        
                    } else {
                        
                        self?.insertTweets(newTweets)
                    }
                }
            }
        } else {
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                
                self.removeActivityIndicator()
                
                self.infoAlertWithLinkToSettings(title: "Turn Off Airplane Mode or Use Wi-Fi to Access Data", message: "")
            }
        }
    }
    
    /**
     Inserts tweets into data source and updates the UI.
     
     - Parameter tweets: Tweets to insert.
     */
    func insertTweets(_ tweets: [MyTwitterDrop.Tweet]) {
       
        if !tweets.isEmpty {
            
            self.tweets.insert(tweets, at: 0)
            
            updateUIForTweets()
            
            if self.lastTwitterRequest?.min_id == self.tweets.first?.first?.identifier {
               
                self.removeActivityIndicator()
            }
            
            let tweeters = Set(tweets.map { $0.user })
            
            getProfileImage(for: tweeters)
        }
    }
    
    /**
     Fetches the profile image of Twitter users via network request.
     
     - Parameter twitterUsers: The Twitter users from a Twitter request.
     */
    func getProfileImage(for twitterUsers: Set<MyTwitterDrop.User>) {
        
        twitterUsers.forEach { user in
            
            TwitterUtility.getProfileImage(from: user) { [weak self] data in
                
                self?.updateProfileImage(data.image, for: data.twitterUser)
            }
        }
    }
    
    /**
     Updates the profile image of a twitter in the UI.
     
     - Parameter image: The profile image of the Twitter user.
     - Parameter twitterUserId: The user id of the Twitter user.
     */
    func updateProfileImage(_ image: UIImage, for twitterUser: MyTwitterDrop.User) {
       
        TwitterUtility.cache.insert(image, forKey: twitterUser.identifier)

        if twitterUser.identifier == Authentication.loggedInUserId {

            updateUIForLoggedInUser(with: image)
        }

        DispatchQueue.main.async {

            self.updateVisibleCells()
        }
    }
}

// MARK: - Default view controller methods
extension TweetTimelineTableViewController {
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView = UITableView.tweets
        
        Network.shared.startNetworkMonitor()
        
        configureRefreshControl()
        configureNavigationItems()
      
        checkUserCredentials()
    }
}

// MARK: - Table View
extension TweetTimelineTableViewController {
    
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
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
       
        if section == 0 && lastTwitterRequest != nil {
            
            return AppStrings.Timeline.sectionTitleLatestTweets
        }
        return AppStrings.Timeline.sectionTitleOlderTweets
    }
}

// MARK: - Private target methods
private extension TweetTimelineTableViewController {
    
    /**
     Handles the target action of the refresh control of the table view in order to refresh the tweets.
     */
    @objc private func handleRefreshControl() {
        
        if let request = lastTwitterRequest?.newer {
            
            fetchTweets(for: request)
            
        } else {
           
            checkUserCredentials()
        }
    }
    
    /**
     Handles the target action of the logout button in order to logout the user.
     */
    @objc private func logoutActBtn() {
        
        logoutAlert(title: AppStrings.Timeline.alertTitle, message: AppStrings.Timeline.logoutAlertMsg) {
            
            self.verifiedUser = nil
        }
    }
    
    /**
     Handles the target action of the search button in order to search for tweets.
     */
    @objc private func searchActBtn() {
       
        TweetSearchNaviPresenter().presentTweets(oauthSwift: oauthSwift, in: self)
    }
}

// MARK: - Private utility methods for tweet fetching
private extension TweetTimelineTableViewController {
    
    /**
     Checks the user credentials of the logged in user.
     */
    private func checkUserCredentials() {
        
        add(loadingVC)

        if Network.shared.isConnected {
      
            Authentication.checkUserCredentials(for: oauthSwift) { [weak self] result in
                
                switch result {
                case .success(let user):
                    self?.verifiedUser = user
                case .failure(let error):
                    print(error.localizedDescription)
                    self?.verifiedUser = nil
                    self?.removeActivityIndicator()
                }
            }
            
        } else {
           
            initialTweetsFetch(for: TwitterUtility.unverifiedUser)
        }
    }
    
    /**
     The first tweets fetch for timeline after user log in.
     
     - Parameter user: The logged in user.
     */
    private func initialTweetsFetch(for user: MyTwitterDrop.User) {
        
        getProfileImage(for: Set([user]))
        
        fetchTweets(for: twitterRequest())
    }

    /**
     Returns a Twitter request.
     
     - Returns: The Twitter request, which is used to fetch tweets for the user timeline.
     */
    private func twitterRequest() -> Request {
        
        return Request(oauthSwift: oauthSwift, count: tweetCountToFetch)
    }
}

// MARK: - UI updates
private extension TweetTimelineTableViewController {
    
    /**
     Updates the UI when new tweets were inserted.
     */
    private func updateUIForTweets() {
        
        DispatchQueue.main.async {
          
            self.tableView.insertSections([0], with: .fade)
           
            if self.tweets.count > 1 {
                
                self.tableView.headerView(forSection: 1)?.textLabel?.text = AppStrings.Timeline.sectionTitleOlderTweets
            }
        }
    }

    /**
     Updates the profile image of the logged in user.
     
     - Parameter profileImage: The new profile image of the logged in user.
     */
    private func updateUIForLoggedInUser(with profileImage: UIImage) {
        
        DispatchQueue.main.async {
            
            self.navigationItem.rightBarButtonItem = self.configureLogoutButton(with: profileImage)
        }
    }

    /**
     Removes all activity indicators from the UI.
     */
    private func removeActivityIndicator() {
        
        self.tableView.refreshControl?.endRefreshing()
        self.loadingVC.remove()
    }
}

// MARK: - Private methods to configure UI elements.
private extension TweetTimelineTableViewController {
    
    /**
     Configures the navigation items: title and searchbutton.
     */
    private func configureNavigationItems() {

        navigationItem.leftBarButtonItem = configureSearchBtn()
        navigationItem.rightBarButtonItem = configureLogoutButton(with: TwitterUtility.defaultProfileImage ?? UIImage())
        navigationItem.title = AppStrings.Timeline.title
    }
    
    /**
     Configures the refresh control of the table view.
     */
    private func configureRefreshControl () {
        
        tableView.refreshControl = UIRefreshControl()
        tableView.refreshControl?.addTarget(self,
                                            action: #selector(handleRefreshControl),
                                            for: .valueChanged)
    }
    
    /**
     Configures a search button for the navigation bar.
     
     - Returns: The configured search button.
     */
    private func configureSearchBtn() -> UIBarButtonItem {
        
        let searchBtn = UIBarButtonItem.searchBtn
        
        searchBtn.action = #selector(searchActBtn)
        searchBtn.target = self
        
        return searchBtn
    }
    
    /**
     Configures a logout button for the navigation bar.
     
     - Parameter profileImage: The profile image of the logout button.
     
     - Returns: The configured logout button.
     */
    private func configureLogoutButton(with profileImage: UIImage) -> UIBarButtonItem? {
        
        if let logoutBtn = UIBarButtonItem.makeLogoutButton(with: profileImage, size: userImageSize), let button = logoutBtn.customView as? UIButton {
            
            button.addTarget(self, action: #selector(logoutActBtn), for: .touchUpInside)
            
            return logoutBtn
        }
        return nil
    }
}

// MARK: - Constants
private extension TweetTimelineTableViewController {
    
    private var tweetCountToFetch: Int { 20 }
    private var userImageSize: CGSize { CGSize(width: 35, height: 35) }
}
