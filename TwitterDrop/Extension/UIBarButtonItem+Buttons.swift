/*
 MIT License

Copyright (c) 2021 Maik Müller (maikdrop) <maik_mueller@me.com>

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

import UIKit

extension UIBarButtonItem {
    
    /**
     A search button.
     */
    static var searchBtn: UIBarButtonItem {
        
        let largeConfig = UIImage.SymbolConfiguration(scale: .large)
        
        let image = UIImage(systemName: AppStrings.SystemImages.magnifyingGlass, withConfiguration: largeConfig)

        return UIBarButtonItem(image: image, style: .plain, target: nil, action: nil)
    }
    
    /**
     Creates a logout button.
     
     - Parameter image: The image of the button.
     - Parameter size: The size of the button image.
     
     - Returns: The created logout button.
     
     If you want to add a target action, cast the "customView" property of the logout button as UIButton.
     */
    static func makeLogoutButton(with image: UIImage, size: CGSize) -> UIBarButtonItem? {
        
        if let resizedImage = image.resizeImage(for: size) {
           
            let button = UIButton()
            button.setImage(resizedImage, for: .normal)
            
            let barButton = UIBarButtonItem(customView: button)
            barButton.tintColor = .white
            barButton.customView?.layer.cornerRadius = resizedImage.size.height / 2
            barButton.customView?.clipsToBounds = true
            
            return barButton
        }
        return nil
    }
}
