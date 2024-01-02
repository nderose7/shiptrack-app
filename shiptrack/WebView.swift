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

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        if let url = URL(string: urlString) {
            let request = URLRequest(url: url)
            uiView.load(request)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    mutating func onOpenScanner(_ action: @escaping () -> Void) -> WebView {
        self.onOpenScanner = action
        return self
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView

        init(_ parent: WebView) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if let url = navigationAction.request.url, url.scheme == "scanner" {
                parent.onOpenScanner?() // Safe call using optional chaining
                decisionHandler(.cancel)
            } else {
                decisionHandler(.allow)
            }
        }
    }
}

