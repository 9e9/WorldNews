//
//  NewsArticle.swift
//  WorldNews
//
//  Created by 조준희 on 2/9/26.
//

// 네이버 뉴스 API 응답에 맞는 뉴스 데이터 모델
// 주요 필드만 우선 구현
import Foundation

struct NewsArticle: Identifiable, Codable {
    let id = UUID()
    let title: String
    let originallink: String
    let link: String
    let description: String
    let pubDate: String
    
    enum CodingKeys: String, CodingKey {
        case title, originallink, link, description, pubDate
    }
}

// API 전체 응답 구조
struct NaverNewsResponse: Codable {
    let items: [NewsArticle]
}
