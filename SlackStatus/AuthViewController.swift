//
//  AuthViewController.swift
//  SlackStatus
//
//  Created by Roman on 1/30/19.
//

import Cocoa
import AppKit
import WebKit

var tokenStore = ""

protocol AuthViewControllerDelegate: class {
    func authorized()
}

final class AuthViewController: NSViewController {

    private let apiClient = APIClient.shared

    @IBOutlet private weak var webview: WKWebView!
    @IBOutlet private weak var activityIndicator: NSProgressIndicator!

    weak var delegate: AuthViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        activityIndicator.isHidden = true
        activityIndicator.controlTint = .graphiteControlTint
        webview.navigationDelegate = self
        let readPerm = AppConstants.Slack.PermissionScope.profileRead + " "
        let writePerm = AppConstants.Slack.PermissionScope.profileUserWrite
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
        let request = URLRequest(url: urlComponents.url!)
        webview.load(request)
    }

    func authorize(with code: String) {
        webview.isHidden = true
        activityIndicator.isHidden = false
        activityIndicator.startAnimation(nil)
        apiClient.authorize(with: code) { (result) in
            switch result {
            case let .success(token):
                tokenStore = token.value
            case let .failure(message):
                print(message)
            }
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimation(nil)
                self.activityIndicator.isHidden = true
                self.delegate?.authorized()
            }
        }
    }


}

extension AuthViewController: WKNavigationDelegate {

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        let urlString = navigationAction.request.url?.absoluteString
        print(urlString)
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

extension AuthViewController {
    static func freshController() -> AuthViewController {
        let storyboard = NSStoryboard(name: "Main", bundle: Bundle.main)
        guard let viewController = storyboard.instantiateController(withIdentifier: "AuthViewController") as? AuthViewController else {
            fatalError()
        }
        return viewController
    }
}
