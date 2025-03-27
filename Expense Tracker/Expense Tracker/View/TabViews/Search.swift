//
//  Search.swift
//  Expense Tracker
//
//  Created by Tímea Kónya on 10.02.2025.
//

import SwiftUI
import Combine

struct Search: View {
    /// View Properties
    @State private var searchText: String = ""
    @State private var filterText: String = ""
    @State private var selectedCategory: Category? = nil
    let searchPublisher = PassthroughSubject<String, Never>()
    var body: some View {
        NavigationStack {
            ScrollView(.vertical) {
                LazyVStack(spacing: 12) {
                    transactionsList()
                }
                .padding(15)
            }
            .overlay { searchOverlay() }
            .searchable(text: $searchText)
            .background(.gray.opacity(0.15))
            .navigationTitle("Search")
            .toolbar { searchToolbar() }
            .onChange(of: searchText) { oldValue, newValue in
                handleSearchTextChange(newValue)
            }
            .onReceive(searchPublisher.debounce(for: .seconds(0.3), scheduler: DispatchQueue.main)) { text in
                filterText = text
                print(text)
            }
        }
    }

    @ViewBuilder
    private func transactionsList() -> some View {
        FilterTransactionsView(category: selectedCategory, searchText: filterText) { transactions in
            ForEach(transactions) { transaction in
                NavigationLink {
                    NewExpenseView(editTransaction: transaction, csvViewModel: CSVViewModel())
                } label: {
                    TransactionCardView(transaction: transaction, showCategory: true)
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private func searchOverlay() -> some View {
        if filterText.isEmpty {
            ContentUnavailableView("Search Transactions", systemImage: "magnifyingglass")
                .opacity(1)
        }
    }

    @ToolbarContentBuilder
    private func searchToolbar() -> some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            ToolBarContent()
        }
    }

    private func handleSearchTextChange(_ newValue: String) {
        if newValue.isEmpty {
            filterText = ""
        }
        searchPublisher.send(newValue)
    }

    
    @ViewBuilder
    func ToolBarContent() -> some View {
        Menu {
            Button {
                selectedCategory = nil
            } label: {
                HStack {
                    Text("Both")
                    
                    if selectedCategory == nil {
                        Image(systemName: "checkmark")
                    }
                }
            }
            
            ForEach(Category.allCases, id: \.rawValue) { category in
                Button {
                    selectedCategory = category
                } label: {
                    HStack {
                        Text(category.rawValue)
                        
                        if selectedCategory == category {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            Image(systemName: "slider.vertical.3")
        }
    }
}

#Preview {
    Search()
}
