//
//  MyPickerComponent.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 2025/7/27.
//

import SwiftUI

struct MyPickerComponent<Entry: Hashable>: View {
    @ObservedObject private var overlayManager: OverlayManager = .shared
    @Binding private var selected: Entry
    @State private var isHovered: Bool = false
    @State private var showMenu: Bool = false
    @State private var overlayId: UUID? = nil
    @FocusState private var isFocused: Bool
    
    private let entries: [Entry]
    private let getText: (Entry) -> String
    
    init(selected: Binding<Entry>, entries: [Entry], textProvider: @escaping (Entry) -> String) {
        self._selected = selected
        self.entries = entries
        self.getText = textProvider
    }
    
    var body: some View {
        MyGeometryReader { geo in
            ZStack(alignment: .leading) {
                HStack {
                    Text(getText(selected))
                        .font(.custom("PCL English", size: 14))
                        .foregroundStyle(Color("TextColor"))
                        .onHover { hover in
                            self.isHovered = hover
                        }
                        .padding(.leading, 5)
                        .lineLimit(1)
                    Spacer()
                    Image("FoldController")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 14, height: 14)
                        .rotationEffect(.degrees(showMenu ? 180 : 0), anchor: .center)
                        .foregroundStyle(self.isHovered ? Color(hex: 0x4890F5) : Color(hex: 0x96C0F9))
                        .padding(.trailing, 5)
                }
                .animation(.easeInOut(duration: 0.3), value: showMenu)
                
                RoundedRectangle(cornerRadius: 4)
                    .stroke(self.isHovered ? Color(hex: 0x4890F5) : Color(hex: 0x96C0F9), lineWidth: 1)
                    .allowsHitTesting(false)
            }
            .animation(.easeInOut(duration: 0.1), value: self.isHovered)
            .frame(height: 27)
            .contentShape(Rectangle())
            .onTapGesture {
                if let overlayId = overlayId {
                    overlayManager.removeOverlay(with: overlayId)
                    self.overlayId = nil
                } else if let geo = geo {
                    let frame = geo.frame(in: .global)
                    overlayId = overlayManager.addOverlay(
                        view: PickerMenu(entries: entries.filter { $0 != selected }, onSelect: { selected = $0 ; overlayManager.removeOverlay(with: self.overlayId!) }, getText: getText)
                            .frame(width: geo.size.width)
                            .foregroundStyle(Color(hex: 0x4890F5)),
                        at: CGPoint(x: frame.minX, y: frame.maxY)
                    )
                }
            }
            .onChange(of: isFocused) { newValue in
                if newValue == false, let overlayId = overlayId {
                    overlayManager.removeOverlay(with: overlayId)
                }
            }
        }
        .onDisappear {
            if let overlayId = overlayId {
                overlayManager.removeOverlay(with: overlayId)
                self.overlayId = nil
            }
        }
    }
}

fileprivate struct PickerMenu<Entry: Hashable>: View {
    let entries: [Entry]
    let onSelect: (Entry) -> Void
    let getText: (Entry) -> String
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                ForEach(entries, id: \.self) { entry in
                    MyListItemComponent {
                        HStack {
                            Text(getText(entry))
                                .font(.custom("PCL English", size: 14))
                                .foregroundStyle(Color("TextColor"))
                                .padding(.leading, 5)
                            Spacer()
                        }
                        .frame(height: 27)
                    }
                    .onTapGesture {
                        onSelect(entry)
                    }
                }
            }
            .background {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color("MyCardBackgroundColor"))
                    .shadow(color: Color("TextColor").opacity(0.2), radius: 4)
            }
            .background {
                RoundedRectangle(cornerRadius: 4)
                    .stroke(.primary)
            }
        }
    }
}
