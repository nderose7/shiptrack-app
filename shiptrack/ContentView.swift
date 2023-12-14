//
//  ContentView.swift
//  shiptrack
//
//  Created by Nick DeRose on 12/6/23.
//

import SwiftUI

struct ContentView: View {
    @State private var isAuthenticated = false

    var body: some View {
        if isAuthenticated {
            MainTabView()
            
        } else {
            
            LoginView(isAuthenticated: $isAuthenticated)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
