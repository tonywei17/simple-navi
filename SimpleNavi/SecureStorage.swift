import Foundation
import CryptoKit
import Security

final class SecureStorage {
    static let shared = SecureStorage()
    private init() {}

    private let keychainService = "com.simplenavi.simplenavi.securekey"
    private let keychainAccount = "encryption-key"
    private let userDefaults = UserDefaults.standard
    private let queue = DispatchQueue(label: "SecureStorageQueue")

    // MARK: - Public API
    func setString(_ value: String?, forKey key: String) {
        queue.sync {
            guard let value, !value.isEmpty else {
                userDefaults.removeObject(forKey: key)
                return
            }
            do {
                let enc = try encrypt(Data(value.utf8))
                userDefaults.set(enc.base64EncodedString(), forKey: key)
            } catch {
                // 失败时不保存密文，避免写入无效数据
                print("[SecureStorage] Encrypt failed: \(error)")
            }
        }
    }

    func getString(forKey key: String) -> String? {
        return queue.sync {
            guard let b64 = userDefaults.string(forKey: key), let data = Data(base64Encoded: b64) else {
                return nil
            }
            do {
                let dec = try decrypt(data)
                return String(data: dec, encoding: .utf8)
            } catch {
                print("[SecureStorage] Decrypt failed: \(error)")
                return nil
            }
        }
    }

    func remove(forKey key: String) {
        queue.sync {
            userDefaults.removeObject(forKey: key)
        }
    }

    // MARK: - Crypto
    private func encrypt(_ plaintext: Data) throws -> Data {
        let key = try loadOrCreateKey()
        let sealed = try AES.GCM.seal(plaintext, using: key)
        guard let combined = sealed.combined else {
            throw NSError(domain: "SecureStorage", code: -1, userInfo: [NSLocalizedDescriptionKey: "Combined cipher generation failed"]) 
        }
        return combined
    }

    private func decrypt(_ combined: Data) throws -> Data {
        let key = try loadOrCreateKey()
        let box = try AES.GCM.SealedBox(combined: combined)
        return try AES.GCM.open(box, using: key)
    }

    // MARK: - Keychain
    private func loadOrCreateKey() throws -> SymmetricKey {
        if let keyData = try? readKeyFromKeychain() {
            return SymmetricKey(data: keyData)
        }
        // 生成并保存
        let newKey = SymmetricKey(size: .bits256)
        let raw = newKey.withUnsafeBytes { Data($0) }
        try saveKeyToKeychain(raw)
        return newKey
    }

    private func readKeyFromKeychain() throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecSuccess {
            return result as? Data
        } else if status == errSecItemNotFound {
            return nil
        } else {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(status), userInfo: nil)
        }
    }

    private func saveKeyToKeychain(_ data: Data) throws {
        // 删除旧的（如存在）
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
            kSecValueData as String: data
        ]
        let status = SecItemAdd(addQuery as CFDictionary, nil)
        if status != errSecSuccess {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(status), userInfo: nil)
        }
    }
}
