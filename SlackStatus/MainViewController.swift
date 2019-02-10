//
//  MainViewController.swift
//  SlackStatus
//
//  Created by Roman on 2/6/19.
//

import AppKit

protocol MainViewControllerDelegate: class {
    func settedProfile()
}

class MainViewController: NSViewController, MainStoryboardInit {

    @IBOutlet weak var textField: NSTextField!
    @IBOutlet weak var welcomeLabel: NSTextField!
    @IBOutlet weak var activityIndicator: NSProgressIndicator!
    @IBOutlet weak var saveButton: NSButton!

    weak var delegate: MainViewControllerDelegate?

    private let storage: StorageServiceProtocol = dependencies.storageService
    private var profile: Profile?
    private let userService: UserServiceProtocol = dependencies.userService

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        fetchProfile()
    }


    @IBAction func saveButtonTapped(_ sender: Any) {
        setStatus(with: textField.stringValue)
    }

    private func setStatus(with status: String) {
        isLoading(true)
        profile?.status = status
        guard let profile = profile else { fatalError() }
        userService.updateProfile(with: profile) { [weak self] (result) in
            switch result {
            case let .success(profile):
                self?.handleProfile(profile)
            case let .failure(message):
                print("Error response: \(message)")
            }
            DispatchQueue.main.async {
                self?.delegate?.settedProfile()
                self?.isLoading(false)
            }
        }
    }

    private func fetchProfile() {
        isLoading(true)
        userService.fetchProfile() { [weak self] (result) in
            switch result {
            case let .success(profile):
                self?.handleProfile(profile)
            case let .failure(message):
                print("Error response: \(message)")
            }
            DispatchQueue.main.async {
                self?.isLoading(false)
            }
        }
    }

    private func handleProfile(_ profile: Profile) {
        welcomeLabel.stringValue = "Hello, " + (profile.name)
        textField.stringValue = profile.status
        storage.storeObject(profile, for: AppConstants.Keychain.profile)
    }

    private func isLoading(_ value: Bool) {
        activityIndicator.isHidden = !value
        saveButton.isEnabled = !value
        if value {
            activityIndicator.startAnimation(nil)

        } else {
            activityIndicator.stopAnimation(nil)
        }
    }
    
}
