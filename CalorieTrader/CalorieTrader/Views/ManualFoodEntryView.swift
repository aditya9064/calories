import SwiftUI

struct ManualFoodEntryView: View {
    @EnvironmentObject var store: CalorieStore
    @Environment(\.dismiss) var dismiss

    @State private var name = ""
    @State private var calories = ""
    @State private var protein = ""
    @State private var carbs = ""
    @State private var fat = ""

    var body: some View {
        NavigationView {
            ZStack {
                Color.tradeDark.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            fieldLabel("FOOD NAME")
                            TextField("e.g. Chicken Salad", text: $name)
                                .textFieldStyle(TradeFieldStyle())
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            fieldLabel("CALORIES (kcal)")
                            TextField("0", text: $calories)
                                .textFieldStyle(TradeFieldStyle())
                                .keyboardType(.decimalPad)
                        }

                        HStack(spacing: 12) {
                            macroField(label: "PROTEIN (g)", binding: $protein)
                            macroField(label: "CARBS (g)", binding: $carbs)
                            macroField(label: "FAT (g)", binding: $fat)
                        }

                        Button(action: save) {
                            Text("LOG FOOD")
                                .font(.system(size: 16, weight: .bold, design: .monospaced))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(canSave ? Color.tradeGreen : Color.gray)
                                .cornerRadius(10)
                        }
                        .disabled(!canSave)
                    }
                    .padding()
                }
            }
            .navigationTitle("Manual Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.tradeGreen)
                }
            }
        }
    }

    private var canSave: Bool {
        !name.isEmpty && Double(calories) != nil
    }

    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .bold, design: .monospaced))
            .foregroundColor(.gray)
    }

    private func macroField(label: String, binding: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            fieldLabel(label)
            TextField("0", text: binding)
                .textFieldStyle(TradeFieldStyle())
                .keyboardType(.decimalPad)
        }
    }

    private func save() {
        let entry = FoodEntry(
            name: name,
            calories: Double(calories) ?? 0,
            protein: Double(protein) ?? 0,
            carbs: Double(carbs) ?? 0,
            fat: Double(fat) ?? 0
        )
        store.addFood(entry)
        dismiss()
    }
}

struct TradeFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(.system(size: 16, design: .monospaced))
            .foregroundColor(.white)
            .padding(12)
            .background(Color.tradePanel)
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.15), lineWidth: 1))
    }
}
