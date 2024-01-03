//
//  WebView.swift
//  eatclassy
//
//  Created by Nick DeRose on 12/2/23.
//

import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    let urlString: String
    var onOpenScanner: (() -> Void)?
    var webViewManager: WebViewManager

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        context.coordinator.webView = webView  // Store reference to webView
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        if let url = URL(string: urlString) {
            let request = URLRequest(url: url)
            uiView.load(request)
        }
    }

    func makeCoordinator() -> Coordinator {
        let coordinator = Coordinator(self)
        webViewManager.coordinator = coordinator // Assign coordinator to webViewManager
        return coordinator
    }

    mutating func onOpenScanner(_ action: @escaping () -> Void) -> WebView {
        self.onOpenScanner = action
        return self
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView
        var webView: WKWebView?  // Reference to the WKWebView

        init(_ parent: WebView) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if let url = navigationAction.request.url, url.scheme == "scanner" {
                // This is your custom URL scheme handling
                parent.onOpenScanner?() // Safe call using optional chaining
                decisionHandler(.cancel)
            } else {
                decisionHandler(.allow)
            }
        }

        // Add this method to evaluate JavaScript
        func evaluateJavaScript(_ script: String) {
            print("Evaluating JS: \(script)")
            webView?.evaluateJavaScript(script, completionHandler: { result, error in
                if let error = error {
                    print("JavaScript evaluation error: \(error)")
                } else if let result = result {
                    print("JavaScript evaluation result: \(result)")
                }
            })
        }
    }
}

