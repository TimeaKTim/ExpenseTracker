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
    @State private var categoryTotals: [CategoryTotal] = []
    @State private var graphType: GraphType = .month
    @State private var selectedMonth: Date = Date()
    @State private var totalExpenseForMonth: Double = 0

    @Namespace private var animation
    
    var body: some View {
        NavigationStack {
            ScrollView(.vertical) {
                HStack(spacing: 0) {
                    ForEach(GraphType.allCases, id: \.rawValue) { type in
                        Text(type.rawValue)
                            .hSpacing()
                            .padding(.vertical, 10)
                            .background {
                                if type == graphType {
                                    Capsule()
                                        .fill(.background)
                                        .matchedGeometryEffect(id: "ACTIVETAB", in: animation)
                                }
                            }
                            .contentShape(.capsule)
                            .onTapGesture {
                                withAnimation(.snappy) {
                                    graphType = type
                                }
                            }
                    }
                }
                .background(.gray.opacity(0.15), in: .capsule)
                .padding(.top, 5)
                
                switch graphType {
                    case .month:
                        MonthlyChart()
                        .transition(.opacity.combined(with: .move(edge: .trailing)))
                    case .category:
                        CategoryChart()
                        .transition(.opacity.combined(with: .move(edge: .trailing)))
                }
            }
            .navigationTitle("Graphs")
            .background(.gray.opacity(0.15))
        }
    }
    
    @ViewBuilder
    func CategoryChart() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(spacing: 10) {
                    Text(format(date: selectedMonth, format: "MMM yyyy"))
                        .font(.title3.bold())
                    Text(currencyString(totalExpenseForMonth, allowedDigits: 1, currencyCode: Locale.current.currencySymbol ?? "RON"))
                        .font(.title3.bold())
                        .multilineTextAlignment(.center)
                    
                    Chart {
                        ForEach(categoryTotals) { data in
                            SectorMark(
                                angle: .value("Amount", data.total),
                                innerRadius: .ratio(0.61),
                                angularInset: 2
                            )
                            .cornerRadius(8)
                            .foregroundStyle(by: .value("Category", data.shopCategory))
                        }
                    }
                    .frame(height: 300)
                    .frame(minWidth: 300, maxWidth: 300)
                    
                    CategoryCard()
                }
            }
            .padding(.top, 15)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Menu {
                    ForEach(uniqueMonths(), id: \.self) { month in
                        Button(format(date: month, format: "MMM yyyy")) {
                            selectedMonth = month
                        }
                    }
                } label: {
                    Label(format(date: selectedMonth, format: "MMM yyyy"), systemImage: "calendar")
                }
            }
        }
        .padding(.horizontal, 10)
        .onAppear {
            calculateCategoryTotals()
        }
        .onChange(of: selectedMonth) {
            calculateCategoryTotals()
        }
    }

    @ViewBuilder
    func CategoryCard() -> some View {
        LazyVStack(spacing: 12) {
            ForEach(categoryTotals) { data in
                let percentage = totalExpenseForMonth == 0 ? 0 : data.total / totalExpenseForMonth
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(data.shopCategory)
                            .font(.headline)
                        Text(currencyString(data.total, currencyCode: Locale.current.currencySymbol ?? "RON"))
                            .font(.subheadline)
                            .foregroundStyle(.gray)
                    }
                    Spacer()
                    Text(String(format: "%.1f%%", percentage * 100))
                        .font(.subheadline.bold())
                        .foregroundColor(.blue)
                }
                .padding()
                .background(.background)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
            }
        }
    }

    @ViewBuilder
    func MonthlyChart() -> some View {
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
        .background(.gray.opacity(0.15))
        .onAppear {
            /// Creating Chart Groups
            createChartGroup()
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
    
    func uniqueMonths() -> [Date] {
        let calendar = Calendar.current
        let months = transactions.map {
            calendar.date(from: calendar.dateComponents([.year, .month], from: $0.dateAdded)) ?? Date()
        }
        return Array(Set(months)).sorted(by: >)
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
    
    func calculateCategoryTotals() {
        let calendar = Calendar.current

            let filtered = transactions.filter {
                $0.category == Category.expense.rawValue &&
                !$0.shopCategory.isEmpty &&
                $0.shopCategory != "Transactions to Others" &&
                calendar.isDate($0.dateAdded, equalTo: selectedMonth, toGranularity: .month)
            }

            let groupedByCategory = Dictionary(grouping: filtered, by: { $0.shopCategory })

            let categoryTotals = groupedByCategory.map { (category, items) in
                let total = items.reduce(0) { $0 + $1.amount }
                return CategoryTotal(shopCategory: category, total: total)
            }

            self.categoryTotals = categoryTotals.sorted { $0.total > $1.total }

            self.totalExpenseForMonth = filtered.reduce(0) { $0 + $1.amount }
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
                let sortedChartGroups = chartGroups.sorted {
                    $0.date > $1.date
                }
                self.chartGroups = sortedChartGroups
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

struct CategorySelectionSheet: View {
    let allCategories: [String]
    @Binding var selectedCategories: Set<String>
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(allCategories.sorted(), id: \.self) { category in
                    MultipleSelectionRow(
                        title: category,
                        isSelected: selectedCategories.contains(category)
                    ) {
                        if selectedCategories.contains(category) {
                            selectedCategories.remove(category)
                        } else {
                            selectedCategories.insert(category)
                        }
                    }
                }
            }
            .navigationTitle("Kategóriák")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kész") {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                }
            }
        }
    }
}

struct MultipleSelectionRow: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.blue)
                }
            }
        }
        .foregroundColor(.primary)
    }
}

#Preview {
    Graphs()
}

