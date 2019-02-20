//
//  MainViewController.swift
//  SlackStatus
//
//  Created by Roman on 2/6/19.
//

import AppKit

let array = [
    StatusView.Model(title: "first", emoji: "😭"),
    StatusView.Model(title: "second", emoji: "😭"),
    StatusView.Model(title: "third", emoji: "😭"),
    StatusView.Model(title: "fourth", emoji: "😭"),
    StatusView.Model(title: "fifth", emoji: "😭"),
    StatusView.Model(title: "sixth", emoji: "😭")
]

protocol MainViewControllerDelegate: class {
    func didFinish()
}

class MainViewController: NSViewController, MainStoryboardInit {

    @IBOutlet private weak var textField: NSTextField!
    @IBOutlet private weak var welcomeLabel: NSTextField!
    @IBOutlet private weak var activityIndicator: NSProgressIndicator!
    @IBOutlet private weak var saveButton: NSButton!
    @IBOutlet private weak var closeButton: NSButton!
    @IBOutlet private weak var leftStatusStackView: NSStackView!
    @IBOutlet private weak var rightStatusStackView: NSStackView!

    weak var delegate: MainViewControllerDelegate?

    private let storage: StorageServiceProtocol = dependencies.storageService
    private let userService: UserServiceProtocol = dependencies.userService

    private var profile: Profile?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupStackViews()
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        fetchProfile()
    }

    func setupStackViews() {
        array.enumerated().forEach { (offset, model) in
            let view = StatusView.initFromNIB()
            view.configure(with: model)
            if offset % 2 == 0 {
                leftStatusStackView.addArrangedSubview(view)
            } else {
                rightStatusStackView.addArrangedSubview(view)
            }
        }
    }

    @IBAction func closeButtonTapped(_ sender: Any) {
        delegate?.didFinish()
    }
    @IBAction func saveButtonTapped(_ sender: Any) {
        setStatus(with: textField.stringValue)
    }

    private func setStatus(with status: String) {
        isLoading(true)
        guard let profile = profile else { fatalError() }
        userService.updateProfile(with: profile) { [weak self] (result) in
            switch result {
            case let .success(profile):
                self?.handleProfile(profile)
            case let .failure(message):
                print("Error response: \(message)")
            }
            DispatchQueue.main.async {
                self?.delegate?.didFinish()
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
        self.profile = profile
        DispatchQueue.main.async {
            self.welcomeLabel.stringValue = "Hello, " + (profile.name)
            self.textField.stringValue = profile.status
        }
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
