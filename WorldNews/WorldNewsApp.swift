//
//  WorldNewsApp.swift
//  WorldNews
//
//  Created by 조준희 on 2/9/26.
//

import SwiftUI
import SwiftData
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

@main
struct WorldNewsApp: App {
    // Firebase 설정을 위한 AppDelegate 등록
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var sharedModelContainer: ModelContainer = {
        do {
            return try ModelContainer(for: Schema([]), configurations: [ModelConfiguration(schema: Schema([]), isStoredInMemoryOnly: false)])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
