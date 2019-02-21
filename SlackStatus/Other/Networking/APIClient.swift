//
//  APIClient.swift
//  SlackStatus
//
//  Created by Roman on 2/6/19.
//

import Foundation

struct Auth {
    let accessToken: String
}

extension Auth: Codable {
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        accessToken = try container.decode(String.self, forKey: .accessToken)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(accessToken, forKey: .accessToken)
    }
}

struct Profile {
    let name: String
    var emoji: String
    var status: String
    var expiration: Int
}

extension Profile: Codable {
    enum CodingKeys: String, CodingKey {
        case profile
        case name = "display_name"
        case status = "status_text"
        case emoji = "status_emoji"
        case expiration = "status_expiration"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let nestedContainer = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .profile)
        name = try nestedContainer.decode(String.self, forKey: .name)
        status = try nestedContainer.decode(String.self, forKey: .status)
        emoji = slackToUnicode(with: try nestedContainer.decode(String.self, forKey: .emoji)) ?? "🚫"
        expiration = try nestedContainer.decode(Int.self, forKey: .expiration)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        var nestedContainer = container.nestedContainer(keyedBy: CodingKeys.self, forKey: .profile)
        try nestedContainer.encode(name, forKey: .name)
        try nestedContainer.encode(status, forKey: .status)
        try nestedContainer.encode(emoji, forKey: .emoji)
        try nestedContainer.encode(expiration, forKey: .expiration)
    }

}

private func slackToUnicode(with value: String) -> String? {

    if let path = Bundle.main.path(forResource: "slack_to_unicode", ofType: "json") {
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .alwaysMapped)
            let json = try JSONSerialization.jsonObject(with: data, options: [])
            let dictionary = json as! [String: String]
            guard
                let emojiUnicode = dictionary[value],
                let charCode = UInt32(emojiUnicode, radix: 16),
                let unicode = UnicodeScalar(charCode)
            else { return nil }

            return String(unicode)
        } catch let error {
            print(error.localizedDescription)
        }
    }
    return nil
}

protocol APIClientProtocol {
    func request<T: Codable>(wirh request: URLRequest, handler: @escaping (Result<T>) -> Void)
}

class APIClient: APIClientProtocol {

    enum Result<Value> {
        case success(Value)
        case failure(String)
    }

    private let urlSession = URLSession.shared

    func request<T: Codable>(wirh request: URLRequest, handler: @escaping (Result<T>) -> Void) {
        let decoder = JSONDecoder()
        urlSession.dataTask(with: request) { (data, _, error) in
            if let error = error {
                handler(.failure(error.localizedDescription))
            } else if let data = data {
                if let profile = try? decoder.decode(T.self, from: data) {
                    handler(.success(profile))
                } else if let json = try? JSONSerialization.jsonObject(with: data, options: []) {
                    handler(.failure("Mapping error while \(#function) \(json)"))
                }
            } else {
                handler(.failure("Unknown error while \(#function)"))
            }
            }.resume()
    }
}
