//
//  Storage.swift
//  SlackStatus
//
//  Created by Roman on 2/10/19.
//

import Foundation
import KeychainAccess

protocol KeychainStorage {
    func clearStorage()
    subscript(data key: String) -> Data? { get set }
    subscript(string key: String) -> String? { get set }
}

extension Keychain: KeychainStorage {
    subscript(data key: String) -> Data? {
        get {
            do {
                let data = try self.getData(key)
                return data
            } catch let error {
                debug("\(error.localizedDescription)")
            }
            return nil
        }
        set {
            do {
                guard let data = newValue else { return }
                try self.set(data, key: key)
            } catch let error {
                debug("\(error.localizedDescription)")
            }
        }
    }

    subscript(string key: String) -> String? {
        get {
            do {
                let string = try self.getString(key)
                return string
            } catch let error {
                debug("\(error.localizedDescription)")
            }
            return nil
        }
        set {
            do {
                guard let string = newValue else { return }
                try self.set(string, key: key)
            } catch let error {
                debug("\(error.localizedDescription)")
            }
        }
    }

    func clearStorage() {
        do {
            try self.removeAll()
        } catch let error {
            debug("\(error.localizedDescription)")
        }
    }
}

