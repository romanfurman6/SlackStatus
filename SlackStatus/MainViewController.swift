//
//  MainViewController.swift
//  SlackStatus
//
//  Created by Roman on 2/6/19.
//

import AppKit

class MainViewController: NSViewController {

    @IBOutlet weak var textField: NSTextField!
    @IBOutlet weak var welcomeLabel: NSTextField!

    private let apiClient = APIClient.shared


    @IBAction func saveButtonTapped(_ sender: Any) {

    }

    
}

extension MainViewController {
    // MARK: Storyboard instantiation
    static func freshController() -> MainViewController {
        let storyboard = NSStoryboard(name: "Main", bundle: Bundle.main)
        guard let viewController = storyboard.instantiateController(withIdentifier: "MainViewController") as? MainViewController else {
            fatalError()
        }
        return viewController
    }
}
