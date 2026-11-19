import Foundation

enum LengthUnit: String, Codable, CaseIterable, Identifiable {
    case inches
    case centimeters

    var id: String { rawValue }

    var abbreviation: String {
        switch self {
        case .inches: return "in"
        case .centimeters: return "cm"
        }
    }

    /// Multiplier to convert a value in this unit to meters.
    var metersPerUnit: Double {
        switch self {
        case .inches: return 0.0254
        case .centimeters: return 0.01
        }
    }
}

/// A physical width/height pair, stored internally in meters so AR code
/// never has to think about units.
struct Dimensions: Codable, Equatable {
    var widthMeters: Double
    var heightMeters: Double

    init(widthMeters: Double, heightMeters: Double) {
        self.widthMeters = widthMeters
        self.heightMeters = heightMeters
    }

    init(width: Double, height: Double, unit: LengthUnit) {
        self.widthMeters = width * unit.metersPerUnit
        self.heightMeters = height * unit.metersPerUnit
    }

    func width(in unit: LengthUnit) -> Double {
        widthMeters / unit.metersPerUnit
    }

    func height(in unit: LengthUnit) -> Double {
        heightMeters / unit.metersPerUnit
    }

    func formatted(in unit: LengthUnit) -> String {
        let w = width(in: unit)
        let h = height(in: unit)
        return String(format: "%.1f × %.1f %@", w, h, unit.abbreviation)
    }

    static let zero = Dimensions(widthMeters: 0, heightMeters: 0)
}

/// Common frame/print sizes a user can pick instead of typing numbers.
enum CommonSize: String, CaseIterable, Identifiable {
    case fiveBySeven = "5 × 7 in"
    case eightByTen = "8 × 10 in"
    case elevenByFourteen = "11 × 14 in"
    case sixteenByTwenty = "16 × 20 in"
    case eighteenByTwentyFour = "18 × 24 in"
    case twentyFourByThirtySix = "24 × 36 in"

    var id: String { rawValue }

    var dimensions: Dimensions {
        switch self {
        case .fiveBySeven: return Dimensions(width: 5, height: 7, unit: .inches)
        case .eightByTen: return Dimensions(width: 8, height: 10, unit: .inches)
        case .elevenByFourteen: return Dimensions(width: 11, height: 14, unit: .inches)
        case .sixteenByTwenty: return Dimensions(width: 16, height: 20, unit: .inches)
        case .eighteenByTwentyFour: return Dimensions(width: 18, height: 24, unit: .inches)
        case .twentyFourByThirtySix: return Dimensions(width: 24, height: 36, unit: .inches)
        }
    }
}

/// Known real-world sizes for objects used to scale a photo.
enum ReferenceObjectKind: String, Codable, CaseIterable, Identifiable {
    case creditCard
    case dollarBill

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .creditCard: return "Credit card"
        case .dollarBill: return "Dollar bill"
        }
    }

    /// Standard physical dimensions, in inches (ISO/ID-1 card; US currency note).
    var dimensions: Dimensions {
        switch self {
        case .creditCard: return Dimensions(width: 3.375, height: 2.125, unit: .inches)
        case .dollarBill: return Dimensions(width: 6.14, height: 2.61, unit: .inches)
        }
    }

    var hint: String {
        switch self {
        case .creditCard: return "Rigid and never bends — the more accurate choice."
        case .dollarBill: return "Keep it flat — any curl or fold will throw off the measurement."
        }
    }
}
