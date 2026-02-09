//
//  PinListView.swift
//  WorldNews
//
//  Created by 조준희 on 2/9/26.
//

import SwiftUI

struct PinListView: View {
    @ObservedObject var viewModel: NewsFeedViewModel
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        NavigationStack {
            if viewModel.pinnedArticles.isEmpty {
                // MARK: - 빈 상태
                VStack(spacing: 16) {
                    Image(systemName: "pin.slash")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    Text("핀된 기사가 없습니다")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("뉴스 피드에서 기사를 왼쪽으로 스와이프하여\n핀을 고정할 수 있습니다")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            } else {
                // MARK: - 핀된 기사 목록
                List {
                    ForEach(viewModel.pinnedArticles) { article in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "pin.fill")
                                    .foregroundColor(.orange)
                                    .font(.caption)
                                Text(article.displayTitle)
                                    .font(.headline)
                            }
                            Text(article.displayDescription)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineLimit(3)
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
                                    Color(UIColor.secondarySystemGroupedBackground) : Color.white)
                        .cornerRadius(8)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                viewModel.deletePinArticle(article)
                            } label: {
                                Label("핀 해제", systemImage: "pin.slash.fill")
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .navigationTitle("Pinned")
                .navigationBarTitleDisplayMode(.automatic)
                .background(Color(UIColor.systemGroupedBackground))
            }
        }
    }
}

// MARK: - Preview
#Preview {
    PinListView(viewModel: NewsFeedViewModel())
}
