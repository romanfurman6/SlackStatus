//
//  UserService.swift
//  SlackStatus
//
//  Created by Roman on 2/10/19.
//

import Foundation

typealias Result = APIClient.Result

protocol UserServiceProtocol {
    func authorize(with code: String, handler: @escaping (Result<Auth>) -> Void)
    func fetchProfile(handler: @escaping (Result<Profile>) -> Void)
    func updateProfile(with profile: Profile, handler: @escaping (Result<Profile>) -> Void)
}

class UserService: UserServiceProtocol {

    private let storageService: StorageServiceProtocol
    private let apiClient: APIClientProtocol

    init(storageService: StorageServiceProtocol, apiClient: APIClientProtocol) {
        self.storageService = storageService
        self.apiClient = apiClient
    }

    func authorize(with code: String, handler: @escaping (Result<Auth>) -> Void) {

        let target = ApiTarget.authorize(code: code)
        let url = target.url
        let request = URLRequest(url: url)

        apiClient.request(wirh: request, handler: handler)
    }

    func fetchProfile(handler: @escaping (Result<Profile>) -> Void) {
        let target = ApiTarget.fetchProfile
        let url = target.url
        var request = URLRequest(url: url)
        guard
            let token: Auth = storageService.getObject(at: AppConstants.Keychain.token)
        else {
            handler(.failure("Weird token"))
            return
        }
        request.setValue("Bearer \(token.accessToken)", forHTTPHeaderField: "Authorization")
        apiClient.request(wirh: request, handler: handler)
    }

    func updateProfile(with updatedProfile: Profile, handler: @escaping (Result<Profile>) -> Void) {
        let target = ApiTarget.updateProfile
        let url = target.url
        var request = URLRequest(url: url)
        let encoder = JSONEncoder()
        guard
            let token: Auth = storageService.getObject(at: AppConstants.Keychain.token)
        else {
            handler(.failure("Weird token"))
            return
        }
        request.setValue("Bearer \(token.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.httpBody = try! encoder.encode(updatedProfile)

        apiClient.request(wirh: request, handler: handler)
    }
}
