/*
 MIT License

Copyright (c) 2021 Maik Müller (maikdrop) <maik_mueller@me.com>

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

import UIKit
import OAuthSwift
import MyTwitterDrop
import Network

class TweetTimelineTableViewController: UITableViewController {
    
    // MARK: - Properties
    private let loadingVC = LoadingViewController()
    private let authorize = Authorize(consumerKey: DeveloperCredentials.consumerKey, consumerSecret: DeveloperCredentials.consumerSecret)
    private var oauthswift: OAuth1Swift?
    private var lastTwitterRequest: MyTwitterDrop.Request?
    private lazy var authorizeHandler: (String, String) -> Void = { token, tokeSecret in
        self.presentedViewController?.dismiss(animated: false)
        Authorize.saveCredentials(token: token, tokenSecret: tokeSecret)
//        self.checkUserCredentials()
    }
    private var tweets = [Array<MyTwitterDrop.Tweet>]()
    private lazy var activityIndicator = configureActivityIndicator()
    static let cache = Cache<String, UIImage>()
    
    private(set) var user: User? {
        didSet {
            if user != nil {
//                checkProfileImage(for: [user!]) { [weak self] user in
                self.fetchProfileImage(for: user!)
//                }
            } else {
                AuthorizeNaviPresenter().present(in: self, authorizeHandler: self.authorizeHandler)
            }
        }
    }
    
    // MARK: - IBActions and Outlets
    @IBOutlet private weak var footerView: UIView!

    @objc private func logoutActBtn() {
        logoutAlert(title: AppStrings.Twitter.alertTitle, message: AppStrings.Twitter.logoutAlertMsg, actionHandler: {
            self.removeDataFromKeychain()
        })
    }
    
    deinit { print("DEINIT - TweetTimelineTableViewController") }
    
    // MARK: - Internal API in order to subclass the table view conntroller
    func fetchProfileImage(for users: Set<MyTwitterDrop.User>, completionHandler: @escaping () -> Void) {
        if users.isEmpty { completionHandler() }
        var pendingUrls = Set(users.compactMap({ $0.getProfileImage(sizeCategory: .original) }))
        for user in users {
            if let url = user.getProfileImage(sizeCategory: .original) {
                URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
                    guard error == nil else {
                        print(#function)
                        print("Error: \(error!.localizedDescription)")
                        return
                    }
                    guard let responseData = data else {
                        print(#function)
                        print("Error: did not receive data")
                        self?.verify(response: response, for: user)
                        return
                    }
                    if let image = UIImage(data: responseData) {
                        Self.cache.insert(image, forKey: user.id)
                        self?.setProfileImage(for: user.id, image: image)
                        pendingUrls.remove(url)
                        if pendingUrls.isEmpty {
                            completionHandler()
                        }
                    }
                }.resume()
            }
        }
    }
    
    func setProfileImage(for userID: String, image: UIImage) {
        if Authorize.loggedUserID == userID {
            DispatchQueue.main.async {
                self.navigationItem.rightBarButtonItem = self.configureLogoutBarBtn(with: image)
            }
        }
    }
    
    func credentialCheckFailed() {
        AuthorizeNaviPresenter().present(in: self, authorizeHandler: self.authorizeHandler)
    }
    
    func insertTweets(_ newTweets: [MyTwitterDrop.Tweet]) {
        //checkProfileImage(for: usersToCheck) { [weak self] checkedUsers in
        let tweeter = getTweeterFrom(newTweets)
        if !tweets.isEmpty && !newTweets.isEmpty {
            if tweets.last!.last!.created > newTweets.first!.created {
                insertOldTweets(newTweets, tweeter)
            } else {
                insertLatestTweets(newTweets, tweeter)
            }
        } else {
            insertLatestTweets(newTweets, tweeter)
        }
    }
    
    private func insertLatestTweets(_ latestweets: [MyTwitterDrop.Tweet], _ tweeter: Set<MyTwitterDrop.User>) {
        if !latestweets.isEmpty {
            tweets.insert(latestweets, at: 0)
            fetchProfileImage(for: tweeter) { [weak self] in
                DispatchQueue.main.async {
                    self?.tableView.insertSections([0], with: .fade)
                    if self?.lastTwitterRequest?.min_id == latestweets.first?.identifier {
                        self?.tableView.refreshControl?.endRefreshing()
                    }
                }
            }
        }
    }
    
    private func insertOldTweets(_ oldTweets: [MyTwitterDrop.Tweet], _ tweeter: Set<MyTwitterDrop.User>) {
        if !oldTweets.isEmpty {
            tweets.append(oldTweets)
            fetchProfileImage(for: tweeter) { [weak self] in
                DispatchQueue.main.async {
                    if let sections = self?.tweets.count, sections >= 1 {
                        self?.tableView.insertSections([sections-1], with: .fade)
                        self?.activityIndicator.stopAnimating()
                    }
                }
            }
        }
    }
    
    private func getTweeterFrom(_ tweets: [MyTwitterDrop.Tweet]) -> Set<MyTwitterDrop.User> {
        var usersFromTweets = [MyTwitterDrop.User]()
        tweets.forEach { usersFromTweets.append($0.user) }
        return Set(usersFromTweets)
    }
}

// MARK: - Default Methods
extension TweetTimelineTableViewController {
        
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.estimatedRowHeight = tableView.rowHeight
        tableView.rowHeight = UITableView.automaticDimension
        configureRefreshControl()
        tableView.refreshControl?.beginRefreshing()
        tableView.tableFooterView = configureFooterView()
       
        // used when not subclassed
//        if user == nil { checkUserCredentials() }
    }
}

// MARK: - Table view data source and delegate methods
extension TweetTimelineTableViewController {
    
    // MARK: - Table view data source
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
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if tableView.isDragging, tableView.isDecelerating || tableView.isTracking {
            if tableView.contentOffset.y >= (tableView.contentSize.height - tableView.frame.size.height) {
                if !activityIndicator.isAnimating {
                    activityIndicator.startAnimating()
                    if let request = oldestTweetsRequest(for: .homeTimeline) {
                        fetchTweets(for: request)
                    } else {
                        activityIndicator.stopAnimating()
                    }
                }
            }
        }
    }
}

// MARK: - Private target methods
private extension TweetTimelineTableViewController {
    
    @objc private func logoutAct(_ sender: UIBarButtonItem) {
        removeDataFromKeychain()
    }
    
    @objc private func handleRefreshControl() {
        
        if let request = latestTweetsRequest(for: .homeTimeline) {
            fetchTweets(for: request)
        } else {
            tableView.refreshControl?.endRefreshing()
        }
    }
}

// MARK: - Private methods for MyTwitterDrop handling
extension TweetTimelineTableViewController {
    
    // Profile image
    private func fetchProfileImage(for user: MyTwitterDrop.User) {
        
        fetchProfileImage(for: Set([user])) { [weak self] in
            
            if let userID = self?.user?.id, let profileImage = Self.cache.value(forKey: userID) {
                self?.setProfileImage(for: userID, image: profileImage)
            }
            if let request = self?.latestTweetsRequest(for: .homeTimeline) {
                DispatchQueue.main.async {
                    self?.fetchTweets(for: request)
                }
            }
        }
    }
    
    private func verify(response: URLResponse?, for user: MyTwitterDrop.User) {
        
        if let httpResponse = response as? HTTPURLResponse {
            
            if HTTPStatusCode(code: httpResponse.statusCode) == .client {
                if httpResponse.statusCode == 403 || httpResponse.statusCode == 404 {
                    print(#function)
                    // TODO retrieve latest user data - GET https://api.twitter.com/1.1/users/show.json
                }
            }
        }
    }
    
    private func checkForNewProfileImage(for user: MyTwitterDrop.User, completion: @escaping (Bool) -> Void) {
        
        if let url = user.getProfileImage(sizeCategory: .original) {
            
            var request = URLRequest(url: url)
            request.httpMethod = "HEAD"
            request.timeoutInterval = 5
            
            URLSession.shared.dataTask(with:request) { [weak self] (_, response, error) in
                guard error == nil else {
                    return
                }
                self?.verify(response: response, for: user)
            }.resume()
        }
    }
    
    // Tweet
    private func latestTweetsRequest(for requestType: MyTwitterDrop.Request.RequestTypes) -> MyTwitterDrop.Request? {
        if let authorize = oauthswift {
            return MyTwitterDrop.Request(oauthswift: authorize, latestTweetID: tweets.first?.first?.identifier ?? "", count: 15)
        }
        return nil
    }
    
    private func oldestTweetsRequest(for requestType: MyTwitterDrop.Request.RequestTypes) -> MyTwitterDrop.Request? {
        if let authorize = oauthswift, let lastSection = tweets.last, let lastElement = lastSection.last?.identifier, let id = Int(lastElement) {
           
            return MyTwitterDrop.Request(oauthswift: authorize, oldestTweetID: String(id - 1), count: 15)
        }
        return nil
    }
    
    
    private func fetchTweets(for request: MyTwitterDrop.Request) {
        lastTwitterRequest = request
        request.fetchTweets(handler: { [weak self] newTweets in
            DispatchQueue.main.async {
                if request == self?.lastTwitterRequest {
                    if newTweets.isEmpty {
                        self?.tableView.refreshControl?.endRefreshing()
                        self?.activityIndicator.stopAnimating()
                    } else {
                        self?.insertTweets(newTweets)
                    }
                }
            }
        })
    }
    
    // User authorization
    func checkUserCredentials() {
        if let oauth = authorize.loadUserCredentials() {
            self.oauthswift = oauth
            Authorize.checkCredentials(for: oauth) { [weak self] result in
                switch result {
                case .success(let user):
                    DispatchQueue.main.async {
                        self?.user = user
                    }
                case .failure(let error):
                    print(#function)
                    print(error.localizedDescription)
                    self?.tableView.refreshControl?.endRefreshing()
                    self?.credentialCheckFailed()
                }
            }
        } else {
            AuthorizeNaviPresenter().present(in: self, authorizeHandler: self.authorizeHandler)
        }
    }
    
    private func removeDataFromKeychain() {
        Authorize.removeCredentials(completion: { error in
            guard error == nil else {
                print(error!)
                self.infoAlert(title: AppStrings.Twitter.alertTitle, message: AppStrings.Twitter.logoutErrorAlertMsg, retryActionHandler: {
                    self.removeDataFromKeychain()
                })
                return
            }
            AuthorizeNaviPresenter().present(in: self, authorizeHandler: self.authorizeHandler)
        })
    }
}

// MARK: - Utility methods
private extension TweetTimelineTableViewController {
    
    private func configureFooterView() -> UIView {
        let width = tableView.frame.size.width
        let customView = UIView(frame: CGRect(x: 0, y: 0, width: width, height: 80))
        activityIndicator.center = customView.center
        customView.addSubview(activityIndicator)
        return customView
    }
    
    private func configureRefreshControl () {
       tableView.refreshControl = UIRefreshControl()
       tableView.refreshControl?.addTarget(self, action:
                                          #selector(handleRefreshControl),
                                          for: .valueChanged)
    }
    
    private func configureActivityIndicator() -> UIActivityIndicatorView {
        let activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.hidesWhenStopped = true
        return activityIndicator
    }
    
    private func configureLogoutBarBtn(with image: UIImage) -> UIBarButtonItem? {
        if let resizedImage = image.resizeImage(for: CGSize(width: 42, height: 42)) {
            let button = UIButton()
            button.setImage(resizedImage, for: .normal)
            button.addTarget(self, action: #selector(logoutActBtn), for: .touchUpInside)
            let barButton = UIBarButtonItem(customView: button)
            barButton.customView?.layer.cornerRadius = resizedImage.size.height / 2
            barButton.customView?.clipsToBounds = true
            return barButton
        }
        return nil
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
