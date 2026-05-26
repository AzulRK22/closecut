//
//  CodableHelpers.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 25/04/26.
//

import Foundation

enum CodableHelpers {
    static func makeEncoder(
        outputFormatting: JSONEncoder.OutputFormatting = []
    ) -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = outputFormatting
        return encoder
    }

    static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    static func encode<T: Encodable>(_ value: T) throws -> Data {
        try makeEncoder().encode(value)
    }

    static func decode<T: Decodable>(
        _ type: T.Type,
        from data: Data
    ) throws -> T {
        try makeDecoder().decode(type, from: data)
    }

    static func decodeIfPossible<T: Decodable>(
        _ type: T.Type,
        from data: Data?
    ) -> T? {
        guard let data else {
            return nil
        }

        return try? makeDecoder().decode(type, from: data)
    }

    #if DEBUG
    static func prettyPrintedString<T: Encodable>(
        from value: T
    ) -> String? {
        guard let data = try? makeEncoder(
            outputFormatting: [.prettyPrinted, .sortedKeys]
        ).encode(value) else {
            return nil
        }

        return String(data: data, encoding: .utf8)
    }
    #endif
}
