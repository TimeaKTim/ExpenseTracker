//
//  Shop.swift
//  Expense Tracker
//
//  Created by Tímea Kónya on 03.04.2025.
//

import FirebaseFirestore

struct Shop: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var title: String
    var category: String
}
