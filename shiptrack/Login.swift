//
//  Login.swift
//  shiptrack
//
//  Created by Nick DeRose on 12/6/23.
//

import Foundation
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
        
        let endpoint = "/api/auth/local"
        
        print("Local Base URL:", Bundle.main.object(forInfoDictionaryKey: "LocalBaseURL") as? String ?? "nil")
        print("Production Base URL:", Bundle.main.object(forInfoDictionaryKey: "ProductionBaseURL") as? String ?? "nil")

                
        // Determine the base URL based on the build configuration.
        let baseUrlString: String
        #if DEBUG
        baseUrlString = (Bundle.main.object(forInfoDictionaryKey: "LocalBaseURL") as? String) ?? ""
        #else
        baseUrlString = (Bundle.main.object(forInfoDictionaryKey: "ProductionBaseURL") as? String) ?? ""
        #endif

        // Combine the base URL with the endpoint to form the complete URL.
        guard let url = URL(string: baseUrlString + endpoint), !baseUrlString.isEmpty else {
            // Handle the error appropriately
            // e.g., log an error, show an alert, etc.
            return
        }
        
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

    //let logoURL = URL(string: "https://cloudship-xi.vercel.app/logo.png") // Replace with actual IP if testing on a real device

    var body: some View {
        VStack {
            Image("Logo").padding(.bottom, 20)
            
            VStack(alignment: .leading) {
                
                Text("Email")
                    .padding([.leading, .top], 10) // Add padding to align with TextField
                
                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .padding([.horizontal, .bottom], 10)
                
                Text("Password")
                    .padding([.leading, .top], 10) // Add padding to align with TextField
                
                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding([.horizontal, .bottom], 10)
                
                
                Button("Login") {
                    // Handle login action
                    loginUser()
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
                .background(Color.hex("0177CC"))
                .foregroundColor(.white)
                .font(.custom("Avenir", size: 20))
                .fontWeight(.bold)
                .cornerRadius(10) // Change this value for different corner radius sizes
                .padding(15)
                .padding(.top, 15)
                
            }
        }
        .padding(.horizontal)
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


