//
//  CSVViewModel.swift
//  Expense Tracker
//
//  Created by Tímea Kónya on 27.03.2025.
//

import SwiftUI
import SwiftCSV
import SwiftData
import Foundation

class CSVViewModel: ObservableObject {
    @Published var content: String = ""
    @Published var headers: [CSVHeader] = []
    @Published var rows: [CSVRow] = []
    @Published var transactions: [Transaction] = []  // Store all parsed transactions here
    @Published var selectedTransaction: Transaction? = nil
    @Published var isCategoryPickerPresented: Bool = false
    @Published var categoryToAssign: Category? = nil // Store the selected category for each transaction
    
    @State var tint: TintColor = tints.randomElement()!
    
    func handleFileImport(for result: Result<URL, Error>, context: ModelContext) {
        switch result {
        case .success(let url):
            readFile(url, context: context)
        case .failure(let error):
            print("Error loading file: \(error)")
        }
    }
    
    func readFile(_ url: URL, context: ModelContext) {
        guard url.startAccessingSecurityScopedResource() else { return }
        
        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            self.content = content
            parseCSV(content: content, context: context)
        } catch {
            print("Error reading file: \(error)")
        }
        
        url.stopAccessingSecurityScopedResource()
    }
    
    func parseCSV(content: String, context: ModelContext) {
        do {
            let data = try EnumeratedCSV(string: content, loadColumns: false)
            
            self.headers = CSVHeader.createHeaders(data: data.header)
            self.rows = data.rows.map { CSVRow(cells: $0.map { CSVCell(content: $0) }) }
            
            var transactionsToDisplay: [Transaction] = []
            
            for row in self.rows {
                let dateString = row.cells[3].content
                
                if let date = convertToDate(dateString: dateString) {
                    let title = row.cells[4].content
                    var amount = Double(row.cells[5].content)!
                    let category: Category = amount < 0 ? .expense : .income
                    let fee = Double(row.cells[6].content)!
                    amount = abs(amount) + fee
                    
                    let newTransaction = Transaction(
                        title: title,
                        remarks: "",
                        amount: amount,
                        dateAdded: date,
                        category: category,
                        shopCategory: "",
                        tintColor: tint
                    )
                    
                    let existingTransactions = fetchAllTransactions(context: context)
                    let isDuplicate = existingTransactions.contains { existing in
                        existing.title == newTransaction.title &&
                        existing.amount == newTransaction.amount &&
                        existing.dateAdded == newTransaction.dateAdded &&
                        existing.category == newTransaction.category
                    }
                    
                    if !isDuplicate {
                        transactionsToDisplay.append(newTransaction)
                    } else {
                        print("Duplicate transaction found, skipping: \(newTransaction)")
                    }
                } else {
                    print("Invalid date format")
                }
            }
            
            self.transactions = transactionsToDisplay
            
            isCategoryPickerPresented = true
            
        } catch {
            print("Error parsing CSV: \(error)")
        }
    }
    
    func selectCategoryForTransaction(transaction: Transaction, category: String) {
        // Here, you would update the transaction's category
        if let index = transactions.firstIndex(where: { $0.title == transaction.title }) {
            transactions[index].shopCategory = category
        }
        print("Category selected: \(category) for transaction \(transaction.title)")
    }
    
    func fetchAllTransactions(context: ModelContext) -> [Transaction] {
        let fetchDescriptor = FetchDescriptor<Transaction>()
        
        do {
            let transactions = try context.fetch(fetchDescriptor)
            return transactions
        } catch {
            print("Error fetching transactions: \(error)")
            return []
        }
    }
    
    func convertToDate(dateString: String) -> Date? {
        let originalFormatter = DateFormatter()
        originalFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        if let date = originalFormatter.date(from: dateString) {
            return date
        } else {
            print("Invalid date string format")
            return nil
        }
    }
    
    func updateTransactionCategory(transaction: Transaction, category: String) {
            if let index = transactions.firstIndex(where: { $0.id == transaction.id }) {
                transactions[index].shopCategory = category
            }
    }

    func saveTransactionsToDatabase(context: ModelContext) {
        for transaction in transactions {
            context.insert(transaction)
            print("✅ Transactions saved to database!")
        }
    }
}
