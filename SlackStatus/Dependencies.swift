//
//  Dependencies.swift
//  SlackStatus
//
//  Created by Roman on 2/10/19.
//

import Foundation
import KeychainAccess

class Dependencies {

    let storageService: StorageServiceProtocol
    let userService: UserServiceProtocol

    private let keychain: KeychainStorage
    init() {
        self.keychain = Keychain(service: "SlackStatus")
        self.storageService = StorageService(keychainStorage: keychain)
        self.userService = UserService(storageService: storageService, apiClient: APIClient())
    }
}
