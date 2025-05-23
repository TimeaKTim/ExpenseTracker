//
//  Recents.swift
//  Expense Tracker
//
//  Created by Tímea Kónya on 10.02.2025.
//

import SwiftUI
import SwiftData

struct Recents: View {
    /// User Properties
    @AppStorage("userName") private var userName: String = ""
    /// View Properties
    @State private var startDate: Date = .now.startOfMonth
    @State private var endDate: Date = .now.endOfMonth
    @State private var showFilterView: Bool = false
    @State private var selectedCategory: Category = .expense
    /// For Animation
    @Namespace private var animation
    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size

            NavigationStack {
                ScrollView(.vertical) {
                    LazyVStack(spacing: 10, pinnedViews: [.sectionHeaders]) {
                        transactionsSection(size)
                    }
                    .padding(15)
                }
                .background(.gray.opacity(0.15))
                .blur(radius: showFilterView ? 8 : 0)
                .disabled(showFilterView)
                .navigationDestination(for: Transaction.self) { transaction in
                    NewExpenseView(editTransaction: transaction, csvViewModel: CSVViewModel())
                }
            }
            .overlay { filterOverlay() }
            .animation(.snappy, value: showFilterView)
        }
    }

    @ViewBuilder
    private func transactionsSection(_ size: CGSize) -> some View {
        Section {
            dateFilterButton()
            filteredTransactionsView()
        } header: {
            HeaderView(size)
        }
    }

    private func dateFilterButton() -> some View {
        Button(action: {
            showFilterView = true
        }) {
            Text("\(format(date: startDate, format: "dd - MMM yy")) to \(format(date: endDate, format: "dd - MMM yy"))")
                .font(.caption)
                .foregroundStyle(.gray)
        }
        .hSpacing(.leading)
    }

    private func filteredTransactionsView() -> some View {
        FilterTransactionsView(satrtDate: startDate, endDate: endDate) { transactions in
            LazyVStack {
                CardView(
                    income: total(transactions, category: .income),
                    expense: total(transactions, category: .expense)
                )
                
                CustomSegmentedControl()
                    .padding(.bottom, 10)
                let filtered = transactions.filter { $0.category == selectedCategory.rawValue }
                ForEach(filtered) { transaction in
                    NavigationLink(destination: NewExpenseView(editTransaction: transaction, csvViewModel: CSVViewModel())) {
                        TransactionCardView(transaction: transaction)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    @ViewBuilder
    private func filterOverlay() -> some View {
        if showFilterView {
            DateFilterView(
                start: startDate,
                end: endDate,
                onSubmit: { start, end in
                    startDate = start
                    endDate = end
                    showFilterView = false
                },
                onClose: {
                    showFilterView = false
                }
            )
            .transition(.move(edge: .leading))
        }
    }

    
    /// Header View
    @ViewBuilder
    func HeaderView(_ size: CGSize) -> some View {
        HStack(spacing: 10){
            VStack(alignment: .leading, spacing: 5, content: {
                Text("Welcome!")
                    .font(.title.bold())
                
                if !userName.isEmpty {
                    Text(userName)
                        .font(.callout)
                        .foregroundStyle(.gray)
                }
            })
            .visualEffect { content, geometryProxy in
                content
                    .scaleEffect(MainActor.assumeIsolated {
                        headerScale(size, proxy: geometryProxy)
                    }, anchor: .topLeading)
            }
            
            Spacer(minLength: 0)

            NavigationLink {
                NewExpenseView(csvViewModel: CSVViewModel())
            } label: {
                Image(systemName: "plus")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(width: 45, height: 45)
                    .background(appTint.gradient, in: .circle)
                    .contentShape(.circle)
            }
        }
        .padding(.bottom, userName.isEmpty ? 10 : 5)
        .background {
            VStack(spacing: 0){
                Rectangle()
                    .fill(.ultraThinMaterial)
                
                Divider()
            }
            .visualEffect { content, geometryProxy in
                content
                    .opacity(MainActor.assumeIsolated {
                        headerBGOpacity(geometryProxy)
                    })
            }
            .padding(.horizontal, -15)
            .padding(.top, -(safeArea.top + 15))
        }
    }
    
    @ViewBuilder
    func CustomSegmentedControl() -> some View {
        HStack(spacing: 0) {
            ForEach(Category.allCases, id: \.rawValue) { category in
                Text(category.rawValue)
                    .hSpacing()
                    .padding(.vertical, 10)
                    .background {
                        if category == selectedCategory {
                            Capsule()
                                .fill(.background)
                                .matchedGeometryEffect(id: "ACTIVETAB", in: animation)
                        }
                    }
                    .contentShape(.capsule)
                    .onTapGesture {
                        withAnimation(.snappy) {
                            selectedCategory = category
                        }
                    }
            }
        }
        .background(.gray.opacity(0.15), in: .capsule)
        .padding(.top, 5)
    }
    
    @MainActor
    func headerBGOpacity(_ proxy: GeometryProxy) -> CGFloat {
        let minY = proxy.frame(in: .scrollView).minY + safeArea.top
        return minY > 0 ? 0 : (-minY / 15)
    }
    
    @MainActor
    func headerScale(_ size: CGSize, proxy: GeometryProxy) -> CGFloat {
        let minY = proxy.frame(in: .scrollView).minY
        let screenHeight = size.height
        
        let progress = minY / screenHeight
        let scale = (min(max(progress, 0), 1)) * 0.4
        
        return 1 + scale
    }
}

#Preview {
    ContentView()
}
