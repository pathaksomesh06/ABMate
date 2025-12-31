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
        var csv = "Serial Number,Model,Product Family,Product Type,Status,ID\n"
        
        for device in devices {
            let row = [
                device.serialNumber,
                device.model ?? "",
                device.os ?? "",
                device.productType ?? "",
                device.enrollmentState ?? "",
                device.id
            ]
            .map { field in
                // Escape quotes and wrap in quotes if contains comma
                let escaped = field.replacingOccurrences(of: "\"", with: "\"\"")
                return field.contains(",") ? "\"\(escaped)\"" : escaped
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
