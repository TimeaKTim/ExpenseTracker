//
//  Transaction.swift
//  Expense Tracker
//
//  Created by Tímea Kónya on 10.02.2025.
//

import SwiftUI
import SwiftData

@Model
class Transaction: @unchecked Sendable, Identifiable {
    /// Properties
    var title: String
    var remarks: String
    var amount: Double
    var dateAdded: Date
    var category: String
    var shopCategory: String
    var tintColor: String
    var originalAmount: Double?
    var originalCurrency: String?
    
    init(title: String, remarks: String, amount: Double, dateAdded: Date, category: Category, shopCategory: String, tintColor: TintColor, originalAmount: Double? = nil, originalCurrency: String? = nil) {
        self.title = title
        self.remarks = remarks
        self.amount = amount
        self.dateAdded = dateAdded
        self.category = category.rawValue
        self.shopCategory = shopCategory
        self.tintColor = tintColor.color
        self.originalAmount = originalAmount
        self.originalCurrency = originalCurrency
    }
    
    /// Extracting Color Value from tintColor String
    @Transient
    var color: Color {
        return tints.first(where: { $0.color == tintColor })?.value ?? appTint
    }
    
    @Transient
    var tint: TintColor? {
        return tints.first(where: { $0.color == tintColor })
    }
    
    @Transient
    var rawCategory: Category? {
        return Category.allCases.first(where: { category == $0.rawValue })
    }
}
