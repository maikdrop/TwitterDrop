/*
 MIT License

Copyright (c) 2021 Maik Müller (maikdrop) <maik_mueller@me.com>

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

import UIKit
import OAuthSwift
import WebKit

class WebViewController: OAuthWebViewController {
    
    // MARK: - Properties
    private var targetURL: URL?
    private let webView: WKWebView = WKWebView()
    private let loadingVC = LoadingViewController()
    
    // MARK: - Overriden methods from base class
    override func handle(_ url: URL) {
        targetURL = url
        super.handle(url)
        loadAddressURL()
    }
    
    deinit { print("DEINIT - WebViewController") }
}

// MARK: - Default methods
extension WebViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.webView.allowsBackForwardNavigationGestures = true
        self.webView.frame = self.view.bounds
        self.webView.navigationDelegate = self
        self.webView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.webView)
    }
}

// MARK: - Webkit navigation delegate methods
extension WebViewController: WKNavigationDelegate {
    
    // Delegate method to remove loading wheel
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.loadingVC.remove()
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        
        // here we handle internally the callback url and call method that call handleOpenURL (not app scheme used)
        if let url = navigationAction.request.url {
            if url.scheme == "mytwitter" {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
                dismissAuthorization(decisionHandler: decisionHandler)
                return
            }
        }
        decisionHandler(.allow)
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("\(error)")
        self.loadingVC.remove()
        self.dismissWebViewController()
    }
}

// MARK: - Private action methods
private extension WebViewController {
    
    private func dismissAuthorization(decisionHandler: (WKNavigationActionPolicy) -> Void) {
        decisionHandler(.cancel)
        self.dismissWebViewController()
    }
    
    private func loadAddressURL() {
        guard let url = targetURL else {
            return
        }
        let req = URLRequest(url: url)
        DispatchQueue.main.async {
            self.add(self.loadingVC)
            self.webView.load(req)
        }
    }
}
