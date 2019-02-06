//
//  AuthViewController.swift
//  SlackStatus
//
//  Created by Roman on 1/30/19.
//

import Cocoa
import AppKit
import WebKit

class AuthViewController: NSViewController {

    @IBOutlet weak var webview: WKWebView!

    override func viewDidLoad() {
        super.viewDidLoad()
        webview.navigationDelegate = self
        let readPerm = AppConstants.Slack.PermissionScope.profileRead
        let writePerm = AppConstants.Slack.PermissionScope.profileUserWrite
        let clientID = AppConstants.Slack.clientID
        let base = AppConstants.Slack.URLs.base
        let redirect = AppConstants.Slack.authRedirect
        let request = URLRequest(url: URL(string: "\(base)/oauth/authorize?client_id=\(clientID)&scope=\(readPerm)%20\(writePerm)&redirect_uri=\(redirect)")!)
        webview.load(request)
    }

    let urlSession = URLSession.shared

    func authorize(with code: String) {
        let url = URL.init(string: "https://slack.com/api/oauth.access?code=\(code)&client_id=27006116208.539129783014&client_secret=7365bb8cd7734f5860010de51344c8a5&&redirect_uri=https%3A%2F%2Fexample.com")!
        let urlRequest = URLRequest.init(url: url)
        urlSession.dataTask(with: urlRequest) { (data, response, error) in
            let json = try! JSONSerialization.jsonObject(with: data!, options: .allowFragments)
            print(json)
//            print(data)
//            print(response)
//            print(error)
        }.resume()
    }

}

extension AuthViewController: WKNavigationDelegate {

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if
            let url = navigationAction.request.url?.absoluteString,
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
    // MARK: Storyboard instantiation
    static func freshController() -> AuthViewController {
        let storyboard = NSStoryboard(name: "Main", bundle: Bundle.main)
        guard let viewController = storyboard.instantiateController(withIdentifier: "ViewController") as? AuthViewController else {
            fatalError("Why cant i find QuotesViewController? - Check Main.storyboard")
        }
        return viewController
    }
}
