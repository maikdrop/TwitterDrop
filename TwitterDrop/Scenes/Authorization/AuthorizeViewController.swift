/*
 MIT License

Copyright (c) 2021 Maik Müller (maikdrop) <maik_mueller@me.com>

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

import Foundation
import MyTwitterDrop
import OAuthSwift
import UIKit

class AuthorizeViewController: OAuthViewController {
    
    // MARK: - Properties
//    var authorizeHandler : ((String,String) -> Void)?
    private let loadingVC = LoadingViewController()
    private let authorize = Authorize(consumerKey: DeveloperCredentials.consumerKey, consumerSecret: DeveloperCredentials.consumerSecret)
    private var oauthSwift: OAuth1Swift?
    private lazy var internalWebViewController = createWebViewController()
    private lazy var logoutHandler: () -> Void = { [weak self] in
        self?.authorizeBtn.isHidden = false
        self?.presentedViewController?.dismiss(animated: true)
        self?.removeUserCredentialsFromKeychain()
    }

    // MARK: - IBActions and Outlets
    @IBOutlet private weak var authorizeBtn: UIButton! {
        didSet {
            authorizeBtn.isHidden = true
        }
    }
    
    @IBAction func authorizeActBtn(_ sender: UIButton) {
        authorizeBtn.isHidden = true
        add(loadingVC)
        authorizeApplication()
    }
    
    deinit { print("DEINIT - AuthorizeViewController") }
}

// MARK: - Default methods
extension AuthorizeViewController {
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if authorizeBtn.isHidden {
            if let oauthSwift = authorize.loadUserCredentials() {
                TweetTimelineNaviPresenter().present(in: self, oauthSwift: oauthSwift, logoutHandler: logoutHandler)
            } else {
                authorizeBtn.isHidden = false
            }
        }
    }
    
    override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        if viewControllerToPresent is WebViewController {
            let handler = { self.loadingVC.remove() }
            super.present(viewControllerToPresent, animated: true, completion: handler)
            return
        }
        super.present(viewControllerToPresent, animated: true) {
            self.authorizeBtn.isHidden = false
        }
    }
}

// MARK: - Private network request methods
private extension AuthorizeViewController {
    
    private func removeUserCredentialsFromKeychain() {
        Authorize.removeCredentials(completion: { error in
            guard error == nil else {
                print(error!.localizedDescription)
                Authorize.saveCredentials(token: "", tokenSecret: "")
                return
            }
        })
    }
    
    private func authorizeApplication() {
        oauthSwift = authorize.newOauthObject()
        oauthSwift?.authorizeURLHandler = internalWebViewController
        oauthSwift?.authorize(
            withCallbackURL: URL(string: AppStrings.Twitter.callBackURL)!) { [weak self] result in
            switch result {
            case .success(let (credential, _, _)):
                Authorize.saveCredentials(token: credential.oauthToken, tokenSecret: credential.oauthTokenSecret)
                self?.internalWebViewController.dismissWebViewController()
            case .failure(let error):
                print(error.description)
                self?.authorizeBtn.isHidden = false
                self?.infoAlertWithRetryAction(title: "Error", message: "Do you want to authorize again?", retryActionHandler: { self?.authorizeApplication() })
            }
        }
    }
}

// MARK: - Oauth web view controller delegate methods
extension AuthorizeViewController: OAuthWebViewControllerDelegate {
    
    func oauthWebViewControllerDidPresent() {}
    func oauthWebViewControllerDidDismiss() {}
    func oauthWebViewControllerWillAppear() {}
    func oauthWebViewControllerDidAppear() {}
    func oauthWebViewControllerWillDisappear() {}
    func oauthWebViewControllerDidDisappear() {
        // Ensure all listeners are removed if presented web view close
        self.oauthSwift?.cancel()
    }
}

// MARK: - Private utility methods
private extension AuthorizeViewController {
    
    private func createWebViewController() -> WebViewController {
        let controller = WebViewController()
        controller.modalTransitionStyle = .flipHorizontal
        controller.modalPresentationStyle = .fullScreen
        controller.view = UIView(frame: UIScreen.main.bounds)
        controller.delegate = self
        controller.viewDidLoad()
        return controller
    }
}


//// User authorization
//private func checkUserCredentials(for oauth: OAuth1Swift) {
//    Authorize.checkCredentials(for: oauth) { [weak self] result in
//        self?.loadingVC.remove()
//        switch result {
//        case .success(let user):
//            if let user = user {
//                    TweetTimelineNaviPresenter().present(in: self, credential: user, authorizeHandler: self?.authorizeHandler)
//            }
//        case .failure(let error):
//            print(#function)
//            print(error.localizedDescription)
//            self?.authorizeBtn.isHidden = false
//            self?.infoAlertWithRetryAction(title: "Error", message: "Do you want to verify user credentials again?", retryActionHandler: { self?.checkUserCredentials(for: oauth) })
//        }
//    }
//}
