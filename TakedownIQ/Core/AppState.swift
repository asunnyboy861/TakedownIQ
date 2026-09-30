import Foundation
import Security

enum AppState {
    static let feedbackBackendURL = URL(string: "https://msg.calcs.top")!
    static let policyBaseURL = URL(string: "https://asunnyboy861.github.io/TakedownIQ")!

    static var deviceID: String {
        let service = "com.zzoutuo.TakedownIQ"
        let account = "device-id"
        if let existing = KeychainHelper.readString(service: service, account: account) {
            return existing
        }
        let id = UUID().uuidString
        KeychainHelper.saveString(id, service: service, account: account)
        return id
    }

    static var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "Version \(version) (\(build))"
    }
}

enum KeychainHelper {
    static func save(_ data: Data, service: String, account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
        var attributes = query
        attributes[kSecValueData as String] = data
        SecItemAdd(attributes as CFDictionary, nil)
    }

    static func read(service: String, account: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        SecItemCopyMatching(query as CFDictionary, &result)
        return result as? Data
    }

    static func delete(service: String, account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }

    static func saveString(_ value: String, service: String, account: String) {
        guard let data = value.data(using: .utf8) else { return }
        save(data, service: service, account: account)
    }

    static func readString(service: String, account: String) -> String? {
        guard let data = read(service: service, account: account) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
