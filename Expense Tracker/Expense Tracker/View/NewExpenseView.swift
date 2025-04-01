//
//  NewExpenseView.swift
//  Expense Tracker
//
//  Created by Tímea Kónya on 18.03.2025.
//

import SwiftUI
import WidgetKit
import UniformTypeIdentifiers

struct NewExpenseView: View {
    /// Env Properties
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    var editTransaction: Transaction?
    /// View Properties
    @State private var title: String = ""
    @State private var remarks: String = ""
    @State private var amount: Double = .zero
    @State private var dateAdded: Date = .now
    @State private var category: Category = .expense
    @State private var shopCategory: String = "Select a category"
    @State private var isPresented: Bool = false
    @State private var showHeaders = false
    @State private var showAddCategoryPopup = false
    @State private var newCategoryName = ""

    @ObservedObject var csvViewModel: CSVViewModel
    @StateObject private var shopCategoryViewModel = ShopCategoryViewModel()
    /// Random Tint
    @State var tint: TintColor = tints.randomElement()!
    var body: some View {
        ScrollView(.vertical) {
            VStack(spacing: 15) {
                Text("Preview")
                    .font(.caption)
                    .foregroundStyle(.gray)
                    .hSpacing(.leading)
                
                /// Preview Transaction Card
                TransactionCardView(transaction: .init(
                    title: title.isEmpty ? "Title" : title,
                    remarks: remarks.isEmpty ? "Remarks" : remarks,
                    amount: amount,
                    dateAdded: dateAdded,
                    category: category,
                    shopCategory: shopCategory.isEmpty ? "Category" : shopCategory,
                    tintColor: tint))
                
                CustomSection("Title", "Magic Keyboard", value: $title)
                
                CustomSection("Remarks", "Apple Product", value: $remarks)
                
                /// Amount and Category Check Box
                VStack(alignment: .leading, spacing: 10, content: {
                    Text("Amount & Category")
                        .font(.caption)
                        .foregroundStyle(.gray)
                        .hSpacing(.leading)
                    
                    HStack(spacing: 15){
                        HStack(spacing: 4){
                            Text(currencySymbol)
                                .font(.callout.bold())
                            
                            TextField("0.0", value: $amount, formatter: numberFormatter)
                                .keyboardType(.decimalPad)
                        }
                        .padding(.horizontal, 15)
                        .padding(.vertical, 12)
                        .background(.background, in: .rect(cornerRadius: 10))
                        .frame(maxWidth: 130)
                        
                        CategoryCheckBox()
                    }
                })
                
                HStack(spacing: 15) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Category")
                            .font(.caption)
                            .foregroundStyle(.gray)
                            .hSpacing(.leading)
                        
                        if !shopCategoryViewModel.categories.isEmpty {
                            Picker("Select Category", selection: $shopCategory) {
                                Text("Select a category").tag("Select a category")
                                
                                ForEach(shopCategoryViewModel.categories) { category in
                                    Text(category.name).tag(category.name)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .padding(.horizontal, 15)
                            .padding(.vertical, 12)
                            .background(.background, in: .rect(cornerRadius: 10))
                        } else {
                            Text("Loading categories...")
                                .padding()
                                .foregroundColor(.gray)
                        }
                    }
                    .onAppear {
                        shopCategoryViewModel.fetchCategories()
                    }
                    .onChange(of: shopCategory) { newValue, _ in
                        if newValue != "Select a category" {
                            print("Category selected: \(newValue)")
                        } else {
                            print("No category selected")
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Custom Category")
                            .font(.caption)
                            .foregroundStyle(.gray)
                            .hSpacing(.leading)
                        
                        Button(action: {
                            showAddCategoryPopup = true
                        }) {
                            Text("Add Custom Category")
                                .foregroundColor(Color.accentColor)
                                .padding(.horizontal, 15)
                                .padding(.vertical, 12)
                                .background(.background, in: .rect(cornerRadius: 10))
                        }
                        .sheet(isPresented: $showAddCategoryPopup) {
                            VStack(spacing: 20) {
                                Text("Add New Category")
                                    .font(.title)
                                    .padding()
                                
                                TextField("Enter category name", text: $newCategoryName)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .padding()
                                
                                HStack {
                                    Button("Cancel") {
                                        showAddCategoryPopup = false
                                        newCategoryName = ""
                                    }
                                    .padding()
                                    .background(Color.gray)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                                    
                                    Button("Save") {
                                        if !newCategoryName.isEmpty {
                                            let newCategory = ShopCategory(name: newCategoryName)
                                            showAddCategoryPopup = false
                                            newCategoryName = ""
                                            
                                            shopCategoryViewModel.addCategoryToDatabase(newCategory)
                                        }
                                    }
                                    .padding()
                                    .background(Color.green)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                                }
                                .padding()
                            }
                            .padding()
                        }

                    }
                }

                /// Date Picker
                VStack(alignment: .leading, spacing: 10, content: {
                    Text("Date")
                        .font(.caption)
                        .foregroundStyle(.gray)
                        .hSpacing(.leading)
                    
                    DatePicker("", selection: $dateAdded, displayedComponents: [.date])
                        .datePickerStyle(.graphical)
                        .padding(.horizontal, 15)
                        .padding(.vertical, 12)
                        .background(.background, in: .rect(cornerRadius: 10))
                })
            }
            .padding(15)
        }
        .navigationTitle("\(editTransaction == nil ? "Add" : "Edit") Transaction")
        .background(.gray.opacity(0.15))
        .toolbar(content: {
            ToolbarItem(placement: .topBarLeading){
                Button {
                    isPresented.toggle()
                } label: {
                    Label("Import", systemImage: "square.and.arrow.down")
                }
                .fileImporter(isPresented: $isPresented, allowedContentTypes: [UTType.commaSeparatedText]) { result in
                    csvViewModel.handleFileImport(for: result, context: context)
                }
                .popover(isPresented: $csvViewModel.isCategoryPickerPresented) {
                            CategoryPickerView(viewModel: csvViewModel)
                }
            }
           
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save", action: save)
            }
        })
        .onAppear(perform: {
            if let editTransaction {
                /// Load All Existing Data from the Transaction
                title = editTransaction.title
                remarks = editTransaction.remarks
                dateAdded = editTransaction.dateAdded
                if let category = editTransaction.rawCategory {
                    self.category = category
                }
                amount = editTransaction.amount
                if let tint = editTransaction.tint {
                    self.tint = tint
                }
            }
        })
    }
    
    /// Saving Data
    func save() {
        /// Saving Item to SwiftData
        if editTransaction != nil {
            editTransaction?.title = title
            editTransaction?.remarks = remarks
            editTransaction?.amount = amount
            editTransaction?.dateAdded = dateAdded
            editTransaction?.category = category.rawValue
            editTransaction?.shopCategory = shopCategory
            return
        } else {
            print(shopCategory)
            let transaction = Transaction(title: title, remarks: remarks, amount: amount, dateAdded: dateAdded, category: category, shopCategory: shopCategory, tintColor: tint)
            context.insert(transaction)
        }
        /// Dismissing View
        dismiss()
        /// Updating Widgets
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    @ViewBuilder
    func CustomSection(_ title: String, _ hint: String, value: Binding<String>) -> some View{
        VStack(alignment: .leading, spacing: 10, content: {
            Text(title)
                .font(.caption)
                .foregroundStyle(.gray)
                .hSpacing(.leading)
            
            TextField(hint, text: value)
                .padding(.horizontal, 15)
                .padding(.vertical, 12)
                .background(.background, in: .rect(cornerRadius: 10))
                
        })
    }
    
    /// Custom Check Box
    @ViewBuilder
    func CategoryCheckBox() -> some View {
        HStack(spacing: 10){
            ForEach(Category.allCases, id: \.rawValue) { category in
                HStack(spacing: 5){
                    ZStack {
                        Image(systemName: "circle")
                            .font(.title3)
                            .foregroundStyle(appTint)
                        
                        if self.category == category {
                            Image(systemName: "circle.fill")
                                .font(.caption)
                                .foregroundStyle(appTint)
                            
                        }
                    }
                    
                    Text(category.rawValue)
                        .font(.caption)
                }
                .contentShape(.rect)
                .onTapGesture {
                    self.category = category
                }
            }
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 12)
        .hSpacing(.leading)
        .background(.background, in: .rect(cornerRadius: 10))
    }
    
    /// Number Formatter
    var numberFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        
        return formatter
    }
}

#Preview {
    NavigationStack{
        NewExpenseView(csvViewModel: CSVViewModel())
    }
}
