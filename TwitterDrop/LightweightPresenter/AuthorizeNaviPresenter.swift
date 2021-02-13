//
//  AuthorizeNaviPresenter.swift
//  TwitterDrop
//
//  Created by Maik on 09.02.21.
//

import Foundation
import UIKit

// source: www.swiftbysundell.com/articles/lightweight-presenters-in-swift/
struct AuthorizeNaviPresenter {
    
    typealias Authorize = AppStrings.Authorize
    
    // MARK: - Public API
    /**
     Presents a highscore list.
     
     - Parameter viewController: The presenting view controller.
     */
    func present(in viewController: UIViewController) {

        let storyboard = UIStoryboard(name: Authorize.storyboardName, bundle: nil)
        
        if let authorizeVC = storyboard.instantiateViewController(withIdentifier: Authorize.identifier) as? AuthorizeViewController {
            authorizeVC.modalTransitionStyle = .coverVertical
            authorizeVC.modalPresentationStyle = .fullScreen
            viewController.present(authorizeVC, animated: true)
        }
    }
}
