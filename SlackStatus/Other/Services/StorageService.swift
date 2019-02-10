//
//  StorageService.swift
//  SlackStatus
//
//  Created by Roman on 2/10/19.
//

import Foundation

protocol StorageServiceProtocol {
    func clearKeychainStorage()
    func getObject<T: Codable>(at key: String) -> T?
    func storeObject<T: Codable>(_ object: T, for key: String)
}

class StorageService: StorageServiceProtocol {

    private var keychainStorage: KeychainStorage

    init(
        keychainStorage: KeychainStorage
        ) {
        self.keychainStorage = keychainStorage
    }

    func clearKeychainStorage() {
        keychainStorage.clearStorage()
    }

    func getObject<T: Codable>(at key: String) -> T? {
        guard let data = keychainStorage[data: key] else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    func storeObject<T: Codable>(_ object: T, for key: String) {
        let data = ((try? JSONEncoder().encode(object)) ?? Data())
        self.keychainStorage[data: key] = data
    }
}

