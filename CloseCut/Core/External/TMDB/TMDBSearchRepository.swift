//
//  TMDBSearchRepository.swift
//  CloseCut
//

import Foundation

final class TMDBSearchRepository {
    private let client: TMDBClient

    init(client: TMDBClient = TMDBClient()) {
        self.client = client
    }

    func searchMedia(
        query: String,
        page: Int = 1,
        language: String = "en-US"
    ) async throws -> [TMDBMediaSearchResult] {
        let cleanedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)

        guard cleanedQuery.count >= 2 else {
            return []
        }

        let response: TMDBSearchResponse = try await client.send(
            .searchMulti(
                query: cleanedQuery,
                page: page,
                language: language
            )
        )

        return response.results
            .compactMap { TMDBMediaSearchResult(dto: $0) }
            .sorted { first, second in
                let firstPopularity = first.popularity ?? 0
                let secondPopularity = second.popularity ?? 0

                if firstPopularity != secondPopularity {
                    return firstPopularity > secondPopularity
                }

                return (first.releaseYear ?? 0) > (second.releaseYear ?? 0)
            }
    }
}
