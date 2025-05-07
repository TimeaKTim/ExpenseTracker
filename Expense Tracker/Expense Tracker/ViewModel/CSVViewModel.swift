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
import PDFKit

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
            let fileExtension = url.pathExtension.lowercased()
            if fileExtension == "csv" {
                readFile(url, context: context)
            } else if fileExtension == "pdf" {
                Task {
                        await self.extractPDFText(from: url, context: context)
                    }
            } else {
                print("Unsupported file type: \(fileExtension)")
            }
        case .failure(let error):
            print("Error loading file: \(error)")
        }
    }
    
    func extractFirstNumber(from text: String) -> String? {
        let cleanedText = text.replacingOccurrences(of: ",", with: "")
        let pattern = #"\d+\.\d+"#
            
        if let regex = try? NSRegularExpression(pattern: pattern),
           let match = regex.firstMatch(in: cleanedText, range: NSRange(cleanedText.startIndex..., in: cleanedText)) {
            if let range = Range(match.range, in: cleanedText) {
                return String(cleanedText[range])
            }
        }
        return nil
    }
    
    func extractPDFText(from url: URL, context: ModelContext) async{
        guard let document = PDFDocument(url: url) else { return }

        let dateRegex = try! NSRegularExpression(pattern: #"^(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\s+\d{1,2},\s+\d{4}"#)
        let fromToRegex = try! NSRegularExpression(pattern: #"^(To|From):"#)
        let amountLineRegex = try! NSRegularExpression(pattern: #"(\d{1,3}(,\d{3})*(\.\d+)?\s*\w{3})\s+(\d{1,3}(,\d{3})*(\.\d+)?\s*\w{3})"#)
        let currencyRegex = try! NSRegularExpression(pattern: #"\b([A-Z]{3}) Statement\b"#)

        var currentDate: Date?
        var currentTitle: String = ""
        var currentAmount: Double = 0.0
        var currentRemarks: String = ""
        var currentCategory: Category = .expense
        var currentCurrency: String = ""

        var extractedTransactions: [Transaction] = []
        
        let rates = await fetchAllExchangeRatesForLocalCurrency()

        for i in 0..<document.pageCount {
            currentTitle = ""
            currentAmount = 0.0
            currentRemarks = ""
            guard let page = document.page(at: i),
                  let text = page.string else { continue }

            let lines = text.components(separatedBy: .newlines)

            for line in lines {
                let lineRange = NSRange(location: 0, length: line.utf16.count)

                if currencyRegex.firstMatch(in: line, range: lineRange) != nil {
                    let parts = line.components(separatedBy: " ")
                    currentCurrency = parts[0]
                    print(currentCurrency)
                }
                
                if dateRegex.firstMatch(in: line, range: lineRange) != nil {
                    let parts = line.components(separatedBy: " ")
                    let cleanedParts = parts.prefix(3).map { $0.replacingOccurrences(of: ",", with: "") }
                    let dateString = cleanedParts.joined(separator: " ")
                    currentDate = convertToDate(dateString: dateString)

                    let remaining = parts.dropFirst(3).joined(separator: " ")
                    if let number = extractFirstNumber(from: remaining),
                       let amount = Double(number) {
                        currentAmount = amount
                        
                        if currentCurrency != Locale.current.currency?.identifier {
                            if let rate = rates?[currentCurrency] {
                                currentAmount /= rate
                            } else {
                                print("⚠️ Missing exchange rate for currency: \(currentCurrency)")
                            }
                        }

                        let originalNumberRegex = try! NSRegularExpression(pattern: #"\d{1,3}(,\d{3})*(\.\d+)?"#)
                        if let match = originalNumberRegex.firstMatch(in: remaining, range: NSRange(remaining.startIndex..., in: remaining)),
                           let matchRange = Range(match.range, in: remaining) {
                            currentTitle = String(remaining[..<matchRange.lowerBound]).trimmingCharacters(in: .whitespaces)
                        } else {
                            currentTitle = remaining
                        }
                    }

                    if currentTitle == "" {
                        if let referenceRange = remaining.range(of: "Reference:") {
                            let firstPart = remaining[..<referenceRange.lowerBound].trimmingCharacters(in: .whitespaces)
                            
                            currentTitle = firstPart
                        }
                    }
                } else if fromToRegex.firstMatch(in: line, range: lineRange) != nil{
                    currentRemarks = line
                        .replacingOccurrences(of: "To:", with: "")
                        .replacingOccurrences(of: "From:", with: "")
                        .trimmingCharacters(in: .whitespaces)

                    currentCategory = line.hasPrefix("To:") ? .expense : .income
                } else if amountLineRegex.firstMatch(in: line, range: lineRange) != nil && currentAmount == 0.0 && currentTitle != ""{
                    if let amountMatch = amountLineRegex.firstMatch(in: line, range: lineRange) {
                        let amountString = (line as NSString).substring(with: amountMatch.range(at: 1))
                        
                        let amountWithoutCurrency = amountString.components(separatedBy: " ").first ?? ""
                        let cleanedAmount = amountWithoutCurrency.replacingOccurrences(of: ",", with: "")
                        
                        if let amount = Double(cleanedAmount) {
                            currentAmount = amount
                        }
                    }
                }
                if currentTitle.hasPrefix("Exchanged") {
                    currentRemarks = "-"
                }
                
//                print(currentTitle, currentAmount, currentRemarks)
                if currentAmount != 0.0 && currentTitle != ""{
                    let newTransaction = Transaction(
                        title: currentTitle,
                        remarks: currentRemarks,
                        amount: currentAmount,
                        dateAdded: currentDate!,
                        category: currentCategory,
                        shopCategory: "",
                        tintColor: tint,
                        originalAmount: currentAmount,
                        originalCurrency: "RON"
                    )
                    
                    print(newTransaction.title, newTransaction.amount, newTransaction.remarks, newTransaction.category, newTransaction.dateAdded)
                    
                    extractedTransactions.append(newTransaction)
                    
                    currentDate = nil
                    currentTitle = ""
                    currentAmount = 0.0
                    currentRemarks = ""
                }
            }
        }
        
        let existingTransactions = fetchAllTransactions(context: context)
            var transactionSet = Set(existingTransactions.map {
                TransactionKey(title: $0.title, amount: $0.amount, date: $0.dateAdded, category: $0.category)
            })
        
        let allStores = await shopViewModel.fetchAllStores()
        let storeDict = Dictionary(uniqueKeysWithValues: allStores.map { ($0.title, $0) })

        for transaction in extractedTransactions {
            let key = TransactionKey(title: transaction.title, amount: transaction.amount, date: transaction.dateAdded, category: transaction.category)
            if transactionSet.contains(key) && !key.title.hasPrefix("Exchanged") && !key.title.hasPrefix("Transfer") && !key.title.hasPrefix("BudapestGO"){
//                print(key.title, key.amount, key.date, key.category)
                print("🟡 Duplikált tranzakció kihagyva: \(transaction.title)")
                continue
            }

            if let store = storeDict[transaction.title] {
                transaction.shopCategory = store.category
                context.insert(transaction)
            } else {
                await MainActor.run {
                    self.transactions.append(transaction)
                }
            }

            transactionSet.insert(key)
        }

        await MainActor.run {
            self.isCategoryPickerPresented = !self.transactions.isEmpty
        }

    }
    
    func readFile(_ url: URL, context: ModelContext) {
        guard url.startAccessingSecurityScopedResource() else { return }

        do {
            let possibleEncodings: [String.Encoding] = [.utf8]
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
                
                let status = row.cells[8].content
                
                if(status != "COMPLETED") {
                    print("Not Complete Payment Found")
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
        let formats = [
            "yyyy-MM-dd HH:mm:ss",
            "yyyy-MM-dd",
            "dd/MM/yyyy",
            "MMM d yyyy",
            "MMM d, yyyy"
        ]

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "Europe/Bucharest")

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
            guard !transaction.shopCategory.isEmpty else {
                print("⚠️ Skipping transaction \(transaction.title) - no shop category assigned.")
                continue
            }
            
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
