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
            button.action = #selector(togglePopover(_:))
        }
        authVC.delegate = self
        mainVC.delegate = self
        if let token: Auth = dependencies.storageService.getObject(at: AppConstants.Keychain.token) {
            print(token)
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
    func settedProfile() {
        closePopover(sender: nil)
    }
}

let dependencies = Dependencies()
