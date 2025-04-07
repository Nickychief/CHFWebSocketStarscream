//
//  UIView+Extension.swift
//  CHFWebSocketStarscream
//
//  Created by Nikcy on 9/14/23.
//

import UIKit

extension UIView {
    public enum UIViewSide {
        case top, bottom, left, right
    }
    
    func makeViewConstraints(toFitSuperView superView: UIView, edgeInsets: UIEdgeInsets = .zero) {
        
        self.translatesAutoresizingMaskIntoConstraints = false
        let constraints = [
            self.leadingAnchor.constraint(equalTo: superView.leadingAnchor, constant: edgeInsets.left),
            self.trailingAnchor.constraint(equalTo: superView.trailingAnchor, constant: edgeInsets.right),
            self.topAnchor.constraint(equalTo: superView.topAnchor, constant: edgeInsets.top),
            self.bottomAnchor.constraint(equalTo: superView.bottomAnchor, constant: edgeInsets.bottom)
        ]
        NSLayoutConstraint.activate(constraints)
    }
    
}
