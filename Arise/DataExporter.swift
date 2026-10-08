//
//  DataExporter.swift
//  Arise
//
//  Pro-only export of a user's Firestore data to a portable JSON file.
//  Everything the app stores lives in the single `users/{uid}` document, so
//  the export is a normalised snapshot of that document plus a small manifest.
//

import Foundation
import FirebaseFirestore
import SwiftUI
import UIKit

enum DataExporter {
    enum ExportError: LocalizedError {
        case noUser
        case empty
        case writeFailed

        var errorDescription: String? {
            switch self {
            case .noUser: return "You need to be signed in to export your data."
            case .empty: return "We couldn't find any data to export yet."
            case .writeFailed: return "We couldn't create the export file. Please try again."
            }
        }
    }

    /// Fetches and normalises the current user's document into pretty JSON data.
    static func exportData(uid: String) async throws -> Data {
        let snapshot = try await Firestore.firestore().collection("users").document(uid).getDocument()
        guard let raw = snapshot.data(), !raw.isEmpty else { throw ExportError.empty }

        let payload: [String: Any] = [
            "exportedAt": ISO8601DateFormatter().string(from: Date()),
            "app": "Arise",
            "data": jsonSafe(raw)
        ]

        return try JSONSerialization.data(
            withJSONObject: payload,
            options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        )
    }

    /// Writes export data to a temporary file and returns its URL for sharing.
    static func writeTemporaryFile(data: Data, uid: String) throws -> URL {
        let stamp = ISO8601DateFormatter().string(from: Date())
            .replacingOccurrences(of: ":", with: "-")
        let name = "Arise-Export-\(uid.prefix(6))-\(stamp).json"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(name)
        do {
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            throw ExportError.writeFailed
        }
    }

    // MARK: - Firestore -> JSON

    /// Recursively converts Firestore values (Timestamps, GeoPoints, refs, etc.)
    /// into JSON-serialisable primitives.
    private static func jsonSafe(_ value: Any) -> Any {
        switch value {
        case let dict as [String: Any]:
            return dict.mapValues { jsonSafe($0) }
        case let array as [Any]:
            return array.map { jsonSafe($0) }
        case let timestamp as Timestamp:
            return ISO8601DateFormatter().string(from: timestamp.dateValue())
        case let date as Date:
            return ISO8601DateFormatter().string(from: date)
        case let geo as GeoPoint:
            return ["latitude": geo.latitude, "longitude": geo.longitude]
        case let ref as DocumentReference:
            return ref.path
        case let data as Data:
            return data.base64EncodedString()
        case is NSNull:
            return NSNull()
        default:
            return value
        }
    }
}

// MARK: - Share sheet

/// A thin SwiftUI wrapper around `UIActivityViewController` for sharing files.
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}