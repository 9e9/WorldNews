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
    @Published var articles: [NewsArticleViewModel] = []
    @Published var isLoading: Bool = false
    @Published var isLoadingMore: Bool = false
    @Published var errorMessage: String? = nil
    
    // Remote Config에서 가져올 API 키
    private var clientId: String = ""
    private var clientSecret: String = ""
    
    private let remoteConfig = RemoteConfig.remoteConfig()
    
    private var currentQuery: String = "세계 뉴스"
    private var currentStart: Int = 1
    private let displayCount: Int = 10  // 10개씩 불러오기
    private var canLoadMore: Bool = true
    private var currentTask: URLSessionDataTask?
    private var lastLoadedArticleId: UUID?  // 중복 방지용
    
    init() {
        setupRemoteConfig()
    }
    
// MARK: - Remote Config 설정
    private func setupRemoteConfig() {
        // 개발 시 빠른 갱신 (프로덕션에서는 3600초 권장)
        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = 0
        remoteConfig.configSettings = settings
        
        // 기본값은 빈 문자열 (보안: 코드에 API 키 노출 방지)
        remoteConfig.setDefaults([
            "naver_client_id": "" as NSObject,
            "naver_client_secret": "" as NSObject
        ])
        
        // Remote Config 가져오기
        remoteConfig.fetch { [weak self] status, error in
            if status == .success {
                self?.remoteConfig.activate { [weak self] _, _ in
                    DispatchQueue.main.async {
                        self?.clientId = self?.remoteConfig["naver_client_id"].stringValue ?? ""
                        self?.clientSecret = self?.remoteConfig["naver_client_secret"].stringValue ?? ""
                        
                        if self?.clientId.isEmpty == false {
                            print("✅ Remote Config 로드 완료")
                            // 첫 뉴스 자동 로드
                            self?.fetchNews()
                        } else {
                            self?.errorMessage = "Firebase Remote Config에서 API 키를 가져오지 못했습니다."
                            print("❌ Remote Config에 API 키가 없습니다.")
                        }
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self?.errorMessage = "Firebase 연결 실패: \(error?.localizedDescription ?? "알 수 없는 오류")"
                    print("❌ Remote Config 가져오기 실패: \(error?.localizedDescription ?? "")")
                }
            }
        }
    }
    
    // 새로고침 (처음부터 다시 로드)
    func fetchNews(query: String = "세계 뉴스") {
        // 기존 요청 취소
        currentTask?.cancel()
        currentTask = nil
        
        currentQuery = query
        currentStart = 1
        canLoadMore = true
        lastLoadedArticleId = nil
        loadNews(isRefresh: true)
    }
    
    // 더 불러오기 (페이지네이션)
    func loadMoreNews() {
        // 이미 로딩 중이거나 더 이상 불러올 수 없으면 무시
        guard !isLoadingMore && !isLoading && canLoadMore else {
            return
        }
        
        // 기존 요청이 진행 중이면 무시
        guard currentTask == nil else {
            return
        }
        
        currentStart += displayCount
        loadNews(isRefresh: false)
    }
    
    private func loadNews(isRefresh: Bool) {
        // API 키가 설정되지 않았으면 대기
        guard !clientId.isEmpty && !clientSecret.isEmpty else {
            print("⚠️ API 키가 아직 로드되지 않았습니다. 잠시 후 다시 시도하세요.")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.loadNews(isRefresh: isRefresh)
            }
            return
        }
        
        guard let encodedQuery = currentQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return }
        // sort=date로 변경하여 최신 뉴스순으로 정렬
        let urlString = "https://openapi.naver.com/v1/search/news.json?query=\(encodedQuery)&display=\(displayCount)&start=\(currentStart)&sort=date"
        guard let url = URL(string: urlString) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue(clientId, forHTTPHeaderField: "X-Naver-Client-Id")
        request.addValue(clientSecret, forHTTPHeaderField: "X-Naver-Client-Secret")
        
        if isRefresh {
            isLoading = true
        } else {
            isLoadingMore = true
        }
        errorMessage = nil
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            defer {
                DispatchQueue.main.async { [weak self] in
                    self?.currentTask = nil
                    if isRefresh {
                        self?.isLoading = false
                    } else {
                        self?.isLoadingMore = false
                    }
                }
            }
            
            if let error = error as NSError?, error.code == NSURLErrorCancelled {
                return  // 취소된 요청은 무시
            }
            
            if let error = error {
                DispatchQueue.main.async { [weak self] in
                    self?.errorMessage = error.localizedDescription
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async { [weak self] in
                    self?.errorMessage = "데이터가 없습니다."
                }
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let result = try decoder.decode(NaverNewsResponse.self, from: data)
                DispatchQueue.main.async { [weak self] in
                    // Model을 ViewModel로 변환
                    let viewModels = result.items.map { NewsArticleViewModel(from: $0) }
                    
                    if isRefresh {
                        self?.articles = viewModels
                    } else {
                        // 중복 방지: 이미 있는 아이템은 추가하지 않음
                        let newItems = viewModels.filter { newItem in
                            !(self?.articles.contains(where: { $0.link == newItem.link }) ?? false)
                        }
                        self?.articles.append(contentsOf: newItems)
                    }
                    
                    // 받아온 아이템이 displayCount보다 적으면 더 이상 로드할 데이터가 없음
                    if result.items.count < self?.displayCount ?? 10 {
                        self?.canLoadMore = false
                    }
                    
                    if let lastId = self?.articles.last?.id {
                        self?.lastLoadedArticleId = lastId
                    }
                }
            } catch {
                DispatchQueue.main.async { [weak self] in
                    self?.errorMessage = "파싱 오류: \(error.localizedDescription)"
                }
            }
        }
        
        currentTask = task
        task.resume()
    }
}

