//
//  UIViewController+ContentViewController.swift
//  TwitterDrop
//
//  Created by Maik on 10.02.21.
//

import UIKit

extension UIViewController {
    
    var contentViewController: UIViewController {
        
        if let visibleVC = (self as? UINavigationController)?.visibleViewController {
            return visibleVC
        } else {
            return self
        }
    }
}
