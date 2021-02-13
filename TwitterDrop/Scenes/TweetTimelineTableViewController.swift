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
   
    
    @IBAction func logoutActBtn(_ sender: UIBarButtonItem) {
        AuthorizeNaviPresenter().present(in: self)
    }
    
    @IBAction func refreshAct(_ sender: UIRefreshControl) {
    
    
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = AppStrings.Twitter.title
    
    }
    
    @objc func logoutAct(_ sender: UIBarButtonItem) {
       
        
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
    
    @IBAction func login(bySegue: UIStoryboardSegue) {
       
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
