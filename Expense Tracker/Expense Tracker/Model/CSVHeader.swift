//
//  CSVHeader.swift
//  Expense Tracker
//
//  Created by Tímea Kónya on 27.03.2025.
//

import SwiftUI

struct CSVHeader: Identifiable {
    var id: UUID = UUID()
    var name: String
    var columnIndex: Int = 0
    
    static func createHeaders(data: [String]) -> [CSVHeader] {
        var headers = data.map({ CSVHeader(name: $0) })
        
        var index = 0
        for(i,_) in headers.enumerated() {
            headers[i].columnIndex = index
            index += 1
        }
        
        return headers
    }
}

struct CSVRow: Identifiable {
    var id: UUID = UUID()
    var cells: [CSVCell]
}

struct CSVCell: Identifiable {
    var id: UUID = UUID()
    var content: String
}
