//
//  ContentView.swift
//  PCL-Mac
//
//  Created by YiZhiMCQiu on 2025/5/17.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject private var dataManager: DataManager = .shared
    
    var body: some View {
        ZStack {
            createViewFromRouter()
            if let task = dataManager.inprogressInstallTask {
                if case .installing = dataManager.router.getLast() {
                    EmptyView()
                } else {
                    HStack() {
                        Spacer()
                        VStack() {
                            Spacer()
                            RoundedButton {
                                Image("DownloadItem")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 20)
                            } onClick: {
                                dataManager.router.append(.installing(task: task))
                            }
                            .padding()
                        }
                    }
                }
            }
            if let currentPopup = dataManager.currentPopup {
                Group {
                    Rectangle()
                        .fill(Color(hex: 0x000000, alpha: 0.7))
                        .opacity(dataManager.showPopup ? 1 : 0)
                    currentPopup
                        .padding()
                        .opacity(dataManager.showPopup ? 1 : 0)
                    VStack {
                        TitleBarComponent()
                        Spacer()
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: dataManager.showPopup)
            }
        }
    }
    
    private func createSubviewFromRouter() -> some View {
        Group {
            switch dataManager.router.getLast() {
            case .launcher: LauncherView()
            case .download: DownloadView()
            case .multiplayer: MultiplayerView()
            case .settings: SettingsView()
            case .others: OthersView()
            case .installing(let task): InstallingView(task: task)
            case .versionList: VersionListView()
            }
        }
    }
    
    private func createViewFromRouter() -> some View {
        VStack(spacing: 0) {
            if dataManager.router.getLast().isRoot {
                TitleBarComponent()
            } else {
                SubviewTitleBarComponent()
            }
            HStack {
                ZStack {
                    Rectangle()
                        .fill(Color(hex: 0xF5F7FB))
                        .shadow(radius: 2)
                    dataManager.leftTabContent
                }
                .frame(width: dataManager.leftTabWidth)
                .zIndex(1)
                .animation(.linear(duration: 0.05), value: dataManager.leftTabWidth)
                
                createSubviewFromRouter()
                    .foregroundStyle(Color(hex: 0x343D4A))
                    .frame(minWidth: 815 - dataManager.leftTabWidth, minHeight: 418)
                    .zIndex(0)
            }
            .background(
                LocalStorage.shared.theme.getBackgroundView()
            )
        }
        .ignoresSafeArea(.container, edges: .top)
    }
    
    static func setPopup(_ popup: PopupOverlay?) {
        DataManager.shared.currentPopup = popup
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            DataManager.shared.showPopup = true
        }
    }
}

#Preview {
    ContentView()
}
