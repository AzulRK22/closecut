//
//  TMDBMediaRepository.swift
//  CloseCut
//

import Foundation

final class TMDBMediaRepository {
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

        guard cleanedQuery.count >= TMDBConfiguration.minimumSearchQueryLength else {
            return []
        }

        let safePage = max(page, 1)

        let response: TMDBSearchResponse = try await client.send(
            .searchMulti(
                query: cleanedQuery,
                page: safePage,
                language: language
            )
        )

        return response.results
            .compactMap { TMDBMediaSearchResult(dto: $0) }
            .sorted(by: sortSearchResults)
    }

    func discoverMovies(
        genreIds: [Int],
        page: Int = 1,
        language: String = "en-US",
        minimumVoteAverage: Double = 6.8
    ) async throws -> [TMDBMediaSearchResult] {
        let cleanedGenreIds = genreIds.uniqued()

        guard cleanedGenreIds.isEmpty == false else {
            return []
        }

        let safePage = max(page, 1)

        let response: TMDBDiscoverMovieResponse = try await client.send(
            .discoverMovies(
                genreIds: cleanedGenreIds,
                page: safePage,
                language: language,
                minimumVoteAverage: minimumVoteAverage
            )
        )

        return response.results
            .compactMap { TMDBMediaSearchResult(movieDTO: $0) }
            .sorted(by: sortDiscoveryResults)
    }

    func discoverTV(
        genreIds: [Int],
        page: Int = 1,
        language: String = "en-US",
        minimumVoteAverage: Double = 6.8
    ) async throws -> [TMDBMediaSearchResult] {
        let cleanedGenreIds = genreIds.uniqued()

        guard cleanedGenreIds.isEmpty == false else {
            return []
        }

        let safePage = max(page, 1)

        let response: TMDBDiscoverTVResponse = try await client.send(
            .discoverTV(
                genreIds: cleanedGenreIds,
                page: safePage,
                language: language,
                minimumVoteAverage: minimumVoteAverage
            )
        )

        return response.results
            .compactMap { TMDBMediaSearchResult(tvDTO: $0) }
            .sorted(by: sortDiscoveryResults)
    }

    func discoverMedia(
        genreIds: [Int],
        preferredType: EntryType?,
        page: Int = 1,
        language: String = "en-US"
    ) async throws -> [TMDBMediaSearchResult] {
        let cleanedGenreIds = Array(
            genreIds
                .uniqued()
                .prefix(TMDBConfiguration.maximumDiscoveryGenreCount)
        )

        guard cleanedGenreIds.isEmpty == false else {
            return []
        }

        let safePage = max(page, 1)

        switch preferredType {
        case .movie:
            return try await discoverMovies(
                genreIds: cleanedGenreIds,
                page: safePage,
                language: language,
                minimumVoteAverage: TMDBConfiguration.minimumDiscoveryVoteAverage
            )

        case .series:
            return try await discoverTV(
                genreIds: cleanedGenreIds,
                page: safePage,
                language: language,
                minimumVoteAverage: TMDBConfiguration.minimumDiscoveryVoteAverage
            )

        case .none:
            async let movies = discoverMovies(
                genreIds: cleanedGenreIds,
                page: safePage,
                language: language,
                minimumVoteAverage: TMDBConfiguration.minimumDiscoveryVoteAverage
            )

            async let tv = discoverTV(
                genreIds: cleanedGenreIds,
                page: safePage,
                language: language,
                minimumVoteAverage: TMDBConfiguration.minimumDiscoveryVoteAverage
            )

            let combined = try await movies + tv

            return combined.sorted(by: sortDiscoveryResults)
        }
    }

    // MARK: - Sorting

    private func sortSearchResults(
        first: TMDBMediaSearchResult,
        second: TMDBMediaSearchResult
    ) -> Bool {
        let firstPopularity = first.popularity ?? 0
        let secondPopularity = second.popularity ?? 0

        if firstPopularity != secondPopularity {
            return firstPopularity > secondPopularity
        }

        let firstRating = first.voteAverage ?? 0
        let secondRating = second.voteAverage ?? 0

        if firstRating != secondRating {
            return firstRating > secondRating
        }

        return (first.releaseYear ?? 0) > (second.releaseYear ?? 0)
    }

    private func sortDiscoveryResults(
        first: TMDBMediaSearchResult,
        second: TMDBMediaSearchResult
    ) -> Bool {
        let firstRating = first.voteAverage ?? 0
        let secondRating = second.voteAverage ?? 0

        if firstRating != secondRating {
            return firstRating > secondRating
        }

        let firstPopularity = first.popularity ?? 0
        let secondPopularity = second.popularity ?? 0

        if firstPopularity != secondPopularity {
            return firstPopularity > secondPopularity
        }

        return (first.releaseYear ?? 0) > (second.releaseYear ?? 0)
    }
}
