//
//  ApiTarget.swift
//  SlackStatus
//
//  Created by Roman on 2/10/19.
//

import Foundation

enum ApiTarget {
    case authorize(code: String)
    case fetchProfile
    case updateProfile
}

extension ApiTarget {
    var url: URL {
        switch self {
        case let .authorize(code):
            let clientSecret = AppConstants.Slack.clientSecret
            let clientID = AppConstants.Slack.clientID
            let base = AppConstants.Slack.URLs.base
            let redirect = AppConstants.Slack.authRedirect
            return URL(string: "\(base)/api/oauth.access?code=\(code)&client_id=\(clientID)&client_secret=\(clientSecret)&redirect_uri=\(redirect)")!
        case .fetchProfile:
            return URL(string: "https://slack.com/api/users.profile.get")!
        case .updateProfile:
            return URL(string: "https://slack.com/api/users.profile.set")!
        }
    }
}
