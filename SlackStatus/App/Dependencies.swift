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

    init() {
        let keychain = Keychain(service: "SlackStatus")
        self.storageService = StorageService(keychainStorage: keychain)

        let apiClient = APIClient()
        self.userService = UserService(storageService: storageService, apiClient: apiClient)
    }
}
