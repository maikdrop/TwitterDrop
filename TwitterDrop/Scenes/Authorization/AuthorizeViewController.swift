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
    var authorizeHandler : ((String,String) -> Void)?
    private let loadingVC = LoadingViewController()
    private let authorize = Authorize(consumerKey: DeveloperCredentials.consumerKey, consumerSecret: DeveloperCredentials.consumerSecret)
    private var oauthswift: OAuth1Swift?
    private lazy var internalWebViewController = createWebViewController()

    // MARK: - IBActions and Outlets
    @IBOutlet weak var authorizeBtn: UIButton!
    
    @IBAction func authorizeActBtn(_ sender: UIButton) {
        authorizeBtn.isHidden = true
        add(loadingVC)
        authorizeApplication()
    }
    
    deinit { print("DEINIT - AuthorizeViewController") }
}

// MARK: - Default methods
extension AuthorizeViewController {
    
    override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        viewControllerToPresent.modalPresentationStyle = .fullScreen
        let handler = { self.loadingVC.remove() }
        super.present(viewControllerToPresent, animated: true, completion: handler)
    }
}

// MARK: - Private network request methods
private extension AuthorizeViewController {
    
    private func authorizeApplication() {
        oauthswift = authorize.newOauthObject()
        oauthswift?.authorizeURLHandler = internalWebViewController
        oauthswift?.authorize(
            withCallbackURL: URL(string: AppStrings.Twitter.callBackURL)!) { [weak self] result in
            switch result {
            case .success(let (credential, _, _)):
                self?.authorizeHandler?(credential.oauthToken, credential.oauthTokenSecret)
            case .failure(let error):
                self?.authorizeBtn.isHidden = false
                print(error.description)
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
        self.oauthswift?.cancel()
    }
}

// MARK: - Private utility methods
private extension AuthorizeViewController {
    
    private func createWebViewController() -> WebViewController {
        let controller = WebViewController()
        controller.modalTransitionStyle = .flipHorizontal
        controller.view = UIView(frame: UIScreen.main.bounds)
        controller.delegate = self
        controller.viewDidLoad()
        return controller
    }
}
