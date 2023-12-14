//
//  MenuView.swift
//  shiptrack
//
//  Created by Nick DeRose on 12/6/23.
//

import Foundation
import SwiftUI

struct MenuView: View {
    var body: some View {
        // Your UI components for Today's Shipments
        PageContainer(title: "Main Menu") {
            // Your specific content for Today's Shipments
            Text("Main menu items...")
        }
    }
}

struct MenuView_Previews: PreviewProvider {
    static var previews: some View {
        MenuView()
    }
}
