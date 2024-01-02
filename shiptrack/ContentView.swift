//
//  ContentView.swift
//  shiptrack
//
//  Created by Nick DeRose on 12/6/23.
//

import SwiftUI

struct ContentView: View {
    @State private var isAuthenticated = false
    @State private var showScanner = false

    var body: some View {
        if isAuthenticated {
            MainTabView()
        } else {
            WebView(urlString: "http://localhost:3000/login", onOpenScanner: {
                self.showScanner = true
            })
            .sheet(isPresented: $showScanner) {
                NewShipmentsView(showScanner: $showScanner)
            }
        }
    }
}


class WebViewContainer: ObservableObject {
    var urlString: String

    init(urlString: String) {
        self.urlString = urlString
    }

    func webView(onOpenScanner: @escaping () -> Void) -> WebView {
        WebView(urlString: urlString, onOpenScanner: onOpenScanner)
    }
}



struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
