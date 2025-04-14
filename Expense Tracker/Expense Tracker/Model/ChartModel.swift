//
//  ChartModel.swift
//  Expense Tracker
//
//  Created by Tímea Kónya on 25.03.2025.
//

import SwiftUI

struct ChartGroup: Identifiable {
    let id: UUID = .init()
    var date: Date
    var categories: [ChartCategory]
    var totalIncome: Double
    var totalExpense: Double
}

struct CategoryTotal: Identifiable {
    var id: String { shopCategory }
    let shopCategory: String
    let total: Double
}

struct ChartCategory: Identifiable {
    let id: UUID = .init()
    var totalValue: Double
    var category: Category
}
