//
//  AuthViewController.swift
//  SlackStatus
//
//  Created by Roman on 1/30/19.
//

import Cocoa
import AppKit
import WebKit

protocol AuthViewControllerDelegate: class {
    func authorized()
}

final class AuthViewController: NSViewController, MainStoryboardInit {

    private let storageService = dependencies.storageService
    private let userService = dependencies.userService
    private let initialRequest = createInitialRequesrt()

    @IBOutlet private weak var webview: WKWebView!
    @IBOutlet private weak var activityIndicator: NSProgressIndicator!

    weak var delegate: AuthViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        activityIndicator.isHidden = true
        activityIndicator.controlTint = .graphiteControlTint
        webview.navigationDelegate = self
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        webview.load(initialRequest)
    }


    private func authorize(with code: String) {
        webview.isHidden = true
        activityIndicator.isHidden = false
        activityIndicator.startAnimation(nil)
        userService.authorize(with: code) { [weak self] (result) in
            switch result {
            case let .success(auth):
                self?.storageService.storeObject(auth, for: AppConstants.Keychain.token)
            case let .failure(message):
                print(message)
            }
            DispatchQueue.main.async {
                self?.activityIndicator.stopAnimation(nil)
                self?.activityIndicator.isHidden = true
                self?.delegate?.authorized()
            }
        }
    }


}

extension AuthViewController: WKNavigationDelegate {

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        let urlString = navigationAction.request.url?.absoluteString
        if
            let url = urlString,
            url.contains("code="),
            let code = url.components(separatedBy: "code=")[1].components(separatedBy: "&").first
        {
            authorize(with: code)
            decisionHandler(.cancel)
            return
        }
        decisionHandler(.allow)
    }

}

private func createInitialRequesrt() -> URLRequest {
    let readPerm = AppConstants.Slack.PermissionScope.Profile.read + " "
    let writePerm = AppConstants.Slack.PermissionScope.Profile.write
    let clientID = AppConstants.Slack.clientID
    let redirect = AppConstants.Slack.authRedirect
    let host = AppConstants.Slack.URLs.host
    let scheme = AppConstants.Slack.URLs.scheme
    var urlComponents = URLComponents()
    urlComponents.scheme = scheme
    urlComponents.host = host
    urlComponents.path = "/oauth/authorize"
    urlComponents.queryItems = [
        URLQueryItem(name: "client_id", value: "\(clientID)"),
        URLQueryItem(name: "scope", value: "\(readPerm) \(writePerm)"),
        URLQueryItem(name: "redirect_uri", value: "\(redirect)")
    ]
    return URLRequest(url: urlComponents.url!)
}
