//
//  ExpenseTrackerAttributes.swift
//  Expense Tracker
//
//  Created by Tímea Kónya on 29.04.2025.
//
import ActivityKit

struct ExpenseTrackerAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var message: String
    }

    var title: String
}

