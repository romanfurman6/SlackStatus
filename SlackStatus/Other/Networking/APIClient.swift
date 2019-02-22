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

struct Emoji {
    let unified: String
    let shortName: String
    let available: Bool
}

extension Emoji: Decodable {

    enum CodingKeys: String, CodingKey {
        case unified = "unified"
        case shortName = "short_name"
        case available = "has_img_apple"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let unifiedString = try container.decode(String.self, forKey: .unified)

        let symbols = unifiedString.split(separator: "-")
        var string = ""
        for symbol in symbols {
            guard
                let uint32 = UInt32(symbol, radix: 16),
                let unidcode = UnicodeScalar(uint32)
            else { fatalError() }
            string += "\(unidcode)"
        }

        unified = string
        shortName = try container.decode(String.self, forKey: .shortName)
        available = try container.decode(Bool.self, forKey: .available)
    }
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
        let shortName = try nestedContainer
            .decode(String.self, forKey: .emoji)
            .replacingOccurrences(of: ":", with: "")
        emoji = slackToUnicode(with: shortName) ?? "🚫"
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
    return emojis.first(where: { $0.shortName == value && $0.available })?.unified
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
