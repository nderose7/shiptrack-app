//
//  HomeView.swift
//  shiptrack
//
//  Created by Nick DeRose on 12/6/23.
//

import Foundation
import SwiftUI

struct ShipmentFetchedResponse: Decodable {
    var data: [ShipmentData]
}

struct ShipmentData: Decodable, Identifiable {
    var id: Int
    var originAddress: String
    var destinationAddress: String

    // Explicitly define the type of `id` for `Identifiable`
    typealias ID = Int
    var identity: Int {
        return id
    }
}

class ShipmentService {
    func fetchShipments(completion: @escaping ([ShipmentData]?, Error?) -> Void) {
        print("Shipment Fetching...")
        guard let authData = KeychainService.shared.retrieveAuthData() else {
            completion(nil, NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Authentication data not found"]))
            return
        }
        
        let endpoint = "/api/shipments"
                
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
        request.httpMethod = "GET"
        request.addValue("Bearer \(authData.token)", forHTTPHeaderField: "Authorization")

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            // Log the error
            if let error = error {
                print("Error fetching shipments: \(error)")
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
            print("Raw Shipment Response: \(rawResponseString)")
            
            do {
                // Directly decode into Response and pass the data array
                let shipmentResponse = try JSONDecoder().decode(ShipmentFetchedResponse.self, from: data)
                completion(shipmentResponse.data, nil)
            } catch {
                print("Decoding error: \(error)")
                completion(nil, error)
            }
        }

        task.resume()
    }

}
enum NavigationDestination: Hashable {
    case newShipments
    // Add other cases for different views as needed
}

struct HomeView: View {
    @State private var shipmentData: [ShipmentData] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var searchText = ""
    @State private var navigationPath = NavigationPath()
    @State private var navigationTrigger: NavigationDestination?
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack {
                HStack {
                    TextField("Search shipments...", text: $searchText)
                        .padding(7)
                        .padding(.horizontal, 25)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .overlay(
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.gray)
                                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                                    .padding(.leading, 8)
                            }
                        )
                    
                    Spacer() // Separates search bar and icon button
                    
                    Button(action: {
                        navigationTrigger = .newShipments
                    }) {
                        Image(systemName: "barcode.viewfinder")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                    }

                    // Conditional navigation
                    if let destination = navigationTrigger {
                        NavigationLink("", value: destination)
                            .hidden()
                    }
                    
                }
                .padding(.horizontal)
                .frame(height: 40) // Adjust the height as needed
                
                // Rest of your content
                PageContainer(title: "In Progress") {
                    List(shipmentData, id: \.identity) { data in
                        VStack(alignment: .leading) {
                            Text(data.originAddress).font(.headline)
                            Text(data.destinationAddress)
                            //Text(data.attributes.description).font(.subheadline)
                        }
                    }
                }
                
                
                // Rest of your content
                /*
                 PageContainer(title: "Shipped Today") {
                 Text("Card items go here...").frame(maxWidth: .infinity, alignment: .leading)
                 }
                 
                 PageContainer(title: "Shipped Yesterday") {
                 Text("Card items go here...").frame(maxWidth: .infinity, alignment: .leading)
                 }
                 
                 PageContainer(title: "Shipped Last 7 Days") {
                 Text("Card items go here...").frame(maxWidth: .infinity, alignment: .leading)
                 }
                 
                 PageContainer(title: "Older Than 7 Days") {
                 Text("Card items go here...").frame(maxWidth: .infinity, alignment: .leading)
                 }*/
            }
            .onAppear(perform: loadShipments)
            /*
            .navigationDestination(for: NavigationDestination.self) { destination in
                switch destination {
                case .newShipments:
                    NewShipmentsView()
                // Handle other destinations
                }
            }*/
        }
    }
    private func loadShipments() {
        isLoading = true
        ShipmentService().fetchShipments { fetchedShipmentData, error in
            DispatchQueue.main.async {
                isLoading = false
                if let error = error {
                    self.errorMessage = error.localizedDescription
                } else if let fetchedShipmentData = fetchedShipmentData {
                    self.shipmentData = fetchedShipmentData
                }
            }
        }
    }
}


struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
