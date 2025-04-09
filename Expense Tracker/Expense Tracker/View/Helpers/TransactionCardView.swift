//
//  TransactionCardView.swift
//  Expense Tracker
//
//  Created by Tímea Kónya on 11.02.2025.
//

import SwiftUI

struct TransactionCardView: View {
    @Environment(\.modelContext) private var context
    var transaction: Transaction
    var showCategory: Bool = false
    var body: some View {
        SwipeAction(cornerRadius: 10, direction: .trailing){
            HStack(spacing: 12) {
                Text("\(String(transaction.title.prefix(1)))")
                    .font(.title)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(width: 45, height: 45)
                    .background(transaction.color.gradient, in: .circle)
                
                VStack(alignment: .leading, spacing: 4, content: {
                    Text(transaction.title)
                        .foregroundStyle(Color.primary.secondary)
                    
                    Text(transaction.remarks)
                        .font(.callout)
                        .foregroundStyle(Color.primary.secondary)
                    
                    Text(transaction.shopCategory)
                        .font(.callout)
                        .foregroundStyle(Color.primary.secondary)
                    
                    Text(format(date: transaction.dateAdded, format: "dd MMM yyyy"))
                        .font(.caption2)
                        .foregroundStyle(.gray)
                    
                    if showCategory {
                        Text(transaction.category)
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .foregroundStyle(.white)
                            .background(transaction.category == Category.income.rawValue ? Color.green.gradient : Color.red.gradient, in: .capsule)
                    }
                })
                .lineLimit(1)
                .hSpacing(.leading)
                
                VStack(spacing: 10){
                    Text(currencyString(transaction.amount, allowedDigits: 1, currencyCode: Locale.current.currencySymbol ?? "RON"))
                        .fontWeight(.semibold)
                    if let original = transaction.originalAmount,
                       let currency = transaction.originalCurrency,
                       currency != Locale.current.currency?.identifier {
                        Text("\(currencyString(original, allowedDigits: 1, currencyCode: currency))")
                            .font(.caption2)
                            .foregroundStyle(.gray)
                    }
                }
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 10)
            .background(.background, in: .rect(cornerRadius: 10))
        } actions: {
            Action(tint: .red, icon: "trash"){
                context.delete(transaction)
            }
        }
    }
}

#Preview {
    ContentView()
}
