// Created by Lunar on 03/03/2022.
//

import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    let url: URL?
    
    private let webView = WKWebView()
    
    
    func makeUIView(context: Context) -> some UIView {
        webView.backgroundColor = .aircastingBackground
        return webView
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        uiView.backgroundColor = .aircastingBackground
        webView.load(url)
    }
}
