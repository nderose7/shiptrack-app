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
    var attributes: Product

    // Explicitly define the type of `id` for `Identifiable`
    typealias ID = Int
    var identity: Int {
        return id
    }
}

struct Product: Decodable {
    var name: String
    var description: String
    var serial: String
    var length: Int
    var width: Int
    var height: Int
    var weight: Int
    // Add other fields as per your Strapi Product model
}


class ProductService {
    func fetchProducts(completion: @escaping ([ProductData]?, Error?) -> Void) {
        guard let authData = KeychainService.shared.retrieveAuthData() else {
            completion(nil, NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Authentication data not found"]))
            return
        }

        let url = URL(string: "http://localhost:1337/api/products")!
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
                let productResponse = try JSONDecoder().decode(ProductResponse.self, from: data)
                completion(productResponse.data, nil)
            } catch {
                print("Decoding error: \(error)")
                completion(nil, error)
            }
        }

        task.resume()
    }

    private func parseProducts(from data: Data) throws -> [Product] {
        let decodedResponse = try JSONDecoder().decode(ProductResponse.self, from: data)
        return decodedResponse.data.map { $0.attributes }
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
                    Text(data.attributes.name).font(.headline)
                    Text(data.attributes.serial)
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
        ProductService().fetchProducts { fetchedProductData, error in  // Changed to fetchedProductData
            DispatchQueue.main.async {
                isLoading = false
                if let error = error {
                    self.errorMessage = error.localizedDescription
                } else if let fetchedProductData = fetchedProductData {
                    self.productData = fetchedProductData  // Changed to productData
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

