//
//  NewsFeedViewModel.swift
//  WorldNews
//
//  Created by 조준희 on 2/9/26.
//

import Foundation
import Combine
import FirebaseRemoteConfig

// MARK: - 표시용 뉴스 아이템 (ViewModel)
struct NewsArticleViewModel: Identifiable {
    let id: UUID
    let displayTitle: String
    let displayDescription: String
    let displayDate: String
    let link: String
    
    init(from article: NewsArticle) {
        self.id = article.id
        self.displayTitle = Self.cleanHTML(article.title)
        self.displayDescription = Self.cleanHTML(article.description)
        self.displayDate = Self.formatDate(article.pubDate)
        self.link = article.link
    }
    
// MARK: - HTML 정리 (태그 제거 + 엔티티 디코딩)
    private static func cleanHTML(_ text: String) -> String {
        // HTML 태그 제거
        var result = text.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        
        // HTML 엔티티 디코딩
        let entities: [String: String] = [
            "&quot;": "\"",
            "&amp;": "&",
            "&lt;": "<",
            "&gt;": ">",
            "&apos;": "'",
            "&nbsp;": " ",
            "&#39;": "'",
            "&#34;": "\""
        ]
        for (entity, char) in entities {
            result = result.replacingOccurrences(of: entity, with: char)
        }
        return result
    }
    
// MARK: - 날짜 포맷팅
    private static func formatDate(_ pubDate: String) -> String {
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
}

// MARK: - 뉴스 피드 ViewModel
class NewsFeedViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var articles: [NewsArticleViewModel] = []
    @Published var isLoading: Bool = false
    @Published var isLoadingMore: Bool = false
    @Published var errorMessage: String? = nil
    
    // MARK: - Private Properties
    private var clientId: String = ""
    private var clientSecret: String = ""
    private let remoteConfig = RemoteConfig.remoteConfig()
    
    private var currentQuery: String = "세계 뉴스"
    private var currentStart: Int = 1
    private let displayCount: Int = 10
    private var canLoadMore: Bool = true
    private var currentTask: URLSessionDataTask?
    private var lastLoadedArticleId: UUID?
    
    // MARK: - Initialization
    init() {
        setupRemoteConfig()
    }
    
    // MARK: - Remote Config 설정
    private func setupRemoteConfig() {
        configureRemoteConfigSettings()
        fetchRemoteConfigValues()
    }
    
    private func configureRemoteConfigSettings() {
        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = 0 // 개발용, 프로덕션: 3600
        remoteConfig.configSettings = settings
        
        remoteConfig.setDefaults([
            "naver_client_id": "" as NSObject,
            "naver_client_secret": "" as NSObject
        ])
    }
    
    private func fetchRemoteConfigValues() {
        remoteConfig.fetch { [weak self] status, error in
            guard let self = self else { return }
            
            if status == .success {
                self.activateRemoteConfig()
            } else {
                self.handleRemoteConfigError(error)
            }
        }
    }
    
    private func activateRemoteConfig() {
        remoteConfig.activate { [weak self] _, _ in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.clientId = self.remoteConfig["naver_client_id"].stringValue ?? ""
                self.clientSecret = self.remoteConfig["naver_client_secret"].stringValue ?? ""
                
                if !self.clientId.isEmpty {
                    print("✅ Remote Config 로드 완료")
                    self.fetchNews()
                } else {
                    self.errorMessage = "Firebase Remote Config에서 API 키를 가져오지 못했습니다."
                    print("❌ Remote Config에 API 키가 없습니다.")
                }
            }
        }
    }
    
    private func handleRemoteConfigError(_ error: Error?) {
        DispatchQueue.main.async { [weak self] in
            self?.errorMessage = "Firebase 연결 실패: \(error?.localizedDescription ?? "알 수 없는 오류")"
            print("❌ Remote Config 가져오기 실패: \(error?.localizedDescription ?? "")")
        }
    }
    
    // MARK: - Public Methods
    func fetchNews(query: String = "세계 뉴스") {
        cancelCurrentRequest()
        resetPagination(with: query)
        loadNews(isRefresh: true)
    }
    
    func loadMoreNews() {
        guard canLoadMore, !isLoading, !isLoadingMore, currentTask == nil else {
            return
        }
        
        currentStart += displayCount
        loadNews(isRefresh: false)
    }
    
    // MARK: - Private Helpers
    private func cancelCurrentRequest() {
        currentTask?.cancel()
        currentTask = nil
    }
    
    private func resetPagination(with query: String) {
        currentQuery = query
        currentStart = 1
        canLoadMore = true
        lastLoadedArticleId = nil
    }
    
    private func loadNews(isRefresh: Bool) {
        guard !clientId.isEmpty && !clientSecret.isEmpty else {
            retryLoadNewsLater(isRefresh: isRefresh)
            return
        }
        
        guard let request = buildNewsRequest() else { return }
        
        updateLoadingState(isRefresh: isRefresh, loading: true)
        executeNewsRequest(request, isRefresh: isRefresh)
    }
    
    private func retryLoadNewsLater(isRefresh: Bool) {
        print("⚠️ API 키가 아직 로드되지 않았습니다. 잠시 후 다시 시도하세요.")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.loadNews(isRefresh: isRefresh)
        }
    }
    
    private func buildNewsRequest() -> URLRequest? {
        guard let encodedQuery = currentQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return nil }
        
        let urlString = "https://openapi.naver.com/v1/search/news.json?query=\(encodedQuery)&display=\(displayCount)&start=\(currentStart)&sort=date"
        guard let url = URL(string: urlString) else { return nil }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue(clientId, forHTTPHeaderField: "X-Naver-Client-Id")
        request.addValue(clientSecret, forHTTPHeaderField: "X-Naver-Client-Secret")
        
        return request
    }
    
    private func updateLoadingState(isRefresh: Bool, loading: Bool) {
        if isRefresh {
            isLoading = loading
        } else {
            isLoadingMore = loading
        }
        if loading {
            errorMessage = nil
        }
    }
    
    private func executeNewsRequest(_ request: URLRequest, isRefresh: Bool) {
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            defer {
                DispatchQueue.main.async { [weak self] in
                    self?.currentTask = nil
                    self?.updateLoadingState(isRefresh: isRefresh, loading: false)
                }
            }
            
            if let error = error as NSError?, error.code == NSURLErrorCancelled {
                return
            }
            
            if let error = error {
                self?.handleError(error.localizedDescription)
                return
            }
            
            guard let data = data else {
                self?.handleError("데이터가 없습니다.")
                return
            }
            
            self?.parseAndUpdateArticles(data: data, isRefresh: isRefresh)
        }
        
        currentTask = task
        task.resume()
    }
    
    private func handleError(_ message: String) {
        DispatchQueue.main.async { [weak self] in
            self?.errorMessage = message
        }
    }
    
    private func parseAndUpdateArticles(data: Data, isRefresh: Bool) {
        do {
            let decoder = JSONDecoder()
            let result = try decoder.decode(NaverNewsResponse.self, from: data)
            
            DispatchQueue.main.async { [weak self] in
                self?.updateArticlesList(with: result.items, isRefresh: isRefresh)
            }
        } catch {
            handleError("파싱 오류: \(error.localizedDescription)")
        }
    }
    
    private func updateArticlesList(with items: [NewsArticle], isRefresh: Bool) {
        let viewModels = items.map { NewsArticleViewModel(from: $0) }
        
        if isRefresh {
            articles = viewModels
        } else {
            let newItems = viewModels.filter { newItem in
                !articles.contains(where: { $0.link == newItem.link })
            }
            articles.append(contentsOf: newItems)
        }
        
        canLoadMore = items.count >= displayCount
        lastLoadedArticleId = articles.last?.id
    }
}

