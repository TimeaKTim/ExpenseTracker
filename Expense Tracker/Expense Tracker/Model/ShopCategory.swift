//
//  ShopCategory.swift
//  Expense Tracker
//
//  Created by Tímea Kónya on 31.03.2025.
//

import FirebaseFirestore

struct ShopCategory: Identifiable, Decodable, Hashable {
    @DocumentID var id: String?
    var name: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case name = "Name"
    }
}
