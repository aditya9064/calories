import SwiftUI
import PhotosUI

struct FoodLogView: View {
    @EnvironmentObject var store: CalorieStore
    @State private var showCamera = false
    @State private var showPhotoPicker = false
    @State private var selectedImage: UIImage?
    @State private var isAnalyzing = false
    @State private var analysisResult: FoodAnalysisResult?
    @State private var errorMessage: String?
    @State private var showManualEntry = false
    @State private var photosItem: PhotosPickerItem?

    private let analyzer = FoodAnalyzer()

    var body: some View {
        NavigationView {
            ZStack {
                Color.tradeDark.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        scanCard
                        if let result = analysisResult {
                            AnalysisResultCard(result: result, onLog: logFood)
                        }
                        todayLogSection
                    }
                    .padding()
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showCamera) {
                CameraView(image: $selectedImage)
                    .ignoresSafeArea()
            }
            .sheet(isPresented: $showManualEntry) {
                ManualFoodEntryView()
            }
            .onChange(of: selectedImage) { image in
                if let img = image { analyzeFood(img) }
            }
            .onChange(of: photosItem) { item in
                Task {
                    if let data = try? await item?.loadTransferable(type: Data.self),
                       let img = UIImage(data: data) {
                        selectedImage = img
                    }
                }
            }
        }
    }

    // MARK: - Scan Card

    private var scanCard: some View {
        VStack(spacing: 16) {
            HStack {
                Text("FOOD SCANNER")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(.gray)
                Spacer()
                Text("AI POWERED")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(.tradeBlue)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.tradeBlue.opacity(0.15))
                    .cornerRadius(4)
            }

            if isAnalyzing {
                analyzingView
            } else if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 200)
                    .clipped()
                    .cornerRadius(8)
            } else {
                emptyPlaceholder
            }

            HStack(spacing: 12) {
                Button(action: { showCamera = true }) {
                    Label("Camera", systemImage: "camera.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.tradeGreen)
                        .cornerRadius(8)
                }

                PhotosPicker(selection: $photosItem, matching: .images) {
                    Label("Gallery", systemImage: "photo.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.tradePanel)
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.2), lineWidth: 1))
                }

                Button(action: { showManualEntry = true }) {
                    Label("Manual", systemImage: "pencil")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.tradePanel)
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.2), lineWidth: 1))
                }
            }

            if let error = errorMessage {
                Text(error)
                    .font(.system(size: 12))
                    .foregroundColor(.tradeRed)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(16)
        .background(Color.tradePanel)
        .cornerRadius(12)
    }

    private var analyzingView: some View {
        VStack(spacing: 12) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .tradeGreen))
                .scaleEffect(1.5)
            Text("ANALYZING FOOD...")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(.tradeGreen)
        }
        .frame(height: 120)
        .frame(maxWidth: .infinity)
    }

    private var emptyPlaceholder: some View {
        VStack(spacing: 8) {
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 48))
                .foregroundColor(.gray.opacity(0.5))
            Text("Take a photo to analyze calories")
                .font(.system(size: 13))
                .foregroundColor(.gray)
        }
        .frame(height: 120)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Today Log

    private var todayLogSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("TODAY'S LOG")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(.gray)
                Spacer()
                let total = store.todayFood().reduce(0) { $0 + $1.calories }
                Text(String(format: "%.0f kcal total", total))
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(.tradeGreen)
            }

            let todayFood = store.todayFood()
            if todayFood.isEmpty {
                Text("No food logged yet")
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 16)
            } else {
                ForEach(todayFood.reversed()) { entry in
                    LoggedFoodRow(entry: entry)
                }
                .onDelete { offsets in
                    let reversed = todayFood.reversed()
                    let indices = offsets.map { reversed.index(reversed.startIndex, offsetBy: $0) }
                    for idx in indices {
                        if let mainIdx = store.foodEntries.firstIndex(where: { $0.id == idx.id }) {
                            store.foodEntries.remove(at: mainIdx)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color.tradePanel)
        .cornerRadius(12)
    }

    // MARK: - Actions

    private func analyzeFood(_ image: UIImage) {
        isAnalyzing = true
        errorMessage = nil
        analysisResult = nil
        Task {
            do {
                let result = try await analyzer.analyze(image: image)
                analysisResult = result
            } catch {
                errorMessage = error.localizedDescription
            }
            isAnalyzing = false
        }
    }

    private func logFood(_ result: FoodAnalysisResult) {
        let entry = FoodEntry(
            name: result.name,
            calories: result.calories,
            protein: result.protein,
            carbs: result.carbs,
            fat: result.fat,
            imageData: selectedImage?.jpegData(compressionQuality: 0.5)
        )
        store.addFood(entry)
        analysisResult = nil
        selectedImage = nil
    }
}

// MARK: - Analysis Result Card

struct AnalysisResultCard: View {
    let result: FoodAnalysisResult
    let onLog: (FoodAnalysisResult) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(result.name.uppercased())
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                    Text(String(format: "Confidence: %.0f%%", result.confidence * 100))
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                }
                Spacer()
                Text(String(format: "+%.0f", result.calories))
                    .font(.system(size: 32, weight: .bold, design: .monospaced))
                    .foregroundColor(.tradeGreen)
                + Text(" kcal")
                    .font(.system(size: 14))
                    .foregroundColor(.tradeGreen.opacity(0.7))
            }

            Divider().background(Color.white.opacity(0.1))

            HStack {
                MacroTag(label: "P", value: result.protein, color: .tradeBlue)
                MacroTag(label: "C", value: result.carbs, color: .tradeYellow)
                MacroTag(label: "F", value: result.fat, color: .tradeRed)
            }

            if !result.breakdown.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("BREAKDOWN")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(.gray)
                    ForEach(result.breakdown.sorted(by: { $0.value > $1.value }), id: \.key) { item, cal in
                        HStack {
                            Text(item)
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.8))
                            Spacer()
                            Text(String(format: "%.0f kcal", cal))
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(.tradeGreen.opacity(0.8))
                        }
                    }
                }
            }

            Button(action: { onLog(result) }) {
                Text("LOG FOOD")
                    .font(.system(size: 15, weight: .bold, design: .monospaced))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.tradeGreen)
                    .cornerRadius(8)
            }
        }
        .padding(16)
        .background(Color.tradePanel)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.tradeGreen.opacity(0.4), lineWidth: 1))
    }
}

struct MacroTag: View {
    let label: String
    let value: Double
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(color)
            Text(String(format: "%.0fg", value))
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(color.opacity(0.15))
        .cornerRadius(6)
    }
}

struct LoggedFoodRow: View {
    let entry: FoodEntry

    var body: some View {
        HStack(spacing: 12) {
            if let data = entry.imageData, let img = UIImage(data: data) {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 44, height: 44)
                    .clipped()
                    .cornerRadius(6)
            } else {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.tradeGreen.opacity(0.1))
                    .frame(width: 44, height: 44)
                    .overlay(Image(systemName: "fork.knife").foregroundColor(.tradeGreen))
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(entry.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                HStack(spacing: 8) {
                    Text("P: \(String(format: "%.0fg", entry.protein))")
                        .font(.system(size: 10))
                        .foregroundColor(.tradeBlue.opacity(0.8))
                    Text("C: \(String(format: "%.0fg", entry.carbs))")
                        .font(.system(size: 10))
                        .foregroundColor(.tradeYellow.opacity(0.8))
                    Text("F: \(String(format: "%.0fg", entry.fat))")
                        .font(.system(size: 10))
                        .foregroundColor(.tradeRed.opacity(0.8))
                }
            }
            Spacer()
            Text(String(format: "+%.0f", entry.calories))
                .font(.system(size: 15, weight: .bold, design: .monospaced))
                .foregroundColor(.tradeGreen)
        }
        .padding(.vertical, 4)
    }
}
