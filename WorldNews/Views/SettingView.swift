//
//  SettingView.swift
//  WorldNews
//
//  Created by 조준희 on 2/9/26.
//

import SwiftUI

struct SettingView: View {
    @State private var isDarkMode: Bool = false
    
    var body: some View {
        VStack (spacing: 20) {
            HStack {
                Text("설정")
                    .font(.largeTitle)
                    .padding(.leading)
                    .bold()
                Spacer()
            }
            
            VStack {
                Text("화면 모드")
                    .font(.title3)
                    .bold()
                HStack(spacing: 30) {
                    Button(action: {
                        isDarkMode = false
                        UIApplication.shared.windows.first?.overrideUserInterfaceStyle = .light
                    }) {
                        Text("라이트 모드")
                            .padding()
                            .background(isDarkMode ? Color.gray.opacity(0.3) : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    Button(action: {
                        isDarkMode = true
                        UIApplication.shared.windows.first?.overrideUserInterfaceStyle = .dark
                    }) {
                        Text("다크 모드")
                            .padding()
                            .background(isDarkMode ? Color.blue : Color.gray.opacity(0.3))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }

            }
            Spacer()
        }
    }
}

// MARK: - Preview
#Preview {
    SettingView()
}
