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
    
    private let loadingVC = LoadingViewController()
    
    private lazy var internalWebViewController = createWebViewController()
    
    private var oauthswift: OAuth1Swift?

    @IBOutlet weak var authorizeBtn: UIButton!
    
    @IBAction func authorizeActBtn(_ sender: UIButton) {
        add(loadingVC)
        authorizeApplication()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        viewControllerToPresent.modalPresentationStyle = .fullScreen
        let handler = { self.loadingVC.remove() }
        super.present(viewControllerToPresent, animated: true, completion: handler)
    }
}

private extension AuthorizeViewController {
    
    private func authorizeApplication() {
        oauthswift?.authorizeURLHandler = internalWebViewController
        oauthswift?.authorize(
            withCallbackURL: URL(string: "mytwitter://oauth-callback/twitter")!) { result in
            switch result {
            case .success:
                self.performSegue(withIdentifier: "loginBuySegue", sender: self)
            case .failure(let error):
                self.authorizeBtn.isHidden = false
                print(error.description)
            }
        }
    }
    
    private func createWebViewController() -> WebViewController {
        let controller = WebViewController()
        controller.modalTransitionStyle = .flipHorizontal
        controller.view = UIView(frame: UIScreen.main.bounds) // needed if no nib or not loaded from storyboard
        controller.delegate = self
        controller.viewDidLoad()
        return controller
    }
}

extension AuthorizeViewController: OAuthWebViewControllerDelegate {
    
    func oauthWebViewControllerDidPresent() {
       
    }
    func oauthWebViewControllerDidDismiss() {
        
    }
    
    func oauthWebViewControllerWillAppear() {
        authorizeBtn.isHidden = true
    }
    
    func oauthWebViewControllerDidAppear() {
       
    }
    func oauthWebViewControllerWillDisappear() {
    }
    func oauthWebViewControllerDidDisappear() {
        // Ensure all listeners are removed if presented web view close
        self.oauthswift?.cancel()
    }
}
