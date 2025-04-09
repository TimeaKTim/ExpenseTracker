//
//  ExchangeViewModel.swift
//  Expense Tracker
//
//  Created by Tímea Kónya on 09.04.2025.
//

import Foundation

func fetchAllExchangeRatesForLocalCurrency() async -> [String: Double]? {
    let localCurrency = Locale.current.currency?.identifier ?? "RON"
    let apiKey = "17f78f3524eba2abff3ab8b6"
    let urlString = "https://v6.exchangerate-api.com/v6/\(apiKey)/latest/\(localCurrency)"
    
    guard let url = URL(string: urlString) else {
        return nil
    }

    do {
        let (data, _) = try await URLSession.shared.data(from: url)

        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let rates = json["conversion_rates"] as? [String: Double] {
            return rates
        } else {
            print("❌ Invalid exchange rate response format")
            return nil
        }
    } catch {
        print("❌ Exchange rate fetch error: \(error.localizedDescription)")
        return nil
    }
}
