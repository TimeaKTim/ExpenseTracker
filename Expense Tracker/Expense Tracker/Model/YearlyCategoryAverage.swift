//
//  YearlyCategoryAverage.swift
//  Expense Tracker
//
//  Created by Tímea Kónya on 15.04.2025.
//

import SwiftUI

struct YearlyCategoryAverage: Identifiable {
    let id = UUID()
    let year: Int
    let category: String
    let averagePerYear: Double
}

struct YearCategoryKey: Hashable {
    let year: Int
    let category: String
}

