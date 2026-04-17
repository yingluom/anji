import SwiftUI
import WebKit

/// Displays rendered card HTML inside a WKWebView.
struct CardWebView: UIViewRepresentable {
    let html: String

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences.allowsContentJavaScript = true
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.scrollView.bounces = false
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        let wrapper = """
        <!DOCTYPE html>
        <html>
        <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1">
        <style>
            * { box-sizing: border-box; margin: 0; padding: 0; }
            body {
                font-family: -apple-system, system-ui, sans-serif;
                font-size: 18px;
                line-height: 1.6;
                padding: 20px;
                color: #1a1a2e;
                word-wrap: break-word;
            }
            @media (prefers-color-scheme: dark) {
                body { color: #e0e0e0; }
            }
            img { max-width: 100%; height: auto; border-radius: 8px; }
            hr { border: none; border-top: 1px solid rgba(128,128,128,0.3); margin: 16px 0; }
        </style>
        </head>
        <body>\(html)</body>
        </html>
        """
        webView.loadHTMLString(wrapper, baseURL: nil)
    }
}
