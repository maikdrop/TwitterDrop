/*
 MIT License

Copyright (c) 2021 Maik Müller (maikdrop) <maik_mueller@me.com>

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 
 Abstract:
 The class handles the authorization of the app and the authentication of the user. -> source: https://github.com/OAuthSwift/OAuthSwift/blob/master/Demo/Common/ViewController.swift
 It's the launch view controller because there is an internal error of OAuthSwift. If the web view controller is deinitialized after authorization, the app freezes.
 */

import Foundation
import MyTwitterDrop
import OAuthSwift
import UIKit

class AuthorizeViewController: OAuthViewController {
    
    // MARK: - Properties
    private let loadingVC = LoadingViewController()
    private let authorize = Authentication(consumerKey: DeveloperCredentials.consumerKey, consumerSecret: DeveloperCredentials.consumerSecret)
    private var oauthSwift: OAuth1Swift?
    private lazy var internalWebViewController = configureWebViewController()
    private lazy var logoutHandler: () -> Void = { [weak self] in self?.logout() }

    // MARK: - IBOutlets and Actions
    @IBOutlet private weak var authorizeBtn: UIButton! {
        didSet {
            authorizeBtn.isHidden = true
        }
    }
    
    @IBAction private func authorizeActBtn(_ sender: UIButton) {
        authorizeBtn.isHidden = true
        add(loadingVC)
        authorizeApplication()
    }
    
    deinit { print("DEINIT - AuthorizeViewController") }
}

// MARK: - Default view controller methods
extension AuthorizeViewController {
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if authorizeBtn.isHidden {
            if let oauthSwift = authorize.loadUserCredentials() {
                TweetTimelineNaviPresenter().presentTimeline(oauthSwift: oauthSwift, in: self, logoutHandler: logoutHandler)
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

// MARK: - Private methods for authorization
private extension AuthorizeViewController {
    
    /**
     Authorizes the app to get access to the data of the Twitter user and saves the returned user credentials.
     */
    private func authorizeApplication() {
        
        oauthSwift = authorize.newOauthObject()
        oauthSwift?.authorizeURLHandler = internalWebViewController
        
        guard let callBackUrl = URL(string: AppStrings.Authorize.callBackURL) else {
            return
        }
        
        oauthSwift?.authorize(withCallbackURL: callBackUrl) { [weak self] result in
            
            self?.internalWebViewController.dismissWebViewController()
            
            switch result {
            case .success(let (credentials, _, _)):
                Authentication.saveCredentials(token: credentials.oauthToken, tokenSecret: credentials.oauthTokenSecret)
            case .failure(_):
                self?.authorizeBtn.isHidden = false
                self?.infoAlertWithRetryAction(
                    title: AppStrings.Alert.authorizeFailedTitle,
                    message: AppStrings.Alert.authorizeFailedMsg,
                    retryActionHandler: { self?.authorizeApplication() })
            }
        }
    }
    
    /**
     Handles the user logout.
     */
    private func logout() {
        
        authorizeBtn.isHidden = false
        
        presentedViewController?.dismiss(animated: true)
        
        Authentication.removeCredentials()
        
        internalWebViewController = configureWebViewController()
    }
}

// MARK: - Private configuration methods
private extension AuthorizeViewController {
    
    /**
     Configures the web view controller for the authorization of the app.
     
     - Returns: The configured web view controller.
     */
    private func configureWebViewController() -> WebViewController {
        let controller = WebViewController()
        controller.modalTransitionStyle = .flipHorizontal
        controller.modalPresentationStyle = .fullScreen
        controller.view = UIView(frame: UIScreen.main.bounds)
        controller.delegate = self
        controller.viewDidLoad()
        return controller
    }
}

// MARK: - Oauth web view controller delegate protocol
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
