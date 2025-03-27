//
//  Graphs.swift
//  Expense Tracker
//
//  Created by Tímea Kónya on 10.02.2025.
//

import SwiftUI
import Charts
import SwiftData

struct Graphs: View {
    /// View Properties
    @Query(animation: .snappy) private var transactions: [Transaction]
    @State private var chartGroups: [ChartGroup] = []
    var body: some View {
        NavigationStack {
            ScrollView(.vertical){
                LazyVStack(spacing: 10) {
                    ChartView()
                        .frame(height: 200)
                        .padding(10)
                        .padding(.top, 10)
                        .background(.background, in: .rect(cornerRadius: 10))
                    
                    ForEach(chartGroups) { group in
                        VStack(alignment: .leading, spacing: 10) {
                            Text(format(date: group.date, format: "MMM yy"))
                                .font(.caption2)
                                .foregroundStyle(.gray)
                                .hSpacing(.leading)
                            
                            NavigationLink {
                                ListOfExpenses(month: group.date)
                            } label: {
                                CardView(income: group.totalIncome, expense: group.totalExpense)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(15)
                }
                .navigationTitle("Graphs")
                .background(.gray.opacity(0.15))
                .onAppear {
                    /// Creating Chart Groups
                    createChartGroup()
                }
            }
        }
    }
        @ViewBuilder
        func ChartView() -> some View {
            Chart {
                chartBars
            }
            /// Making Chart Scrollable
            .chartScrollableAxes(.horizontal)
            .chartXVisibleDomain(length: 4)
            .chartLegend(position: .bottom, alignment: .trailing)
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    let doubleValue = value.as(Double.self) ?? 0
                    
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel {
                        Text(axisLabel(doubleValue)) // Wrap string in Text
                    }
                }
            }
            /// Foreground Colors
            .chartForegroundStyleScale(range: [Color.green.gradient, Color.red.gradient])
        }

        var chartBars: some ChartContent {
            ForEach(chartGroups) { group in
                ForEach(group.categories) { chart in
                    BarMark(
                        x: .value("Month", format(date: group.date, format: "MMM yy")),
                        y: .value(chart.category.rawValue, chart.totalValue),
                        width: 20
                    )
                    .position(by: .value("Category", chart.category.rawValue), axis: .horizontal)
                    .foregroundStyle(by: .value("Category", chart.category.rawValue))
                }
            }
        }
        
    func createChartGroup() {
        Task.detached(priority: .high) {
            let calendar = Calendar.current
            
            // Grouping transactions by month and year
            let groupByDate = await Dictionary(grouping: transactions) { transaction in
                let components = calendar.dateComponents([.month, .year], from: transaction.dateAdded)
                return components
            }
            
            // Sorting Groups By Date
            let sortedGroups = groupByDate.sorted {
                let date1 = calendar.date(from: $0.key) ?? .init()
                let date2 = calendar.date(from: $1.key) ?? .init()
                return calendar.compare(date1, to: date2, toGranularity: .day) == .orderedDescending
            }
            
            // Use Task to run async logic inside the task group
            let chartGroups = await withTaskGroup(of: ChartGroup?.self) { group in
                // Iterate over sorted groups and add async tasks to the group
                for dict in sortedGroups {
                    group.addTask {
                        let date = calendar.date(from: dict.key) ?? .init()
                        let income = dict.value.filter { $0.category == Category.income.rawValue }
                        let expense = dict.value.filter { $0.category == Category.expense.rawValue }
                        
                        // Using await to call async total function
                        let incomeTotalValue = await total(income, category: .income)
                        let expenseTotalValue = await total(expense, category: .expense)
                        
                        return ChartGroup(
                            date: date,
                            categories: [
                                .init(totalValue: incomeTotalValue, category: .income),
                                .init(totalValue: expenseTotalValue, category: .expense)
                            ],
                            totalIncome: incomeTotalValue,
                            totalExpense: expenseTotalValue
                        )
                    }
                }
                // Collecting results and returning them as an array
                var results: [ChartGroup] = []
                for await result in group {
                    if let chartGroup = result {
                        results.append(chartGroup)
                    }
                }
                return results
            }
            
            // UI update must be done on the main thread
            await MainActor.run {
                self.chartGroups = chartGroups
            }
        }
    }
        
        func axisLabel(_ value: Double) -> String {
            let intValue = Int(value)
            let kValue = intValue / 1000
            
            return intValue < 1000 ? "\(intValue)" :"\(kValue)K"
        }
    }
    
/// List of Transactions for the Selected Month
struct ListOfExpenses: View {
    let month: Date
    
    var body: some View {
        ScrollView(.vertical) {
            LazyVStack(spacing: 15) {
                incomeSection
                expenseSection
            }
            .padding(15)
        }
        .background(.gray.opacity(0.15))
        .navigationTitle(format(date: month, format: "MMM yy"))
    }
    
    private var incomeSection: some View {
        Section {
            FilterTransactionsView(satrtDate: month.startOfMonth, endDate: month.endOfMonth, category: .income
            ) { transactions in
                ForEach(transactions) { transaction in
                    transactionLink(transaction)
                }
            }
        } header: {
            Text("Income")
                .font(.caption)
                .foregroundStyle(.gray)
                .hSpacing(.leading)
        }
    }
    
    private var expenseSection: some View {
        Section {
            FilterTransactionsView(satrtDate: month.startOfMonth, endDate: month.endOfMonth, category: .expense
            ) { transactions in
                ForEach(transactions) { transaction in
                    transactionLink(transaction)
                }
            }
        } header: {
            Text("Expense")
                .font(.caption)
                .foregroundStyle(.gray)
                .hSpacing(.leading)
        }
    }
    
    private func transactionLink(_ transaction: Transaction) -> some View {
        NavigationLink {
            NewExpenseView(editTransaction: transaction, csvViewModel: CSVViewModel())
        } label: {
            TransactionCardView(transaction: transaction)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    Graphs()
}
