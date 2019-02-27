//
//  MainViewController.swift
//  SlackStatus
//
//  Created by Roman on 2/6/19.
//

import AppKit

let array = [
    StatusView.Model(title: "Home", emoji: "🏡"),
    StatusView.Model(title: "On the way", emoji: "🚙"),
    StatusView.Model(title: "Lunch", emoji: "🥪"),
    StatusView.Model(title: "Meeting", emoji: "🤙"),
    StatusView.Model(title: "Vacation", emoji: "🏖"),
    StatusView.Model(title: "Office", emoji: "🏢")
]

let doNotDisturbStatus = StatusView.Model(title: "Do not disturb", emoji: "🌚")

protocol MainViewControllerDelegate: class {
    func didFinish()
}

class MainViewController: NSViewController, MainStoryboardInit, NSTextFieldDelegate {

    @IBOutlet private weak var textField: NSTextField!
    @IBOutlet private weak var welcomeLabel: NSTextField!
    @IBOutlet private weak var activityIndicator: NSProgressIndicator!
    @IBOutlet private weak var saveButton: NSButton!
    @IBOutlet private weak var closeButton: NSButton!
    @IBOutlet private weak var leftStatusStackView: NSStackView!
    @IBOutlet private weak var rightStatusStackView: NSStackView!
    @IBOutlet private weak var emojiLabel: NSTextField!
    @IBOutlet private weak var emojiButton: NSButton!
    @IBOutlet private weak var fakeTextField: NSTextField!

    weak var delegate: MainViewControllerDelegate?

    private let storage: StorageServiceProtocol = dependencies.storageService
    private let userService: UserServiceProtocol = dependencies.userService
    private var profile: Profile?
    private var isIgnoringDND = true
    private var lastSavedProfile: Profile?
    private var isLoadingState = false

    override func viewDidLoad() {
        super.viewDidLoad()
        setupDNDObserve()
        setupStackViews()
        setupEmojisPicker()
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        fetchProfile()
    }

    @IBAction func quitButton(_ sender: Any) {
        exit(0)
    }

    @IBAction func closeButtonTapped(_ sender: Any) {
        delegate?.didFinish()
    }

    @IBAction func saveButtonTapped(_ sender: Any) {
        setStatus(with: textField.stringValue, and: emojiLabel.stringValue)
    }

    @objc func buttonPressed(button: NSButton) {
        let item = array[button.tag]
        textField.stringValue = item.title
        emojiLabel.stringValue = item.emoji
    }

    private func handleProfile(_ profile: Profile) {
        self.profile = profile
        if profile.status != doNotDisturbStatus.title {
            self.lastSavedProfile = profile
        }
        DispatchQueue.main.async {
            self.welcomeLabel.stringValue = "Hey " + (profile.name)
            self.textField.stringValue = profile.status
            self.emojiLabel.stringValue = profile.emoji
        }
        storage.storeObject(profile, for: AppConstants.Keychain.profile)
    }

    private func isLoading(_ value: Bool) {
        isLoadingState = value
        activityIndicator.isHidden = !value
        saveButton.isEnabled = !value
        if value {
            activityIndicator.startAnimation(nil)
        } else {
            activityIndicator.stopAnimation(nil)
        }
    }

    private func setupStackViews() {
        array.enumerated().forEach { (offset, model) in
            let view = StatusView.initFromNIB()
            view.configure(with: model)
            if offset % 2 == 0 {
                leftStatusStackView.addArrangedSubview(view)
            } else {
                rightStatusStackView.addArrangedSubview(view)
            }
            view.button.tag = offset
            view.button.action = #selector(buttonPressed(button:))
        }
    }

    // MARK: Networking

    private func setStatus(with status: String, and emoji: String, shouldSave: Bool = true) {
        isLoading(true)
        profile?.status = status
        profile?.emoji = emoji
        profile?.expiration = 0
        guard let profile = profile else { fatalError() }
        if shouldSave { self.lastSavedProfile = profile }
        userService.updateProfile(with: profile) { [weak self] (result) in
            switch result {
            case let .success(profile):
                self?.handleProfile(profile)
            case let .failure(message):
                debug("Error response: \(message)")
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
                debug("Error response: \(message)")
            }
            DispatchQueue.main.async {
                self?.isLoading(false)
            }
        }
    }

    // MARK: Emojis

    private func setupEmojisPicker() {
        fakeTextField.delegate = self
        fakeTextField.alphaValue = 0
        emojiButton.action = #selector(emojiButtonPressed(button:))
        emojiLabel.usesSingleLineMode = true
        emojiLabel.alignment = NSTextAlignment.center
    }

    func controlTextDidChange(_ obj: Notification) {
        let object = obj.object as! NSTextField
        let value = object.stringValue
        emojiLabel.stringValue = value
        fakeTextField.window?.makeFirstResponder(nil)
        fakeTextField.stringValue = ""
    }

    @objc private func emojiButtonPressed(button: NSButton) {
        textField.window?.makeFirstResponder(nil)
        fakeTextField.stringValue = " "
        fakeTextField.becomeFirstResponder()
        openEmojiPicker()
    }

    // MARK: DND

    private let notificationEnabled = NSNotification.Name("_NSDoNotDisturbEnabledNotification")
    private let notificationDisabled = NSNotification.Name("_NSDoNotDisturbDisabledNotification")
    private var dndTask: DispatchWorkItem?

    @IBAction private func ignoreDNDTaps(_ sender: Any) {
        isIgnoringDND = !isIgnoringDND
    }

    @objc private func handleDND(_ notification: NSNotification) {
        if isIgnoringDND || isLoadingState { return }

        let enabled: Bool
        switch notification.name {
        case self.notificationEnabled:
            enabled = true
        case self.notificationDisabled:
            enabled = false
        default: fatalError()
        }

        self.dndTask?.cancel()

        let task = DispatchWorkItem(block: { [weak self] in
            print(notification)
            self?.dndStatus(with: enabled)
        })

        self.dndTask = task

        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.75, execute: task)
    }

    private func setupDNDObserve() {
        DistributedNotificationCenter.default().addObserver(self, selector: #selector(handleDND(_:)), name: notificationEnabled, object: nil)
        DistributedNotificationCenter.default().addObserver(self, selector: #selector(handleDND(_:)), name: notificationDisabled, object: nil)
    }

    private func dndStatus(with enabled: Bool) {
        if !enabled && lastSavedProfile == nil { return }

        let status = enabled ? doNotDisturbStatus.title : lastSavedProfile!.status
        let emoji = enabled ? doNotDisturbStatus.emoji : lastSavedProfile!.emoji

        setStatus(with: status, and: emoji, shouldSave: false)
    }
}

private func openEmojiPicker() {
    let commandControlMask = (CGEventFlags.maskCommand.rawValue | CGEventFlags.maskControl.rawValue)
    let commandControlMaskFlags = CGEventFlags(rawValue: commandControlMask)
    let space = CGEventSource(stateID: .hidSystemState)
    let keyDown = CGEvent(keyboardEventSource: space, virtualKey: 49 as CGKeyCode, keyDown: true)
    keyDown?.flags = commandControlMaskFlags
    keyDown?.post(tap: .cghidEventTap)
    let keyUp = CGEvent(keyboardEventSource: space, virtualKey: 49 as CGKeyCode, keyDown: false)
    keyUp?.flags = commandControlMaskFlags
    keyUp?.post(tap: .cghidEventTap)
}
