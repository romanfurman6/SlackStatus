//
//  APIClient.swift
//  SlackStatus
//
//  Created by Roman on 2/6/19.
//

import Foundation

struct Token {
    let value: String
}

extension Token: Decodable {
    enum CodingKeys: String, CodingKey {
        case value = "access_token"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        value = try container.decode(String.self, forKey: .value)
    }
}

struct Profile {
    let name: String
    var status: String
}

extension Profile: Codable {
    enum CodingKeys: String, CodingKey {
        case profile
        case name = "display_name"
        case status = "status_text"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let response = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .profile)
        name = try response.decode(String.self, forKey: .name)
        status = try response.decode(String.self, forKey: .status)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(status, forKey: .status)
    }

}

enum Result<Value> {
    case success(Value)
    case failure(String)
}

class APIClient {
    static let shared = APIClient()

    typealias CodeResult = Result<String>
    typealias TokenResult = Result<Token>
    typealias ProfileResult = Result<Profile>

    private let urlSession = URLSession.shared

    func authorize(with code: String, handler: @escaping (TokenResult) -> Void) {

        let clientSecret = AppConstants.Slack.clientSecret
        let clientID = AppConstants.Slack.clientID
        let base = AppConstants.Slack.URLs.base
        let redirect = AppConstants.Slack.authRedirect
        let url = URL(string: "\(base)/api/oauth.access?code=\(code)&client_id=\(clientID)&client_secret=\(clientSecret)&redirect_uri=\(redirect)")!
        let decoder = JSONDecoder()
        urlSession.dataTask(with: url) { (data, _, error) in
            if let error = error {
                handler(.failure(error.localizedDescription))
            } else if let data = data, let token = try? decoder.decode(Token.self, from: data) {
                handler(.success(token))
            } else {
                handler(.failure("Unknown error while \(#function)"))
            }
        }.resume()
    }

    func fetchProfile(handler: @escaping (ProfileResult) -> Void) {
        let url = URL(string: "https://slack.com/api/users.profile.get")!
        let decoder = JSONDecoder()
        urlSession.dataTask(with: url) { (data, _, error) in
            if let error = error {
                handler(.failure(error.localizedDescription))
            } else if let data = data, let profile = try? decoder.decode(Profile.self, from: data) {
                handler(.success(profile))
            } else {
                handler(.failure("Unknown error while \(#function)"))
            }
        }.resume()
    }

    func setStatus(with status: String, handler: () -> Void) {

    }

}
