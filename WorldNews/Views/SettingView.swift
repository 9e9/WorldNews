//
//  SettingView.swift
//  WorldNews
//
//  Created by 조준희 on 2/9/26.
//

import SwiftUI

struct SettingView: View {
    @AppStorage("appearanceMode") private var appearanceMode: AppearanceMode = .system
    
    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    Text("설정")
                        .font(.largeTitle)
                        .padding(.leading)
                        .bold()
                    Spacer()
                }
                Form {
                    Section(header: Text("화면 모드")) {
                        Picker("화면 모드", selection: $appearanceMode) {
                            ForEach(AppearanceMode.allCases, id: \.self) { mode in
                                Text(mode.rawValue).tag(mode)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
        }
    }
}

// MARK: - Preview
#Preview {
    SettingView()
}
