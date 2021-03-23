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
    private var oauthSwift: OAuth1Swift
    
    private var lastTwitterRequest: MyTwitterDrop.Request?
    private var tweets = [Array<MyTwitterDrop.Tweet>]()
    
    private lazy var activityIndicator = configureActivityIndicator()
    static let cache = Cache<String, UIImage>()

    private let logoutHandler: () -> Void
    private(set) var loggedInUser: User? {
        didSet {
            if loggedInUser == nil {
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
    
    // MARK: - API in order to subclass the table view conntroller
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
                        Self.cache.insert(image, forKey: user.identifier)
                        self?.setProfileImage(for: user.identifier, image: image)
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
    
    func fetchTweets(for request: MyTwitterDrop.Request) {
        lastTwitterRequest = request
        request.fetchTweets() { [weak self] newTweets in
            if request == self?.lastTwitterRequest {
                if newTweets.isEmpty {
                    print(newTweets.count)
                    DispatchQueue.main.async {
                        self?.tableView.refreshControl?.endRefreshing()
                        self?.activityIndicator.stopAnimating()
                    }
                } else {
                    self?.insertTweets(newTweets)
                }
            }
        }
    }
    
    func insertTweets(_ newTweets: [MyTwitterDrop.Tweet]) {
        
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
    
    func credentialCheckFailed() {
       loggedInUser = nil
    }
}

// MARK: - Default Methods
extension TweetTimelineTableViewController {
        
    override func viewDidLoad() {
        super.viewDidLoad()
        configureTableView()
        checkUserCredentials() { [weak self] in
            self?.initialDataFetch()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if tableView.tableFooterView == nil {
            tableView.tableFooterView = configureFooterView()
        }
    }
}

// MARK: - Table view data source and delegate methods
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
    
    // Delegate
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if tableView.isDragging, tableView.isDecelerating || tableView.isTracking {
            if tableView.contentOffset.y >= (tableView.contentSize.height - tableView.frame.size.height) + 40 {
                if !activityIndicator.isAnimating {
                    activityIndicator.startAnimating()
                    if let last = tweets.last?.last, let id = Int(last.identifier) {
                        let oldRequest = MyTwitterDrop.Request(oauthSwift: oauthSwift, latestTweetID: String(id - 1), count: 15)
                        fetchTweets(for: oldRequest)
                    }
                } else {
                    activityIndicator.stopAnimating()
                }
            }
        }
    }
}

// MARK: - Private target methods
private extension TweetTimelineTableViewController {
    
    @objc private func handleRefreshControl() {
        
        if let request = lastTwitterRequest?.newer {
            fetchTweets(for: request)
        } else {
            tableView.refreshControl?.endRefreshing()
        }
    }
    
    @objc private func logoutActBtn() {
        logoutAlert(title: AppStrings.Twitter.alertTitle, message: AppStrings.Twitter.logoutAlertMsg, actionHandler: {
            self.loggedInUser = nil
        })
    }
}

// MARK: - Private methods for network communication
private extension TweetTimelineTableViewController {
    
    private func initialDataFetch() {
        
        if let user = loggedInUser {
            fetchProfileImage(for: Set([user])) { [weak self] in
                if let profileImage = Self.cache.value(forKey: user.identifier) {
                    self?.setProfileImage(for: user.identifier, image: profileImage)
                }
                if let oauthSwift = self?.oauthSwift {
                    let request = Request(oauthSwift: oauthSwift, latestTweetID: self?.tweets.first?.first?.identifier ?? "", count: 15)
                    self?.fetchTweets(for: request)
                }
            }
        }
    }
    
    private func checkUserCredentials(completion: @escaping () -> Void) {
        Authorize.checkUserCredentials(for: oauthSwift) { [weak self] result in
            switch result {
            case .success(let user):
                self?.loggedInUser = user
                completion()
            case .failure(let error):
                print(#function)
                print(error.localizedDescription)
                self?.tableView.refreshControl?.endRefreshing()
                self?.credentialCheckFailed()
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
}

// MARK: - Private methods for tweet handling
private extension TweetTimelineTableViewController {
    
    private func oldestTweetsRequest(for requestType: MyTwitterDrop.Request.RequestTypes) -> MyTwitterDrop.Request? {
        if let lastSection = tweets.last, let lastElement = lastSection.last?.identifier, let id = Int(lastElement) {
            
            return MyTwitterDrop.Request(oauthSwift: oauthSwift, oldestTweetID: String(id - 1), count: 15)
        }
        return nil
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
        if oldTweets.count > 1 {
            tweets.append(oldTweets)
            fetchProfileImage(for: tweeter) { [weak self] in
                if let sections = self?.tweets.count, sections >= 1 {
                    DispatchQueue.main.async {
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

// MARK: - Private configuration methods
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
    
    private func configureTableView() {
        let textFieldCell = UINib(nibName: AppStrings.TweetCell.identifier,bundle: nil)
        tableView.register(textFieldCell, forCellReuseIdentifier: AppStrings.TweetCell.identifier)
        tableView.estimatedRowHeight = tableView.rowHeight
        tableView.rowHeight = UITableView.automaticDimension
        configureRefreshControl()
        tableView.refreshControl?.beginRefreshing()
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
