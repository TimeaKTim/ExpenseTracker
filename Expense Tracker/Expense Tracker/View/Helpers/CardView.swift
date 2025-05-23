//
//  CardView.swift
//  Expense Tracker
//
//  Created by Tímea Kónya on 11.02.2025.
//

import SwiftUI

struct CardView: View {
    var income: Double
    var expense: Double
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 15)
                .fill(.background)
            
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    Text("\(currencyString(income - expense, currencyCode: Locale.current.currencySymbol ?? "RON"))")
                        .font(.title.bold())
                        .foregroundStyle(Color.primary)
                    
                    Image(systemName: expense > income ? "chart.line.downtrend.xyaxis" : "chart.line.uptrend.xyaxis")
                        .font(.title3)
                        .foregroundStyle(expense > income ? .red : .green)
                }
                .padding(.bottom, 25)
                
                HStack(spacing: 0){
                    ForEach(Category.allCases, id: \.rawValue) { category in
                        let symbolInage = category == .income ? "arrow.down" : "arrow.up"
                        let tint = category == .income ? Color.green : Color.red
                        
                        HStack(spacing: 10){
                            Image(systemName: symbolInage)
                                .font(.callout.bold())
                                .foregroundStyle(tint)
                                .frame(width: 35, height: 35)
                                .background {
                                    Circle()
                                        .fill(tint.opacity(0.25).gradient)
                                }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(category.rawValue)
                                    .font(.caption2)
                                    .foregroundStyle(.gray)
                                
                                Text(currencyString(category == .income ? income : expense, allowedDigits: 0, currencyCode: Locale.current.currencySymbol ?? "RON"))
                                    .font(.callout)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(Color.primary)
                            }
                            
                            if category == .income {
                                Spacer(minLength: 10)
                            }
                        }
                    }
                }
            }
            .padding([.horizontal, .bottom], 25)
            .padding(.top, 15)
        }
    }
}

#Preview {
    ScrollView{
        CardView(income: 4590, expense: 2389)
    }
}
