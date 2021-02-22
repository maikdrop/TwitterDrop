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
    private lazy var authorizeHandler: (String, String) -> Void = { token, tokeSecret in
        self.presentedViewController?.dismiss(animated: false)
        Authorize.saveCredentials(token: token, tokenSecret: tokeSecret)
        self.checkUserCredentials()
    }
    
    private(set) var user: User? {
        didSet {
//            tableView.refreshControl?.endRefreshing()
//            tableView.reloadData()
            if user != nil {
                fetchProfileImage(from: user!)
                // TODO fetch Tweets
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
    
    @IBAction private func refreshAct(_ sender: UIRefreshControl) {
       
    }
    
    // MARK: - Internal API in order to subclass the table view conntroller
    func fetchProfileImage(from user: MyTwitterDrop.User) {
        
        guard let url = user.getProfileImage(sizeCategory: .normal) else {
            return
        }
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let imageData = try? Data(contentsOf: url) else {
                return
            }
            DispatchQueue.main.async {
                if let profileImage = UIImage(data: imageData) {
                    self?.setUserProfileImage(image: profileImage)
                    self?.loadingVC.remove()
                }
            }
        }
    }
    
    func setUserProfileImage(image: UIImage) {
        navigationItem.rightBarButtonItem = createLogoutBarBtn(with: image)
    }
    
    func removeDataFromKeychain() {
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

    func checkUserCredentials() {
        add(loadingVC)
        if let oauth = authorize.loadUserCredentials() {
            Authorize.checkCredentials(for: oauth) { [weak self] result in
                switch result {
                case .success(let user):
                    DispatchQueue.main.async {
                        self?.user = user
                    }
                case .failure(let error):
                    print(error)
                    self?.credentialCheckFailed()
                    self?.loadingVC.remove()
                }
            }
        } else {
            AuthorizeNaviPresenter().present(in: self, authorizeHandler: self.authorizeHandler)
        }
    }
    
    func credentialCheckFailed() {
        AuthorizeNaviPresenter().present(in: self, authorizeHandler: self.authorizeHandler)
    }
}

// MARK: - Default Methods
extension TweetTimelineTableViewController {
        
    override func viewDidLoad() {
        super.viewDidLoad()
        if user == nil {
            checkUserCredentials()
        }
    }
}
 
// MARK: - Table view data source and delegate methods
extension TweetTimelineTableViewController {
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 0
    }


    /*
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        // Configure the cell...

        return cell
    }
    */
    
}

// MARK: - private target methods
private extension TweetTimelineTableViewController {
    
    @objc private func logoutAct(_ sender: UIBarButtonItem) {
        removeDataFromKeychain()
    }
}

// MARK: - private utility methods
private extension TweetTimelineTableViewController {
    
    private func createLogoutBarBtn(with image: UIImage) -> UIBarButtonItem? {
        let button = UIButton()
        button.setImage(image, for: .normal)
        button.addTarget(self, action: #selector(logoutActBtn), for: .touchUpInside)
        let barButton = UIBarButtonItem(customView: button)
        barButton.customView?.layer.cornerRadius = image.size.height / 2
        barButton.customView?.clipsToBounds = true
        return barButton
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
