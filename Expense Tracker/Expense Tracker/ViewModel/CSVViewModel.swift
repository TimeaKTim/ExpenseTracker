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
    @Published var exchangeRates: [String: Double] = [:]

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

            let lines = validContent.components(separatedBy: .newlines)
            let currentCurrency = Locale.current.currency?.identifier ?? "RON"
            var needsExchangeRates = false

            // Skip the first line (header)
            let dataLines = lines.dropFirst()

            // Check if any line contains a different currency
            for line in dataLines {
                let columns = line.components(separatedBy: ",")
                if columns.count > 7 {
                    let currency = columns[7].trimmingCharacters(in: .whitespacesAndNewlines)
                    if currency != currentCurrency {
                        needsExchangeRates = true
                        break
                    }
                }
            }

            // Only fetch exchange rates if needed
            if needsExchangeRates {
                // Wait for the exchange rates to be fetched before continuing
                Task { @MainActor in
                    if let rates = await fetchAllExchangeRatesForLocalCurrency() {
                        // Parse the CSV with the fetched exchange rates
                        await self.parseCSV(content: validContent, context: context, exchangeRates: rates)
                    } else {
                        print("❌ Could not fetch exchange rates.")
                    }
                }
            } else {
                // No need to fetch exchange rates, proceed with empty rates
                print("❌ No need to fetch exchange rates.")
                Task {
                    await self.parseCSV(content: validContent, context: context, exchangeRates: [:])
                }
            }
        }

        url.stopAccessingSecurityScopedResource()
    }
    
    @MainActor
    func parseCSV(content: String, context: ModelContext, exchangeRates: [String: Double]) async {
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
            var transactionSet = Set(existingTransactions.map {
                TransactionKey(title: $0.title, amount: $0.amount, date: $0.dateAdded, category: $0.category)
            })

            let allStores = await shopViewModel.fetchAllStores()
            let storeDict = Dictionary(uniqueKeysWithValues: allStores.map { ($0.title, $0) })

            for row in self.rows {
                guard row.cells.count > 6 else {
                    print("⚠️ Hiba: a sor kevesebb oszlopot tartalmaz, mint a várt 7. Sor tartalma: \(row.cells)")
                    continue
                }

                let dateString = row.cells[3].content
                guard let date = convertToDate(dateString: dateString) else {
                    print("❌ Invalid date: \(dateString)")
                    continue
                }

                let title = row.cells[4].content
                var amount = Double(row.cells[5].content) ?? 0.0
                let category: Category = amount < 0 ? .expense : .income
                let fee = Double(row.cells[6].content) ?? 0.0
                let currency = row.cells[7].content
                
                amount = abs(amount) + fee
                
                if currency != Locale.current.currency?.identifier {
                    if let rate = exchangeRates[currency] {
                        amount /= rate
                    } else {
                        print("⚠️ Missing exchange rate for currency: \(currency)")
                    }
                }


                let transactionKey = TransactionKey(title: title, amount: amount, date: date, category: category.rawValue)
                if transactionSet.contains(transactionKey) {
                    print("Duplicate found")
                    continue
                }

                let newTransaction = Transaction(
                    title: title,
                    remarks: "",
                    amount: amount,
                    dateAdded: date,
                    category: category,
                    shopCategory: "",
                    tintColor: tint,
                    originalAmount: abs(Double(row.cells[5].content) ?? 0.0 ) + (Double(row.cells[6].content) ?? 0.0),
                    originalCurrency: currency
                )

                if let store = storeDict[title] {
                    newTransaction.shopCategory = store.category
                    context.insert(newTransaction)
                } else {
                    transactionsToDisplay.append(newTransaction)
                }

                transactionSet.insert(transactionKey)
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
        let formats = ["yyyy-MM-dd HH:mm:ss", "yyyy-MM-dd", "dd/MM/yyyy"]
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")

        for format in formats {
            formatter.dateFormat = format
            if let date = formatter.date(from: dateString) {
                return date
            }
        }

        print("❌ Invalid date format for: \(dateString)")
        return nil
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
