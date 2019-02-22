//
//  AppDelegate.swift
//  SlackStatus
//
//  Created by Roman on 1/30/19.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    let statusItem = NSStatusBar.system.statusItem(withLength:NSStatusItem.squareLength)
    let popover = NSPopover()

    let authVC = AuthViewController.initFromStoryboard()
    let mainVC = MainViewController.initFromStoryboard()

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        if let button = statusItem.button {
            let image = NSImage(named: NSImage.Name("slack"))
            button.image = image
            button.action = #selector(togglePopover(_:))
        }
        authVC.delegate = self
        popover.behavior = NSPopover.Behavior.transient
        mainVC.delegate = self

        if (dependencies.storageService.getObject(at: AppConstants.Keychain.token) as Auth?) != nil {
            popover.contentViewController = mainVC
        } else {
            popover.contentViewController = authVC
        }

    }

    @objc func togglePopover(_ sender: Any?) {
        if popover.isShown {
            closePopover(sender: sender)
        } else {
            showPopover(sender: sender)
        }
    }

    func showPopover(sender: Any?) {
        if let button = statusItem.button {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
        }
    }

    func closePopover(sender: Any?) {
        popover.performClose(sender)
    }
}

extension AppDelegate: AuthViewControllerDelegate {
    func authorized() {
        popover.contentViewController = mainVC
    }
}

extension AppDelegate: MainViewControllerDelegate {
    func didFinish() {
        closePopover(sender: nil)
    }
}

let dependencies = Dependencies()
var emojis: [Emoji] = {
    let decoder = JSONDecoder()
    if let path = Bundle.main.path(forResource: "slack_to_unicode", ofType: "json") {
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
            return try decoder.decode([Emoji].self, from: data)
        } catch let error {
            debug(error)
        }
    }
    return []
}()

func debug(_ value: Any) {
    #if DEBUG
        print("🤙 Debug: \(value)")
    #endif
}
