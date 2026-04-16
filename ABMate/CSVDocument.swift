//
//  CSVDocument.swift
//  ABMate
//
// © Created by Somesh Pathak on 24/06/2025.
//


import SwiftUI
import UniformTypeIdentifiers

struct CSVDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.commaSeparatedText] }
    
    var csvString: String
    
    init(devices: [OrgDevice]) {
        var csv = "Serial Number,Model,Product Family,Product Type,Capacity,Color,Status,Order Number,Added to Org,Last Updated,ID\n"

        for device in devices {
            let fields: [String] = [
                device.serialNumber,
                device.model ?? "",
                device.os ?? "",
                device.productType ?? ""
            ]
            let fields2: [String] = [
                device.capacity ?? "",
                device.color ?? "",
                device.enrollmentState ?? "",
                device.orderNumber ?? ""
            ]
            let fields3: [String] = [
                device.addedDate ?? "",
                device.updatedDate ?? "",
                device.id
            ]
            let row = (fields + fields2 + fields3)
            .map { field -> String in
                let escaped = field.replacingOccurrences(of: "\"", with: "\"\"")
                return field.contains(",") || field.contains("\"") ? "\"\(escaped)\"" : escaped
            }
            .joined(separator: ",")

            csv += row + "\n"
        }

        self.csvString = csv
    }
    
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let string = String(data: data, encoding: .utf8) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        csvString = string
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = csvString.data(using: .utf8)!
        return FileWrapper(regularFileWithContents: data)
    }
}

// MARK: - Plain Text Document (for report export)

struct PlainTextDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.plainText] }

    var text: String

    init(text: String) {
        self.text = text
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let string = String(data: data, encoding: .utf8) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        text = string
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: text.data(using: .utf8)!)
    }
}
