/*
 MIT License

Copyright (c) 2021 Maik Müller (maikdrop) <maik_mueller@me.com>

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 
 Abstract:
 The view controller shows a spinning indicator in the center of a blurred effect view in the center of the main view.
 */

import UIKit

class LoadingViewController: UIViewController {
    
    deinit { print("DEINIT - LoadingViewController") }
   
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let spinner = configureSpinner()
        spinner.startAnimating()
        
        let effectView = configureEffectView()
        effectView.contentView.addSubview(spinner)
        view.addSubview(effectView)
        
        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: effectView.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: effectView.centerYAnchor)
        ])
    }
    
    /**
     Configures a large activity indicator.
     
     Returns: The configured activity indicator.
     */
    private func configureSpinner() -> UIActivityIndicatorView {
        
        let spinner = UIActivityIndicatorView(style: .large)
        spinner.color = .label
        spinner.translatesAutoresizingMaskIntoConstraints = false
        
        return spinner
    }
    
    /**
     Configures a blurred effect view in the center of the main view.
     
     Returns: The configured effect view.
     */
    private func configureEffectView() -> UIVisualEffectView {
        
        let effectView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
        effectView.frame = CGRect(x: 0, y: 0, width: Effect.size.width, height: Effect.size.height)
        effectView.center = view.center
        effectView.layer.cornerRadius = Effect.cornerRadius
        effectView.layer.masksToBounds = true
        
        return effectView
    }
}

// MARK: - Constants
private extension LoadingViewController {
    
    private struct Effect {
        static var size: CGSize { CGSize(width: 80, height: 80) }
        static var cornerRadius: CGFloat { 15 }
    }
}
