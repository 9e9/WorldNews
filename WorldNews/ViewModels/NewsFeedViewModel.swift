//
//  NewsFeedViewModel.swift
//  WorldNews
//
//  Created by 조준희 on 2/9/26.
//

import Foundation
import Combine
import FirebaseRemoteConfig
import SwiftData

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
    
    // SwiftData PinnedArticle로부터 생성
    init(from pinnedArticle: PinnedArticle) {
        self.id = UUID(uuidString: pinnedArticle.id) ?? UUID()
        self.displayTitle = pinnedArticle.displayTitle
        self.displayDescription = pinnedArticle.displayDescription
        self.displayDate = pinnedArticle.displayDate
        self.link = pinnedArticle.link
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
    @Published var pinnedArticles: [NewsArticleViewModel] = []
    @Published var isLoading: Bool = false
    @Published var isLoadingMore: Bool = false
    @Published var errorMessage: String? = nil
    
    // MARK: - SwiftData Context
    private var modelContext: ModelContext?
    
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
    
    // MARK: - SwiftData 설정
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        loadPinnedArticles()
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
    
    func addPinArticle(_ article: NewsArticleViewModel) {
        guard let context = modelContext else {
            print("❌ ModelContext가 설정되지 않았습니다.")
            return
        }
        
        // UUID를 문자열로 변환 (Predicate 매크로는 복잡한 체이닝 미지원)
        let articleIdString = article.id.uuidString
        
        // 중복 방지
        let fetchDescriptor = FetchDescriptor<PinnedArticle>(
            predicate: #Predicate { $0.id == articleIdString }
        )
        
        do {
            if let existing = try context.fetch(fetchDescriptor).first {
                print("⚠️ 이미 핀된 기사입니다.")
                return
            }
            
            let pinnedArticle = PinnedArticle(
                id: article.id.uuidString,
                displayTitle: article.displayTitle,
                displayDescription: article.displayDescription,
                displayDate: article.displayDate,
                link: article.link
            )
            
            context.insert(pinnedArticle)
            try context.save()
            loadPinnedArticles()
            print("✅ 핀 추가: \(article.displayTitle)")
        } catch {
            print("❌ 핀 저장 실패: \(error.localizedDescription)")
        }
    }
    
    func deletePinArticle(_ article: NewsArticleViewModel) {
        guard let context = modelContext else {
            print("❌ ModelContext가 설정되지 않았습니다.")
            return
        }
        
        // UUID를 문자열로 변환 (Predicate 매크로는 복잡한 체이닝 미지원)
        let articleIdString = article.id.uuidString
        
        let fetchDescriptor = FetchDescriptor<PinnedArticle>(
            predicate: #Predicate { $0.id == articleIdString }
        )
        
        do {
            if let pinnedArticle = try context.fetch(fetchDescriptor).first {
                context.delete(pinnedArticle)
                try context.save()
                loadPinnedArticles()
                print("✅ 핀 삭제: \(article.displayTitle)")
            }
        } catch {
            print("❌ 핀 삭제 실패: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Pin Helper Methods
    
    /// 핀 여부 확인
    func isPinned(_ article: NewsArticleViewModel) -> Bool {
        return pinnedArticles.contains(where: { $0.id == article.id })
    }
    
    /// SwiftData에서 핀 목록 로드
    private func loadPinnedArticles() {
        guard let context = modelContext else { return }
        
        let fetchDescriptor = FetchDescriptor<PinnedArticle>(
            sortBy: [SortDescriptor(\.pinnedAt, order: .reverse)]
        )
        
        do {
            let pins = try context.fetch(fetchDescriptor)
            pinnedArticles = pins.map { NewsArticleViewModel(from: $0) }
            print("📂 핀 불러오기 완료: \(pinnedArticles.count)개")
        } catch {
            print("❌ 핀 불러오기 실패: \(error.localizedDescription)")
        }
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

