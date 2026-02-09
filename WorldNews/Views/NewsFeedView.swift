//
//  NewsFeedView.swift
//  WorldNews
//
//  Created by 조준희 on 2/9/26.
//

import SwiftUI
import Combine

// MARK: -카테고리 정의
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
    @Environment(\.colorScheme) private var colorScheme
    @State private var searchText: String = "세계 뉴스"
    @State private var selectedCategory: NewsCategory = .전체
    @State private var selectedURL: String? = nil
    @State private var lastTriggeredId: UUID? = nil  // 중복 호출 방지
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 5) {
                // MARK: -헤더
                /*HStack {
                    Text("뉴스 피드")
                        .font(.largeTitle)
                        .padding(.leading)
                        .bold()
                    Spacer()
                }*/
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
                Spacer(minLength: 0)
                
                // MARK: -뉴스 피드
                if viewModel.isLoading {
                    ProgressView("로딩 중...")
                        .padding()
                } else if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.articles) { article in
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(article.displayTitle)
                                        .font(.headline)
                                    Text(article.displayDescription)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    if let url = URL(string: article.link) {
                                        NavigationLink(
                                            destination: ArticleView(url: url),
                                            label: {
                                                Text("원문 보기")
                                                    .font(.caption)
                                                    .foregroundColor(.blue)
                                            }
                                        )
                                    }
                                    Text(article.displayDate)
                                        .font(.caption2)
                                        .foregroundColor(.gray)
                                }
                                .padding()
                                .background(colorScheme == .dark ?
                                            Color(UIColor.secondarySystemGroupedBackground) : Color.white
                                )
                                .cornerRadius(8)
                                .frame(maxWidth: .infinity , alignment: .leading)
                                .onAppear {
                                    // 마지막 아이템에 도달하면 다음 페이지 로드 (무한 스크롤)
                                    // 중복 호출 방지
                                    if article.id == viewModel.articles.last?.id,
                                       article.id != lastTriggeredId {
                                        lastTriggeredId = article.id
                                        // 0.3초 디바운싱으로 CPU 부하 감소
                                        Task {
                                            try? await Task.sleep(nanoseconds: 300_000_000)
                                            viewModel.loadMoreNews()
                                        }
                                    }
                                }
                            }
                            
                            // 더 불러오는 중 표시
                            if viewModel.isLoadingMore {
                                ProgressView()
                                    .padding()
                            }
                        }
                        .padding()
                    }
                    .refreshable {
                        // Pull to Refresh
                        await refreshNews()
                    }
                }
            }
            .navigationTitle("뉴스 피드")
            .navigationBarTitleDisplayMode(.large)
            .background(Color(UIColor.systemGroupedBackground))
            .onAppear {
                viewModel.fetchNews(query: searchText)
            }
        }
    }
    
    // MARK: - Pull to Refresh 함수
    private func refreshNews() async {
        viewModel.fetchNews(query: searchText)
        // 네트워크 요청이 완료될 때까지 대기
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5초
    }
}
