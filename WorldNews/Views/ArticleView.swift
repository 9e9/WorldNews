//
//  ArticleView.swift
//  WorldNews
//
//  Created by 조준희 on 2/9/26.
//

import SwiftUI
import WebKit

struct ArticleView: View {
    let url: URL
    
    var body: some View {
        WebView(url: url)
            .navigationTitle("기사 원문")
            .navigationBarTitleDisplayMode(.inline)
    }
}

struct WebView: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> WKWebView {
        return WKWebView()
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        uiView.load(request)
    }
}

// 프리뷰
#Preview {
    ArticleView(url: URL(string: "https://www.naver.com")!)
}
