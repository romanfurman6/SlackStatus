//
//  NibInit.swift
//  SlackStatus
//
//  Created by Roman on 2/20/19.
//

import AppKit

protocol NibInit: class {
    static var nib: NSNib { get }
}

extension NibInit {
    static var nib: NSNib {
        return NSNib(nibNamed: NSNib.Name(describing: self), bundle: Bundle(for: self))!
        //(nibName: String(describing: self), bundle: )
    }

    static func initFromNIB() -> Self {
        var myArray: NSArray? = NSArray()
        if let isInstantiated = nib.instantiate(withOwner: self, topLevelObjects: &myArray) as? Bool, isInstantiated {
            return myArray?.first(where: { ($0 as? Self) != nil }) as! Self
        }
        fatalError("Could not instantiate view from nib")
    }
}

