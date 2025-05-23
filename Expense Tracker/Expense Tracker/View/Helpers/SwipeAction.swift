//
//  SwipeAction.swift
//  Expense Tracker
//
//  Created by Tímea Kónya on 11.02.2025.
//

import SwiftUI

struct SwipeAction<Content: View>: View {
    var cornerRadius: CGFloat = 0
    var direction: SwipeDirection = .trailing
    @ViewBuilder var content: Content
    @ActionBuilder var actions: [Action]
    @Environment(\.colorScheme) private var scheme
    let viewID = UUID()
    @State private var isEnabled: Bool = true
    @State private var scrollOffset: CGFloat = .zero
    
    var body: some View {
        ScrollViewReader { scrollProxy in
            ScrollViewContent(scrollProxy: scrollProxy)
                .scrollIndicators(.hidden)
                .scrollTargetBehavior(.viewAligned)
                .background{
                    if let lastAction = filteredActions .last{
                        Rectangle()
                            .fill(lastAction.tint)
                            .opacity(scrollOffset == .zero ? 0 : 1)
                    }
                }
                .clipShape(.rect(cornerRadius: cornerRadius))
                .rotationEffect(.init(degrees: direction == .leading ? 180 : 0))
        }
        .allowsHitTesting(isEnabled)
        .transition(CustomTransition())
    }
    
    @ViewBuilder
    private func ScrollViewContent(scrollProxy: ScrollViewProxy) -> some View{
        ScrollView(.horizontal){
            LazyHStack(spacing: 0){
                content
                    .rotationEffect(.init(degrees: direction == .leading ? -180 : 0))
                    .containerRelativeFrame(.horizontal)
                    .background(scheme == .dark ? .black : .white)
                    .background{
                        if let firstAction = filteredActions.first{
                            Rectangle()
                                .fill(firstAction.tint)
                                .opacity(scrollOffset == .zero ? 0 : 1)
                        }
                    }
                    .id(viewID)
                    .transition(/*@START_MENU_TOKEN@*/.identity/*@END_MENU_TOKEN@*/)
                    .overlay {
                        GeometryReader {
                            let minX = $0.frame(in: .scrollView(axis: .horizontal)).minX
                            
                            Color.clear
                                .preference(key: OffsetKey.self, value: minX)
                                .onPreferenceChange(OffsetKey.self){
                                    scrollOffset = $0
                                }
                        }
                    }
                
                ActionButtons{
                    withAnimation(.snappy){
                        scrollProxy.scrollTo(viewID, anchor: direction == .trailing ? .topLeading : .topTrailing)
                    }
                }
                .opacity(scrollOffset == .zero ? 0 : 1)
            }
            .scrollTargetLayout()
        }
    }
    
    ///Action Buttons
    @ViewBuilder
    func ActionButtons(resetPosition: @escaping () -> ()) -> some View{
        Rectangle()
            .fill(.clear)
            .frame(width: CGFloat(filteredActions.count)*100)
            .overlay(alignment: direction.alignment){
                HStack(spacing: 0){
                    ForEach(filteredActions){ button in
                        Button(action: {
                            Task{
                                isEnabled = false
                                resetPosition()
                                try? await Task.sleep(for: .seconds(0.25))
                                button.action()
                                try? await Task.sleep(for: .seconds(0.1))
                                isEnabled = true
                            }
                        }, label: {
                            Image(systemName: button.icon)
                                .font(button.iconFont)
                                .foregroundStyle(button.iconTint)
                                .frame(width: 100)
                                .frame(maxHeight: .infinity)
                                .contentShape(.rect)
                        })
                        .buttonStyle(.plain)
                        .background(button.tint)
                        .rotationEffect(.init(degrees: direction == .leading ? -180 : 0))
                    }
                }
            }
    }
    
    @MainActor
    func scrollOffset(_ proxy: GeometryProxy) -> CGFloat {
        let minX = proxy.frame(in: .scrollView(axis: .horizontal)).minX
        return (minX > 0 ? -minX : 0)
    }
    
    var filteredActions: [Action]{
        return actions.filter({$0.isEnabled})
    }
}

struct Action: Identifiable{
    private(set) var id: UUID = .init()
    var tint: Color
    var icon: String
    var iconFont: Font = .title
    var iconTint: Color = .white
    var isEnabled: Bool = true
    var action: () -> ()
}

///Offset Key
struct OffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = .zero
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

///Custom Transition
struct CustomTransition: Transition {
    func body(content: Content, phase: TransitionPhase) -> some View {
        content
            .mask{
                GeometryReader{
                    let size = $0.size
                    
                    Rectangle()
                        .offset(y: phase == .identity ? 0 : -size.height)
                }
                .containerRelativeFrame(.horizontal)
            }
    }
}

enum SwipeDirection {
    case leading
    case trailing
    
    var alignment: Alignment{
        switch self {
        case .leading:
            return .leading
        case .trailing:
            return .trailing
        }
    }
}

@resultBuilder
struct ActionBuilder {
    static func buildBlock(_ components: Action...) -> [Action] {
        return components
    }
}
