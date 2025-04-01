//
//  CategoryPickerView.swift
//  Expense Tracker
//
//  Created by Tímea Kónya on 31.03.2025.
//

import SwiftUI
import SwiftData

struct CategoryPickerView: View {
    @Environment(\.modelContext) private var context
    @ObservedObject var viewModel: CSVViewModel
    @StateObject private var shopCategoryViewModel = ShopCategoryViewModel()
    
    @State private var selectedCategories: [String: String] = [:]

    var body: some View {
        VStack {
            Text("Select Category for Transactions")
                .font(.title)
                .padding()

            List(viewModel.transactions, id: \.title) { transaction in
                HStack {
                    Text(transaction.title)
                        .frame(width: 200, alignment: .leading)
                    
                    if shopCategoryViewModel.categories.isEmpty {
                        Text("Loading categories...")
                            .foregroundColor(.gray)
                    } else {
                        Picker("", selection: Binding(
                            get: { selectedCategories[transaction.title] ?? "" },
                            set: { newValue in
                                selectedCategories[transaction.title] = newValue
                                viewModel.selectCategoryForTransaction(transaction: transaction, category: newValue)
                            }
                        )) {
                            Text("").tag("")
                            ForEach(shopCategoryViewModel.categories, id: \.id) { category in
                                Text(category.name).tag(category.name)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                }
            }
            .onAppear {
                shopCategoryViewModel.fetchCategories()
            }

            HStack {
                Button("Save") {
                    saveTransactionsWithCategories()
                }
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)

                Button("Close") {
                    viewModel.isCategoryPickerPresented = false
                }
                .padding()
                .background(Color.gray)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding()
        }
        .padding()
    }

    private func saveTransactionsWithCategories() {
        for transaction in viewModel.transactions {
            if let categoryName = selectedCategories[transaction.title] {
                viewModel.updateTransactionCategory(transaction: transaction, category: categoryName)
            }
        }
        viewModel.saveTransactionsToDatabase(context: context)
        
        viewModel.isCategoryPickerPresented = false
    }
}
