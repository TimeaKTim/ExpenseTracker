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

class CSVViewModel: ObservableObject, @unchecked Sendable {
    @Published var content: String = ""
    @Published var headers: [CSVHeader] = []
    @Published var rows: [CSVRow] = []
    @Published var transactions: [Transaction] = []
    @Published var selectedTransaction: Transaction? = nil
    @Published var isCategoryPickerPresented: Bool = false
    @Published var categoryToAssign: Category? = nil
    @Published var shopViewModel = ShopCategoryViewModel()
    
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
            let possibleEncodings: [String.Encoding] = [.utf8, .isoLatin1, .windowsCP1252]
            var content: String? = nil

            for encoding in possibleEncodings {
                if let decoded = try? String(contentsOf: url, encoding: encoding) {
                    content = decoded
                    break
                }
            }
            
            guard let validContent = content else {
                print("❌ Error: Could not decode file with supported encodings.")
                return
            }
            
            self.content = validContent
            Task {
                await parseCSV(content: validContent, context: context)
            }
        }
        
        url.stopAccessingSecurityScopedResource()
    }

    
    @MainActor
    func parseCSV(content: String, context: ModelContext) async {
        do {
            let data = try EnumeratedCSV(string: content, loadColumns: false)
            if data.header.isEmpty {
                print("❌ Error: CSV header is empty or malformed")
                return
            }


            await MainActor.run {
                self.headers = CSVHeader.createHeaders(data: data.header)
                self.rows = data.rows.map { CSVRow(cells: $0.map { CSVCell(content: $0) }) }
            }

            var transactionsToDisplay: [Transaction] = []
            
            let existingTransactions = fetchAllTransactions(context: context)
            var transactionSet = Set(existingTransactions.map { "\($0.title)|\($0.amount)|\($0.dateAdded)|\($0.category)" })

            for row in self.rows {
                guard row.cells.count > 6 else {
                    print("⚠️ Hiba: a sor kevesebb oszlopot tartalmaz, mint a várt 7. Sor tartalma: \(row.cells)")
                    continue
                }

                let dateString = row.cells[3].content
                if let date = convertToDate(dateString: dateString) {
                    let title = row.cells[4].content
                    var amount = Double(row.cells[5].content) ?? 0.0
                    let category: Category = amount < 0 ? .expense : .income
                    let fee = Double(row.cells[6].content) ?? 0.0
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

                    let transactionKey = "\(newTransaction.title)|\(newTransaction.amount)|\(newTransaction.dateAdded)|\(newTransaction.category)"

                    if transactionSet.contains(transactionKey) {
                        continue
                    }

                    if let store = await shopViewModel.fetchStoreByTitle(title: newTransaction.title) {
                        newTransaction.shopCategory = store.category
                        context.insert(newTransaction)
                    } else {
                        transactionsToDisplay.append(newTransaction)
                    }

                    transactionSet.insert(transactionKey)
                } else {
                    print("Invalid date format")
                }
            }

            await MainActor.run {
                self.transactions = transactionsToDisplay
                self.isCategoryPickerPresented = !transactionsToDisplay.isEmpty
            }

        } catch {
            print("Error parsing CSV: \(error)")
        }
    }
    
    func selectCategoryForTransaction(transaction: Transaction, category: String) {
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

    @MainActor
    func saveTransactionsToDatabase(context: ModelContext) {
        var uniqueShops: [String: Shop] = [:]
        
        for transaction in transactions {
            context.insert(transaction)
            print("✅ Transactions saved to database!")
            
            if uniqueShops[transaction.title] == nil {
                let newShop = Shop(title: transaction.title, category: transaction.shopCategory)
                uniqueShops[transaction.title] = newShop
            }
        }

        let uniqueShopSet = Set(uniqueShops.values)
        
        Task {
            await shopViewModel.saveShopsToDatabase(uniqueShopSet)
        }
    }

}
