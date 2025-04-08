//
//  TransactionKey.swift
//  Expense Tracker
//
//  Created by Tímea Kónya on 08.04.2025.
//

import SwiftUI

struct TransactionKey: Hashable {
    let title: String
    let amount: Double
    let date: Date
    let category: String
}

