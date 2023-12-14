//
//  ShipView.swift
//  shiptrack
//
//  Created by Nick DeRose on 12/7/23.
//

import Foundation
import SwiftUI

// Custom Label View
struct LabelView: View {
    var labelText: String
    
    var body: some View {
        Text(labelText)
            .font(.custom("Avenir", size: 16))
            
    }
}
// DateFormatter for custom date format
private var dateFormatter: DateFormatter {
    let formatter = DateFormatter()
    formatter.dateFormat = "(EEE)" // Format: Tue, Dec 7, 2023
    return formatter
}
struct RadioButton: View {
    var id: String
    var label: String
    var isSelected: Bool
    var action: (String) -> Void

    var body: some View {
        HStack {
            Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                .foregroundColor(isSelected ? .blue : .primary)
                .onTapGesture {
                    self.action(self.id)
                }
            Text(label)
                .foregroundColor(.primary)
            Spacer()
        }
        .padding(5)
    }
}

struct Address: Codable {
    var name: String
    var street1: String
    var street2: String? // Optional if not always needed
    var city: String
    var state: String
    var zip: String
    var country: String
    var email: String?
    var phone: String?
}

struct Parcel: Codable {
    var length: Double
    var width: Double
    var height: Double
    var weight: Double
}

struct CustomsInfo: Codable {
    var id: String?
}

struct Shipment: Codable {
    var to_address: Address
    var from_address: Address
    var parcel: Parcel
    var customs_info: CustomsInfo?
}

class ShippingData: ObservableObject {
    @Published var destinationName: String = ""
    @Published var destinationStreet1: String = ""
    @Published var destinationStreet2: String = ""
    @Published var destinationCity: String = ""
    @Published var destinationState: String = ""
    @Published var destinationZip: String = ""
    @Published var destinationCountry: String = "US"
    @Published var destinationEmail: String = "example@example.com"
    //@Published var destinationPhone: String = ""
    // ... other shared properties ...
}


struct BorderedPicker<Label, Content>: View where Label: View, Content: View {
    let label: Label
    let content: Content

    init(@ViewBuilder label: () -> Label, @ViewBuilder content: () -> Content) {
        self.label = label()
        self.content = content()
    }

    var body: some View {
        ZStack {
            Rectangle()
                .foregroundColor(Color(UIColor.systemBackground))
                .border(Color.gray, width: 1)

            HStack {
                label
                Spacer()
                content
            }
            .padding(.horizontal)
        }
        .frame(height: 44) // Match the height of TextField
    }
}

/*
struct AddressFormTo: View {
    @ObservedObject var shippingData: ShippingData
    
    var body: some View {
        Group {
            // Address Field
            LabelView(labelText: "Destination Address").fontWeight(.bold)
            TextField("Name", text: $shippingData.destinationName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            TextField("Address", text: $shippingData.destinationStreet1)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            TextField("Suite/Apt", text: $shippingData.destinationStreet2)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            TextField("City", text: $shippingData.destinationCity)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            TextField("State", text: $shippingData.destinationState)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            TextField("Zip Code", text: $shippingData.destinationZip)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            TextField("Country", text: $shippingData.destinationCountry)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            TextField("Email", text: $shippingData.destinationEmail)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            /*
            TextField("Phone", text: shippingData.destinationPhone)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                */
            
            Spacer().frame(height: 5)
        }
    }
}*/



struct ShippingRate: Decodable, Identifiable {
    var id: String
    var service: String
    var carrier: String
    var rate: String
    // Add other properties as needed

    // Implement `Identifiable` conformance if your id field is named differently
    var identity: String { return id }
}


struct ShipView: View {
    var product: Product
    //var serialNumber: String
    @ObservedObject var shippingData: ShippingData
    
    @State private var originName: String = "Nick's Company"
    @State private var originStreet1: String = "18019 MOHAWK DR"
    @State private var originStreet2: String = ""
    @State private var originCity: String = "SPRING LAKE"
    @State private var originState: String = "MI"
    @State private var originZip: String = "49456"
    @State private var originCountry: String = "US"
    @State private var originEmail: String = "example@example.com"
    @State private var originPhone: String = "555-555-5555"
    
    
    
    @State private var preferredArrivalDate = Date()
    @State private var selectedProvider = "UPS"
    let providers = ["UPS", "FedEx", "DHL", "USPS"]
    @State private var selectedShippingOption = "Next Day Air"
    //let shippingOptions = ["Next Day Air: $38.98", "Second Day Air: $28.98", "3-Day Select: $18.98", "Ground: $12.98", "Standard: $8.98"]
    @State private var shippingOptions: [ShippingOption] = []

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    
                    VStack(alignment: .leading) {
                        Text("Product To Ship")
                            .fontWeight(.bold)
                            .font(.custom("Avenir", size: 14))
                        
                        Spacer().frame(height: 3)
                        
                        Text(product.name)
                            .fontWeight(.bold)
                            .font(.custom("Avenir", size: 18))
                        
                        Spacer().frame(height: 5)
                        
                        Text("Serial #: \(product.serial)")
                            .font(.custom("Avenir", size: 14))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding() // Padding inside the box
                    .background(Color.gray.opacity(0.2)) // Light grey background
                    .cornerRadius(10) // Rounded corners
                    
                    
                    
                    VStack(alignment: .leading, spacing: 6) {
                        
                        //AddressFormTo(shippingData: shippingData)
                        
                        Group {
                            // Address Field
                            LabelView(labelText: "Destination Address").fontWeight(.bold)
                            TextField("Name", text: $shippingData.destinationName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            TextField("Address", text: $shippingData.destinationStreet1)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            TextField("Suite/Apt", text: $shippingData.destinationStreet2)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            TextField("City", text: $shippingData.destinationCity)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            TextField("State", text: $shippingData.destinationState)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            TextField("Zip Code", text: $shippingData.destinationZip)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            TextField("Country", text: $shippingData.destinationCountry)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            /*
                            TextField("Email", text: $shippingData.destinationEmail)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            TextField("Phone", text: shippingData.destinationPhone)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                */
                            
                            Spacer().frame(height: 5)
                        }
                        

                        // Provider Picker Field
                        
                        LabelView(labelText: "Provider").fontWeight(.bold)
                        Picker("Provider", selection: $selectedProvider) {
                            ForEach(providers, id: \.self) {
                                Text($0)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        
                        Spacer().frame(height: 10)
                        
                        
                        LabelView(labelText: "Shipping Options").fontWeight(.bold)
                        ForEach(shippingOptions, id: \.self) { option in
                            RadioButton(id: option.name, label: "\(option.name): $\(option.price)", isSelected: option.name == selectedShippingOption) { selectedId in
                                self.selectedShippingOption = selectedId
                            }
                        }
                        
                        

                        
                        Button("Get Shipping Options") {
   
                            let shipment = Shipment(
                                to_address: Address(
                                    name: shippingData.destinationName,
                                    street1: shippingData.destinationStreet1,
                                    street2: shippingData.destinationStreet2, // Optional field
                                    city: shippingData.destinationCity,
                                    state: shippingData.destinationState,
                                    zip: shippingData.destinationZip,
                                    country: shippingData.destinationCountry,
                                    email: shippingData.destinationEmail
                                    //phone: shippingData.destinationPhone
                                ),
                                from_address: Address(
                                    name: originName,
                                    street1: originStreet1,
                                    street2: originStreet2, // Optional field
                                    city: originCity,
                                    state: originState,
                                    zip: originZip,
                                    country: originCountry,
                                    email: originEmail,
                                    phone: originPhone
                                ),
                                parcel: Parcel(
                                    length: Double(product.length),
                                    width: Double(product.width),
                                    height: Double(product.height),
                                    weight: Double(product.weight)
                                )
                                //customs_info: CustomsInfo(id: "cstinfo_...")
                            )
                                

                            NetworkManager.shared.getShippingOptions(shipment: shipment) { result in
                                switch result {
                                case .success(let options):
                                    self.shippingOptions = options
                                    // Update UI to display these options
                                case .failure(let error):
                                    print("Error: \(error.localizedDescription)")
                                    // Handle error
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                        .background(Color.hex("0177CC"))
                        .foregroundColor(.white)
                        .font(.custom("Avenir", size: 20))
                        .fontWeight(.bold)
                        .cornerRadius(10) // Change this value for different corner radius sizes
                        .padding(15)
                        .padding(.top, 30)
                        
                        
                        Spacer().frame(height: 20)
                    }
                }
                .padding(7)
                .padding(.horizontal, 10)
                
                Spacer()
            }
        }
    }
    

}
