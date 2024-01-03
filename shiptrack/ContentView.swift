//
//  ContentView.swift
//  shiptrack
//
//  Created by Nick DeRose on 12/6/23.
//

import SwiftUI

class WebViewManager: ObservableObject {
    var coordinator: WebView.Coordinator?
}

struct ContentView: View {
    @State private var isAuthenticated = false
    @State private var showScanner = false
    @StateObject var webViewManager = WebViewManager()
    
    // Computed property for baseUrlString
    private var baseUrlString: String {
        let key = isDebugBuild ? "LocalBaseURL" : "ProductionBaseURL"
        return (Bundle.main.object(forInfoDictionaryKey: key) as? String) ?? ""
    }

    // Computed property to check if it's a debug build
    private var isDebugBuild: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
    
    var body: some View {
        WebView(urlString: baseUrlString + "/login", onOpenScanner: {
            self.showScanner = true
        }, webViewManager: webViewManager)
        .environmentObject(webViewManager) 
        .sheet(isPresented: $showScanner) {
            NewShipmentsView(showScanner: $showScanner)
                .environmentObject(webViewManager)
        }
    }
}

class WebViewContainer: ObservableObject {
    var urlString: String
    var webViewManager: WebViewManager  // Add this property

    init(urlString: String, webViewManager: WebViewManager) {
        self.urlString = urlString
        self.webViewManager = webViewManager
    }

    func webView(onOpenScanner: @escaping () -> Void) -> WebView {
        WebView(urlString: urlString, onOpenScanner: onOpenScanner, webViewManager: webViewManager)
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
