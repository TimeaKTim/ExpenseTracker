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

            // Meglévő tranzakciók lekérdezése
            let existingTransactions = fetchAllTransactions(context: context)

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

                    let isDuplicate = existingTransactions.contains { existing in
                        existing.title == newTransaction.title &&
                        existing.amount == newTransaction.amount &&
                        existing.dateAdded == newTransaction.dateAdded &&
                        existing.category == newTransaction.category
                    }

                    if !isDuplicate {
                        context.insert(newTransaction)
                    } else {
                        print("Duplicate transaction found, skipping: \(newTransaction)")
                    }
                } else {
                    print("Invalid date format")
                }
            }
        } catch {
            print(error)
        }
    }

    
    func fetchAllTransactions(context: ModelContext) -> [Transaction] {
        // Create a FetchDescriptor to get all Transaction entries
        let fetchDescriptor = FetchDescriptor<Transaction>()

        do {
            // Fetch all transactions
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

    func formatDate(date: Date) -> String {
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "dd MMM yyyy"
        
        return outputFormatter.string(from: date)
    }
}
