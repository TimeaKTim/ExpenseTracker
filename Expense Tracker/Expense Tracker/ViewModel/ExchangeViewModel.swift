//
//  ExchangeViewModel.swift
//  Expense Tracker
//
//  Created by Tímea Kónya on 09.04.2025.
//

import Foundation

func fetchAllExchangeRatesForLocalCurrency(completion: @escaping ([String: Double]?) -> Void) {
    let localCurrency = Locale.current.currency?.identifier ?? "RON"
    let apiKey = "17f78f3524eba2abff3ab8b6"
    let urlString = "https://v6.exchangerate-api.com/v6/\(apiKey)/latest/\(localCurrency)"
    
    guard let url = URL(string: urlString) else {
        completion(nil)
        return
    }

    URLSession.shared.dataTask(with: url) { data, _, error in
        guard let data = data, error == nil else {
            print("❌ Exchange rate fetch error: \(error?.localizedDescription ?? "unknown")")
            completion(nil)
            return
        }

        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let rates = json["conversion_rates"] as? [String: Double] {
                completion(rates)
            } else {
                print("❌ Invalid exchange rate response format")
                completion(nil)
            }
        } catch {
            print("❌ Failed to parse exchange rate JSON: \(error.localizedDescription)")
            completion(nil)
        }
    }.resume()
}
