//
//  StoryboardInit.swift
//  SlackStatus
//
//  Created by Roman on 2/10/19.
//

import AppKit

protocol MainStoryboardInit {
    static var storyboardName: String { get }
    static func initFromStoryboard() -> Self
}

extension MainStoryboardInit where Self: NSViewController {
    static var storyboardName: String {
        return String(describing: "Main")
    }

    static func initFromStoryboard() -> Self {
        guard
            let viewController = NSStoryboard(name: "Main", bundle: Bundle.main).instantiateController(withIdentifier: "\(Self.self)") as? Self
            else {
                fatalError("Could not instantiate initial \(Self.self) from Main storyboard.")
        }

        return viewController
    }

}
