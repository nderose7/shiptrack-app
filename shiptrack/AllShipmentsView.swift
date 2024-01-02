//
//  AllShipmentsView.swift
//  shiptrack
//
//  Created by Nick DeRose on 12/6/23.
//

import Foundation
import SwiftUI

struct ProductResponse: Decodable {
    var data: [ProductData]
}

struct ProductData: Decodable, Identifiable {
    var id: Int
    var name: String
    var description: String
    var serial: String
    var length: Int
    var width: Int
    var height: Int
    var weight: Int
    // Add other fields that were previously in Product

    typealias ID = Int
    var identity: Int {
        return id
    }
}


class ProductService {
    func fetchProducts(completion: @escaping ([ProductData]?, Error?) -> Void) {
        guard let authData = KeychainService.shared.retrieveAuthData() else {
            completion(nil, NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Authentication data not found"]))
            return
        }
        
        let endpoint = "/api/products"

        var baseDomain: String {
            #if DEBUG
            return Bundle.main.object(forInfoDictionaryKey: "LocalBaseDomain") as? String ?? "http://localhost:1337"
            #else
            return Bundle.main.object(forInfoDictionaryKey: "ProductionBaseDomain") as? String ?? "https://cloudship-strapi-6orma.ondigitalocean.app"
            #endif
        }
        
        print("URL: ", baseDomain + endpoint)
        
        // Combine the base URL with the endpoint to form the complete URL.
        guard let url = URL(string: baseDomain + endpoint), !baseDomain.isEmpty else {
            // Handle the error appropriately
            // e.g., log an error, show an alert, etc.
            return
        }
        
        
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(authData.token)", forHTTPHeaderField: "Authorization")

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            // Log the error
            if let error = error {
                print("Error fetching products: \(error)")
                completion(nil, error)
                return
            }

            // Check for HTTP response and log status code
            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP Status Code: \(httpResponse.statusCode)")
            }

            // Ensure data is not nil
            guard let data = data else {
                print("No data received from server")
                completion(nil, NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data"]))
                return
            }

            // Log the raw data for debugging
            let rawResponseString = String(data: data, encoding: .utf8) ?? "Unable to decode response"
            print("Raw Response: \(rawResponseString)")

            do {
                // Directly decode into ProductResponse and pass the data array
                let productResponse = try JSONDecoder().decode(ProductResponse.self, from: data)
                completion(productResponse.data, nil)
            } catch {
                print("Decoding error: \(error)")
                completion(nil, error)
            }
        }

        task.resume()
    }

    
}

struct AllProductsView: View {
    @State private var productData: [ProductData] = []  // Changed to ProductData
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            List(productData, id: \.identity) { data in
                VStack(alignment: .leading) {
                    Text(data.name).font(.headline)
                    Text(data.serial)
                    //Text(data.attributes.description).font(.subheadline)
                }
            }
            .navigationTitle("All Products")
            .onAppear(perform: loadProducts)
            .alert(isPresented: .constant(errorMessage != nil), content: {
                Alert(title: Text("Error"), message: Text(errorMessage ?? "Unknown error"), dismissButton: .default(Text("OK")))
            })
        }
    }

    private func loadProducts() {
        isLoading = true
        ProductService().fetchProducts { fetchedProductData, error in
            DispatchQueue.main.async {
                isLoading = false
                if let error = error {
                    self.errorMessage = error.localizedDescription
                } else if let fetchedProductData = fetchedProductData {
                    self.productData = fetchedProductData
                }
            }
        }
    }
}

struct AllProductsView_Previews: PreviewProvider {
    static var previews: some View {
        AllProductsView()
    }
}

