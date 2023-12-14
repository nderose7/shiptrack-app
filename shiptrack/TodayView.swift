//
//  HomeView.swift
//  shiptrack
//
//  Created by Nick DeRose on 12/6/23.
//

import Foundation
import SwiftUI

struct HomeView: View {
    @State private var searchText = ""
    var body: some View {
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
                        // Action for the button
                    }) {
                        Image(systemName: "barcode.viewfinder") // Replace with your icon
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                    }
                }
                .padding(.horizontal)
                .frame(height: 40) // Adjust the height as needed
                
                // Rest of your content
                PageContainer(title: "In Progress") {
                    Text("Card items go here...").frame(maxWidth: .infinity, alignment: .leading)
                }

                // Rest of your content
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
                }
            }
        
        
    }
}


struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
