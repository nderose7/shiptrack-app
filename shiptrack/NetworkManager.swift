//
//  NetworkManager.swift
//  shiptrack
//
//  Created by Nick DeRose on 12/12/23.
//

import Foundation

class NetworkManager {
    static let shared = NetworkManager()

    func getShippingOptions(shipment: Shipment, completion: @escaping (Result<ShipmentResponse, Error>) -> Void) {
        guard let authData = KeychainService.shared.retrieveAuthData() else {
            // If authentication data is not found, return an error using Result.failure
            completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Authentication data not found"])))
            return
        }
        
        let url = URL(string: "https://cloudship-strapi-6orma.ondigitalocean.app/api/shipments")! // Replace with your API URL
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
                    completion(.success(response))  // Return the entire response
                }
            } catch {
                print("Decoding error: \(error)")
                completion(.failure(error))
            }

        }.resume()
    }
    
    func purchaseLabel(shipmentId: String, rateId: String, completion: @escaping (Result<LabelInfo, Error>) -> Void) {
        guard let authData = KeychainService.shared.retrieveAuthData() else {
            // If authentication data is not found, return an error using Result.failure
            completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Authentication data not found"])))
            return
        }
        
        let url = URL(string: "https://cloudship-strapi-6orma.ondigitalocean.app/api/shipments/\(shipmentId)/buy-label")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(authData.token)", forHTTPHeaderField: "Authorization")
        
        let body: [String: Any] = ["rateId": rateId] // Assuming rate_id is needed to buy a label
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        } catch {
            completion(.failure(error))
            return
        }


        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("Response HTTP Status code: \(httpResponse.statusCode)")
            }

            if let data = data, let rawResponse = String(data: data, encoding: .utf8) {
                print("Raw server response: \(rawResponse)")
            } else {
                print("No data received from server")
            }

            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "", code: -1, userInfo: nil)))
                }
                return
            }

            do {
                let labelInfo = try JSONDecoder().decode(LabelInfo.self, from: data)
                DispatchQueue.main.async {
                    completion(.success(labelInfo))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
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
    var shipmentId: String
    var rates: [ShippingOption]
    
    enum CodingKeys: String, CodingKey {
        case shipmentId = "id"  // Use the actual key from your JSON response
        case rates
    }
}

struct ShippingOption: Decodable, Identifiable, Hashable {
    var id: String
    var carrier: String
    var service: String
    var rate: String
    var delivery_days: Int?
    // ... other properties ...
}

struct LabelInfo: Decodable, Hashable {
    var label_url: String

    enum CodingKeys: String, CodingKey {
        case postageLabel = "postage_label"
    }

    enum PostageLabelKeys: String, CodingKey {
        case label_url
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let postageLabelContainer = try container.nestedContainer(keyedBy: PostageLabelKeys.self, forKey: .postageLabel)
        label_url = try postageLabelContainer.decode(String.self, forKey: .label_url)
    }
}

