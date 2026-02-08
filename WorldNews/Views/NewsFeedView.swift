//
//  NewsFeedView.swift
//  WorldNews
//
//  Created by 조준희 on 2/9/26.
//

import SwiftUI
import Combine

// 카테고리 정의
enum NewsCategory: String, CaseIterable, Identifiable {
    case 전체 = "전체"
    case 정치 = "정치"
    case 경제 = "경제"
    case 사회 = "사회"
    case 생활문화 = "생활/문화"
    case IT과학 = "IT/과학"
    case 세계 = "세계"
    var id: String { self.rawValue }
    var query: String {
        switch self {
        case .전체: return "세계 뉴스"
        case .정치: return "정치"
        case .경제: return "경제"
        case .사회: return "사회"
        case .생활문화: return "생활 문화"
        case .IT과학: return "IT 과학"
        case .세계: return "세계"
        }
    }
}

struct NewsFeedView: View {
    @StateObject private var viewModel = NewsFeedViewModel()
    @State private var searchText: String = "세계 뉴스"
    @State private var selectedCategory: NewsCategory = .전체
    
    var body: some View {
        VStack (spacing: 5) {

// MARK: -헤더
            VStack (spacing: 5) {
                HStack {
                    Text("뉴스")
                        .font(.largeTitle)
                        .padding(.leading)
                        .bold()
                    Spacer()
                }
                // MARK: -카테고리 선택 및 뉴스 리스트
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(NewsCategory.allCases) { category in
                            Button(action: {
                                selectedCategory = category
                                searchText = category.query
                                viewModel.fetchNews(query: searchText)
                            }) {
                                Text(category.rawValue)
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 16)
                                    .background(selectedCategory == category ? Color.blue : Color.gray.opacity(0.2))
                                    .foregroundColor(selectedCategory == category ? .white : .primary)
                                    .cornerRadius(16)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            
// MARK: -뉴스 피드
            if viewModel.isLoading {
                ProgressView("로딩 중...")
                    .padding()
            } else if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .padding()
            } else {
                ScrollView (showsIndicators: false) {
                    VStack(spacing: 16) {
                        ForEach(viewModel.articles) { article in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(article.title.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression))
                                    .font(.headline)
                                Text(article.description.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression))
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                if let url = URL(string: article.link), UIApplication.shared.canOpenURL(url) {
                                    Link("원문 보기", destination: url)
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                }
                                Text(formattedDate(article.pubDate))
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            .background(Color(UIColor.systemBackground).shadow(radius: 1))
                            .cornerRadius(8)
                        }
                    }
                    .padding()
                }
            }
        }
        .onAppear {
            viewModel.fetchNews(query: searchText)
        }
    }
}

// 날짜 포맷 함수 추가
private func formattedDate(_ pubDate: String) -> String {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "E, d MMM yyyy HH:mm:ss Z"
    if let date = formatter.date(from: pubDate) {
        let outputFormatter = DateFormatter()
        outputFormatter.locale = Locale(identifier: "ko_KR")
        outputFormatter.dateFormat = "yyyy.MM.dd HH:mm"
        return outputFormatter.string(from: date)
    }
    return pubDate
}
