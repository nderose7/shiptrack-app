//
//  NetworkManager.swift
//  shiptrack
//
//  Created by Nick DeRose on 12/12/23.
//

import Foundation

class NetworkManager {
    static let shared = NetworkManager()

    func getShippingOptions(shipment: Shipment, completion: @escaping (Result<[ShippingOption], Error>) -> Void) {
        guard let authData = KeychainService.shared.retrieveAuthData() else {
            // If authentication data is not found, return an error using Result.failure
            completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Authentication data not found"])))
            return
        }
        
        let url = URL(string: "http://localhost:1337/api/shipments")! // Replace with your API URL
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(authData.token)", forHTTPHeaderField: "Authorization")

        do {
            request.httpBody = try JSONEncoder().encode(shipment)
        } catch {
            completion(.failure(error))
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            if let httpResponse = response as? HTTPURLResponse {
                print("Response HTTP Status code: \(httpResponse.statusCode)")
            }

            guard let data = data else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: nil)))
                return
            }

            // Log the raw response data as a string
            if let rawResponse = String(data: data, encoding: .utf8) {
                print("Raw server response: \(rawResponse)")
            }

            do {
                let response = try JSONDecoder().decode(ShipmentResponse.self, from: data)
                DispatchQueue.main.async {
                    completion(.success(response.rates))
                }
            } catch {
                print("Decoding error: \(error)")
                completion(.failure(error))
            }

        }.resume()
    }
}

/*
struct Shipment: Codable {
    var originAddress: String
    var destinationAddress: String
    var provider: String
    var length: Double
    var width: Double
    var height: Double
    var weight: Double
}*/


struct ShipmentResponse: Decodable {
    let rates: [ShippingOption]
}

struct ShippingOption: Decodable, Identifiable {
    var id: String
    var carrier: String
    var service: String
    var rate: String
    // ... other properties ...
}



/*

class NetworkManager {
    
    static let shared = NetworkManager()
    
    func authenticateWithUPS(completion: @escaping (Result<String, Error>) -> Void) {
        let url = URL(string: "https://wwwcie.ups.com/security/v1/oauth/token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("G48J89", forHTTPHeaderField: "x-merchant-id")
        
        let clientId = "yMl8QYJXOMwSUYW0De3YFJrrdX8Y5opnQIzsguQbyOyWNxK1"
        let clientSecret = "jfO1zPXeXJUxEOUnsqMwJ54aosGZuQHeRVtIzVEClpNIqMPGbOw4EmaJT7AxjHca"

        let credentials = "\(clientId):\(clientSecret)"
        let encodedCredentials = Data(credentials.utf8).base64EncodedString()
        request.setValue("Basic \(encodedCredentials)", forHTTPHeaderField: "Authorization")

        let payload = "grant_type=client_credentials"
        request.httpBody = payload.data(using: .utf8)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                completion(.failure(error ?? NSError(domain: "", code: 0, userInfo: nil)))
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    print(json)
                    if let token = json["access_token"] as? String {
                        completion(.success(token))
                    } else {
                        completion(.failure(NSError(domain: "", code: 0, userInfo: nil)))
                    }
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}

*/


