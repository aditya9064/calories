import SwiftUI
import Charts

struct SummaryView: View {
    @EnvironmentObject var store: CalorieStore
    @EnvironmentObject var healthKit: HealthKitManager
    @State private var selectedPeriod: SummaryPeriod = .week

    private var summaries: [DaySummary] {
        store.daySummaries(for: selectedPeriod, healthKit: healthKit)
    }

    private var totalNet: Double { summaries.reduce(0) { $0 + $1.netCalories } }
    private var isSurplusPeriod: Bool { totalNet > 0 }

    var body: some View {
        NavigationView {
            ZStack {
                Color.tradeDark.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        periodSelector
                        periodSummaryCard
                        chartCard
                        dailyBreakdown
                    }
                    .padding()
                }
            }
            .navigationBarHidden(true)
        }
    }

    // MARK: - Period Selector

    private var periodSelector: some View {
        HStack {
            Text("PORTFOLIO SUMMARY")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(.gray)
            Spacer()
            HStack(spacing: 0) {
                ForEach(SummaryPeriod.allCases, id: \.self) { period in
                    Button(action: { selectedPeriod = period }) {
                        Text(period.rawValue)
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .foregroundColor(selectedPeriod == period ? .black : .gray)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(selectedPeriod == period ? Color.tradeGreen : Color.clear)
                            .cornerRadius(6)
                    }
                }
            }
            .background(Color.tradePanel)
            .cornerRadius(8)
        }
    }

    // MARK: - Period Summary Card

    private var periodSummaryCard: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(periodLabel)
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundColor(.gray)
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text(isSurplusPeriod ? "+" : "")
                            .font(.system(size: 28, weight: .bold, design: .monospaced))
                            .foregroundColor(isSurplusPeriod ? .tradeGreen : .tradeRed)
                        Text(String(format: "%.0f", abs(totalNet)))
                            .font(.system(size: 40, weight: .bold, design: .monospaced))
                            .foregroundColor(isSurplusPeriod ? .tradeGreen : .tradeRed)
                        Text("kcal")
                            .font(.system(size: 14))
                            .foregroundColor((isSurplusPeriod ? Color.tradeGreen : Color.tradeRed).opacity(0.7))
                            .padding(.bottom, 4)
                    }
                    Text(isSurplusPeriod ? "CALORIC SURPLUS" : "CALORIC DEFICIT")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(isSurplusPeriod ? .tradeGreen : .tradeRed)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 8) {
                    statBadge(label: "AVG/DAY", value: summaries.isEmpty ? 0 : totalNet / Double(summaries.count))
                    statBadge(label: "SURPLUS DAYS",
                              value: Double(summaries.filter { $0.isSurplus }.count),
                              isCount: true)
                }
            }
        }
        .padding(16)
        .background(Color.tradePanel)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke((isSurplusPeriod ? Color.tradeGreen : Color.tradeRed).opacity(0.3), lineWidth: 1)
        )
    }

    private var periodLabel: String {
        switch selectedPeriod {
        case .day: return "TODAY"
        case .week: return "THIS WEEK"
        case .month: return "THIS MONTH"
        }
    }

    private func statBadge(label: String, value: Double, isCount: Bool = false) -> some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text(label)
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundColor(.gray)
            let isSurp = value > 0
            Text(isCount ? String(format: "%.0f", value) : (isSurp ? "+" : "") + String(format: "%.0f", value))
                .font(.system(size: 15, weight: .bold, design: .monospaced))
                .foregroundColor(isCount ? .white : (isSurp ? .tradeGreen : .tradeRed))
        }
        .padding(8)
        .background(Color.tradeDark)
        .cornerRadius(6)
    }

    // MARK: - Chart

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("NET CALORIE CHART")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(.gray)

            if summaries.isEmpty {
                Text("No data available")
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
            } else {
                Chart(summaries) { day in
                    BarMark(
                        x: .value("Date", day.date, unit: .day),
                        y: .value("Net", day.netCalories)
                    )
                    .foregroundStyle(day.isSurplus ? Color.tradeGreen : Color.tradeRed)
                    .cornerRadius(3)
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [3]))
                            .foregroundStyle(Color.white.opacity(0.1))
                        AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                            .foregroundStyle(Color.gray)
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [3]))
                            .foregroundStyle(Color.white.opacity(0.1))
                        AxisValueLabel()
                            .foregroundStyle(Color.gray)
                    }
                }
                .chartPlotStyle { plot in
                    plot.background(Color.tradeDark)
                }
                .frame(height: 180)
            }
        }
        .padding(16)
        .background(Color.tradePanel)
        .cornerRadius(12)
    }

    // MARK: - Daily Breakdown

    private var dailyBreakdown: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("DAILY BREAKDOWN")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(.gray)

            ForEach(summaries.reversed()) { day in
                DaySummaryRow(summary: day)
            }
        }
        .padding(16)
        .background(Color.tradePanel)
        .cornerRadius(12)
    }
}

struct DaySummaryRow: View {
    let summary: DaySummary
    @State private var expanded = false

    private var color: Color { summary.isSurplus ? .tradeGreen : .tradeRed }

    var body: some View {
        VStack(spacing: 0) {
            Button(action: { withAnimation(.spring(response: 0.3)) { expanded.toggle() } }) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(summary.date, format: .dateTime.weekday(.wide).month().day())
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white)
                        Text(Calendar.current.isDateInToday(summary.date) ? "TODAY" : "")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(.tradeYellow)
                    }
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: summary.isSurplus ? "arrow.up.right" : "arrow.down.right")
                            .font(.system(size: 10, weight: .bold))
                        Text((summary.isSurplus ? "+" : "") + String(format: "%.0f", summary.netCalories))
                            .font(.system(size: 15, weight: .bold, design: .monospaced))
                    }
                    .foregroundColor(color)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(color.opacity(0.15))
                    .cornerRadius(6)

                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                        .padding(.leading, 4)
                }
            }
            .buttonStyle(.plain)

            if expanded {
                VStack(spacing: 8) {
                    Divider().background(Color.white.opacity(0.1))
                    HStack {
                        miniStat(label: "CONSUMED", value: summary.caloriesConsumed, color: .white)
                        miniStat(label: "ACTIVE", value: summary.caloriesBurned, color: .tradeRed)
                        miniStat(label: "BMR", value: summary.bmr, color: .tradeBlue)
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.tradeDark.opacity(0.5))
        .cornerRadius(8)
    }

    private func miniStat(label: String, value: Double, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundColor(.gray)
            Text(String(format: "%.0f", value))
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
    }
}
