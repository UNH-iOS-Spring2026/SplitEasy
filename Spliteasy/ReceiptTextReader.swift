//
//  ReceiptTextReader.swift
//  Spliteasy
//

import Foundation
import Vision
import UIKit

struct ReceiptScanResult {
    let recognizedText: String
    let detectedAmount: Double?
    let detectedMerchantName: String?
    let detectedCategory: String?
}

private struct OCRLine {
    let text: String
    let normalizedText: String
    let rect: CGRect
    let midY: CGFloat
    let minX: CGFloat
}

final class ReceiptTextReader {
    static let shared = ReceiptTextReader()

    private init() {}

    func scanReceipt(
        image: UIImage,
        completion: @escaping (Result<ReceiptScanResult, Error>) -> Void
    ) {
        guard let cgImage = image.cgImage else {
            completion(.failure(NSError(
                domain: "ReceiptTextReader",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Unable to read the selected image."]
            )))
            return
        }

        let request = VNRecognizeTextRequest { request, error in
            if let error {
                completion(.failure(error))
                return
            }

            let observations = request.results as? [VNRecognizedTextObservation] ?? []
            let orderedLines = Self.makeOrderedLines(from: observations)

            let fullText = orderedLines.map(\.text).joined(separator: "\n")
            let detectedAmount = Self.extractLikelyTotal(from: orderedLines)
            let merchant = Self.extractMerchantName(from: orderedLines)
            let category = Self.inferCategory(from: orderedLines, merchant: merchant)

            completion(.success(
                ReceiptScanResult(
                    recognizedText: fullText,
                    detectedAmount: detectedAmount,
                    detectedMerchantName: merchant,
                    detectedCategory: category
                )
            ))
        }

        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                completion(.failure(error))
            }
        }
    }

    // MARK: - OCR ordering

    private static func makeOrderedLines(from observations: [VNRecognizedTextObservation]) -> [OCRLine] {
        let rawLines: [OCRLine] = observations.compactMap { observation in
            guard let candidate = observation.topCandidates(1).first else { return nil }

            let text = candidate.string.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else { return nil }

            let rect = observation.boundingBox
            return OCRLine(
                text: text,
                normalizedText: normalizeText(text),
                rect: rect,
                midY: rect.midY,
                minX: rect.minX
            )
        }

        // Sort by visual position:
        // higher Y first (top of receipt), then left to right
        let sorted = rawLines.sorted { a, b in
            if abs(a.midY - b.midY) > 0.025 {
                return a.midY > b.midY
            }
            return a.minX < b.minX
        }

        return mergeSameRowLines(sorted)
    }

    private static func mergeSameRowLines(_ lines: [OCRLine]) -> [OCRLine] {
        guard !lines.isEmpty else { return [] }

        var grouped: [[OCRLine]] = []

        for line in lines {
            if let last = grouped.last,
               let reference = last.first,
               abs(reference.midY - line.midY) < 0.022 {
                grouped[grouped.count - 1].append(line)
            } else {
                grouped.append([line])
            }
        }

        return grouped.compactMap { row in
            let ordered = row.sorted { $0.minX < $1.minX }
            let mergedText = ordered.map(\.text).joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
            guard !mergedText.isEmpty else { return nil }

            let rect = ordered.reduce(ordered[0].rect) { partial, next in
                partial.union(next.rect)
            }

            return OCRLine(
                text: mergedText,
                normalizedText: normalizeText(mergedText),
                rect: rect,
                midY: rect.midY,
                minX: rect.minX
            )
        }
    }

    // MARK: - Total extraction

    private static func extractLikelyTotal(from lines: [OCRLine]) -> Double? {
        guard !lines.isEmpty else { return nil }

        // 1. Best case: same merged row contains TOTAL and the amount
        for line in lines {
            if isTotalLine(line.normalizedText),
               let amount = extractRightmostCurrencyValue(from: line.text) {
                return amount
            }
        }

        // 2. Standalone TOTAL row -> next nearby non-payment row with amount
        for index in lines.indices {
            let line = lines[index]

            if isStandaloneTotalLabel(line.normalizedText) {
                for offset in 1...3 {
                    let nextIndex = index + offset
                    if nextIndex < lines.count {
                        let nextLine = lines[nextIndex]
                        if isPaymentLine(nextLine.normalizedText) { continue }
                        if let amount = extractRightmostCurrencyValue(from: nextLine.text) {
                            return amount
                        }
                    }
                }
            }
        }

        // 3. Subtotal + tax
        let subtotal = extractValue(forLabels: ["subtotal", "sub total"], in: lines)
        let tax = extractTaxValue(in: lines)

        if let subtotal, let tax {
            return roundToTwo(subtotal + tax)
        }

        // 4. Bottom summary fallback:
        // find reasonable amounts near TOTAL/CASH/CHANGE block and prefer non-payment total-like row
        let bottomLines = Array(lines.suffix(12))

        for line in bottomLines {
            if isTotalLine(line.normalizedText),
               let amount = extractRightmostCurrencyValue(from: line.text) {
                return amount
            }
        }

        return nil
    }

    private static func extractValue(forLabels labels: [String], in lines: [OCRLine]) -> Double? {
        for index in lines.indices {
            let line = lines[index]

            if labels.contains(where: { line.normalizedText.contains($0) }) {
                if let value = extractRightmostCurrencyValue(from: line.text) {
                    return value
                }

                for offset in 1...2 {
                    let nextIndex = index + offset
                    if nextIndex < lines.count,
                       let value = extractRightmostCurrencyValue(from: lines[nextIndex].text) {
                        return value
                    }
                }
            }
        }
        return nil
    }

    private static func extractTaxValue(in lines: [OCRLine]) -> Double? {
        for index in lines.indices {
            let line = lines[index]

            if line.normalizedText.contains("tax") {
                // Prefer a money amount, not percentage
                let moneyValues = extractAllCurrencyValues(from: line.text)
                if let money = moneyValues.max() {
                    return money
                }

                for offset in 1...3 {
                    let nextIndex = index + offset
                    if nextIndex < lines.count {
                        let nextValues = extractAllCurrencyValues(from: lines[nextIndex].text)
                        if let money = nextValues.max() {
                            return money
                        }
                    }
                }
            }
        }
        return nil
    }

    // MARK: - Merchant / category

    private static func extractMerchantName(from lines: [OCRLine]) -> String? {
        let topLines = Array(lines.prefix(5))

        let blockedWords = [
            "total", "subtotal", "tax", "cash", "change", "receipt",
            "invoice", "paid", "date", "time", "thank you"
        ]

        let candidates = topLines.filter { line in
            if extractRightmostCurrencyValue(from: line.text) != nil { return false }
            if blockedWords.contains(where: { line.normalizedText.contains($0) }) { return false }
            return line.text.count >= 3
        }

        guard !candidates.isEmpty else { return nil }

        if candidates.count >= 2,
           candidates[0].text.count <= 24,
           candidates[1].text.count <= 24 {
            return "\(candidates[0].text) \(candidates[1].text)"
        }

        return candidates[0].text
    }

    private static func inferCategory(from lines: [OCRLine], merchant: String?) -> String? {
        let joined = lines.map(\.normalizedText).joined(separator: " ")
        let merchantText = merchant?.lowercased() ?? ""
        let text = joined + " " + merchantText

        if text.contains("supermarket") || text.contains("grocery") || text.contains("fruit") || text.contains("milk") || text.contains("cheese") || text.contains("yogurt") {
            return "Food"
        }

        if text.contains("walmart") || text.contains("target") || text.contains("costco") {
            return "Shopping"
        }

        if text.contains("cafe") || text.contains("restaurant") || text.contains("burger") || text.contains("pizza") || text.contains("coffee") {
            return "Food"
        }

        if text.contains("uber") || text.contains("taxi") || text.contains("fuel") || text.contains("gas") {
            return "Transport"
        }

        if text.contains("pharmacy") || text.contains("drug") {
            return "Health"
        }

        if text.contains("mall") || text.contains("fashion") || text.contains("store") {
            return "Shopping"
        }

        return nil
    }

    // MARK: - Helpers

    private static func extractRightmostCurrencyValue(from text: String) -> Double? {
        extractAllCurrencyValues(from: text).last
    }

    private static func extractAllCurrencyValues(from text: String) -> [Double] {
        let pattern = #"(\$?\s*\d+\.\d{2})"#

        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return []
        }

        let nsRange = NSRange(text.startIndex..<text.endIndex, in: text)
        let matches = regex.matches(in: text, options: [], range: nsRange)

        return matches.compactMap { match in
            guard let range = Range(match.range(at: 1), in: text) else { return nil }
            let raw = String(text[range])
                .replacingOccurrences(of: "$", with: "")
                .replacingOccurrences(of: " ", with: "")
            return Double(raw)
        }
    }

    private static func normalizeText(_ text: String) -> String {
        text
            .lowercased()
            .replacingOccurrences(of: "|", with: "l")
            .replacingOccurrences(of: ":", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func isTotalLine(_ line: String) -> Bool {
        let hasTotalWord =
            line.contains("grand total") ||
            line.contains("amount due") ||
            line.contains("balance due") ||
            line == "total" ||
            line.contains("total ")

        return hasTotalWord &&
            !line.contains("subtotal") &&
            !line.contains("sub total") &&
            !line.contains("cash") &&
            !line.contains("change") &&
            !line.contains("visa") &&
            !line.contains("debit") &&
            !line.contains("credit") &&
            !line.contains("tend") &&
            !line.contains("paid")
    }

    private static func isStandaloneTotalLabel(_ line: String) -> Bool {
        line == "total" || line == "grand total"
    }

    private static func isPaymentLine(_ line: String) -> Bool {
        line.contains("cash") ||
        line.contains("change") ||
        line.contains("paid") ||
        line.contains("tender") ||
        line.contains("tend") ||
        line.contains("credit") ||
        line.contains("debit") ||
        line.contains("visa") ||
        line.contains("mastercard") ||
        line.contains("master card")
    }

    private static func roundToTwo(_ value: Double) -> Double {
        (value * 100).rounded() / 100
    }
}
