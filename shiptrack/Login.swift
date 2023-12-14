//
//  Login.swift
//  shiptrack
//
//  Created by Nick DeRose on 12/6/23.
//

import Foundation
//import FirebaseAuth

import SwiftUI
import Security

struct AuthData: Codable {
    var token: String
    var email: String
}


class KeychainService {
    static let shared = KeychainService()
    private let account = "shipTrackAuthAccount" // A constant to identify your app's auth data in Keychain

    func save(authData: AuthData) {
        if let data = try? JSONEncoder().encode(authData) {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: account,
                kSecValueData as String: data
            ]

            SecItemDelete(query as CFDictionary) // Remove any existing item
            SecItemAdd(query as CFDictionary, nil)
        }
    }

    func retrieveAuthData() -> AuthData? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)

        if status == noErr, let data = dataTypeRef as? Data, let authData = try? JSONDecoder().decode(AuthData.self, from: data) {
            return authData
        }

        return nil
    }
}



class StrapiAuthService {
    func login(email: String, password: String, completion: @escaping (Bool, Error?) -> Void) {
        let url = URL(string: "http://localhost:1337/api/auth/local")! // Replace with your Strapi URL
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "identifier": email,
            "password": password
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(false, error)
                return
            }

            guard let data = data else {
                completion(false, NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data in response"]))
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let jwt = json["jwt"] as? String {
                    let authData = AuthData(token: jwt, email: email)
                    KeychainService.shared.save(authData: authData)
                    completion(true, nil)
                } else {
                    let rawResponse = String(data: data, encoding: .utf8) ?? "Unable to decode response"
                    print("Received non-JSON response: \(rawResponse)")
                    completion(false, NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response format"]))
                }
            } catch let jsonError {
                let rawResponse = String(data: data, encoding: .utf8) ?? "Unable to decode response"
                print("JSON decode error: \(jsonError), Response: \(rawResponse)")
                completion(false, jsonError)
            }
        }

        task.resume()
    }
}




struct LoginView: View {
    @Binding var isAuthenticated: Bool
    @State private var email = ""
    @State private var password = ""

    var body: some View {
        VStack {
            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
                .padding()

            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            Button("Login") {
                // Handle login action
                loginUser()
            }
            .padding()
        }
        .padding()
    }
    /*
    private func loginUser() {
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            if let error = error {
                print("Login error: \(error.localizedDescription)")
                print(error)
                    return
            } else if let authResult = authResult {
                print("Successfully logged in user: \(authResult.user.email ?? "")")
                DispatchQueue.main.async {
                    self.isAuthenticated = true
                }
            }
        }
    }*/
    private func loginUser() {
        let authService = StrapiAuthService()
        authService.login(email: email, password: password) { success, error in
            DispatchQueue.main.async {
                if success {
                    self.isAuthenticated = true
                } else {
                    print("Login error: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
        }
    }

}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        // Create a dummy binding for the preview
        LoginView(isAuthenticated: .constant(false))
    }
}


