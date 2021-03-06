/*
 MIT License
 
 Copyright (c) 2021 Maik Müller (maikdrop) <maik_mueller@me.com>
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

import UIKit

extension UIViewController {
    
    /**
     Presents an alert when the user wants to logout.
     
     - Parameter title: The title of the alert.
     - Parameter message: The message of the alert.
     - Parameter actionHandler: Handles the logout action.
     */
    func logoutAlert(title: String?, message: String?, actionHandler: @escaping () -> Void) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let logoutAction = UIAlertAction(title: AppStrings.Alert.logoutBtn, style: .destructive, handler: { _ in actionHandler() })
        let cancelAction = UIAlertAction(title: AppStrings.Alert.cancelBtn, style: .cancel)
        alertController.addAction(cancelAction)
        alertController.addAction(logoutAction)
        present(alertController, animated: true, completion: nil)
    }
    
    /**
     Presents an error alert.
     
     - Parameter title: The title of the alert.
     - Parameter message: The message of the alert.
     */
    func infoAlertWithRetryAction(title: String?, message: String?, retryActionHandler:  @escaping () -> Void) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: AppStrings.Alert.cancelBtn, style: .cancel)
        let retryAction = UIAlertAction(title: AppStrings.Alert.retryBtn, style: .default, handler: { _ in retryActionHandler() })
        alertController.addAction(okAction)
        alertController.addAction(retryAction)
        present(alertController, animated: true, completion: nil)
    }
    
    /**
     Presents an info alert.
     
     - Parameter title: The title of the alert.
     - Parameter message: The message of the alert.
     */
    func infoAlert(title: String?, message: String?) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: AppStrings.Alert.okBtn, style: .default)
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }
    
    /**
     Presents an info alert with a link to the app settings.
     
     - Parameter title: The title of the alert.
     - Parameter message: The message of the alert.
     */
    func infoAlertWithLinkToSettings(title: String?, message: String?) {
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let settingsAction = UIAlertAction(title: AppStrings.Alert.settingsBtn, style: .default) { _ in
            
            guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                return
            }
    
            if UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl)
            }
        }
        let okAction = UIAlertAction(title: AppStrings.Alert.okBtn, style: .default)
        alertController.addAction(settingsAction)
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }
}
