//
//  TweetTimelineTableViewController.swift
//  TwitterDrop
//
//  Created by Maik on 09.02.21.
//

import UIKit
import OAuthSwift
import MyTwitterDrop

class TweetTimelineTableViewController: UITableViewController {
    
    private var oauthswift: OAuth1Swift?
    private let loadingVC = LoadingViewController()
    private let authorize = Authorize(consumerKey: DeveloperCredentials.consumerKey, consumerSecret: DeveloperCredentials.consumerSecret)
    
    @IBAction func logoutActBtn(_ sender: UIBarButtonItem) {
        logoutAlert(title: "Attention", message: "Are you sure you want to logout?", actionHandler: {
            self.removeDataFromKeychain()
        })
    }
    
    @IBAction func refreshAct(_ sender: UIRefreshControl) {
    
    
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = AppStrings.Twitter.title
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        checkUserCredentials()
    }
    
    @objc func logoutAct(_ sender: UIBarButtonItem) {
        removeDataFromKeychain()
    }

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
    
    private func removeDataFromKeychain() {
        Authorize.removeCredentials(completion: { error in
            guard error == nil else {
                print(error!)
                self.infoAlert(title: "Attention", message: "Error occured while removing credentials from keychain.", actionHandler: {
                    self.removeDataFromKeychain()
                })
                return
            }
            AuthorizeNaviPresenter().present(in: self)
        })
    }

    // TODO check WIFI connection before loading user credentials -> do nothing when no wifi conection is found, add footer "NO Wifi" connection
    private func checkUserCredentials() {
        add(loadingVC)
        if let oauth = authorize.loadUserCredentials() {
            Authorize.checkCredentials(for: oauth) { result in
                if case .failure = result {
                    AuthorizeNaviPresenter().present(in: self)
                } else {
                    print("Credentials valid")
                    self.oauthswift = oauth
                }
            }
        } else {
            AuthorizeNaviPresenter().present(in: self)
        }
        self.loadingVC.remove()
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
