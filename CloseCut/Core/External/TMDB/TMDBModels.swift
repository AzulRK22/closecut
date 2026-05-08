//
//  TMDBModels.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 06/05/26.
//

import Foundation

enum TMDBMediaType: String, Codable {
    case movie
    case tv
    case person
    case unknown

    var entryType: EntryType? {
        switch self {
        case .movie:
            return .movie
        case .tv:
            return .series
        case .person, .unknown:
            return nil
        }
    }

    var displayName: String {
        switch self {
        case .movie:
            return "Movie"
        case .tv:
            return "Series"
        case .person:
            return "Person"
        case .unknown:
            return "Unknown"
        }
    }
}

struct TMDBSearchResponse: Decodable {
    let page: Int
    let results: [TMDBSearchResultDTO]
    let totalPages: Int
    let totalResults: Int

    enum CodingKeys: String, CodingKey {
        case page
        case results
        case totalPages = "total_pages"
        case totalResults = "total_results"
    }
}

struct TMDBSearchResultDTO: Decodable, Identifiable {
    let id: Int
    let mediaTypeRaw: String?

    let title: String?
    let name: String?

    let overview: String?
    let posterPath: String?
    let backdropPath: String?

    let releaseDate: String?
    let firstAirDate: String?

    let voteAverage: Double?
    let popularity: Double?
    let genreIds: [Int]?

    enum CodingKeys: String, CodingKey {
        case id
        case mediaTypeRaw = "media_type"
        case title
        case name
        case overview
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case releaseDate = "release_date"
        case firstAirDate = "first_air_date"
        case voteAverage = "vote_average"
        case popularity
        case genreIds = "genre_ids"
    }

    var mediaType: TMDBMediaType {
        TMDBMediaType(rawValue: mediaTypeRaw ?? "") ?? .unknown
    }

    var displayTitle: String {
        let candidate = title ?? name ?? ""
        return candidate.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var releaseYear: Int? {
        let date = releaseDate ?? firstAirDate

        guard let yearText = date?.prefix(4),
              let year = Int(yearText) else {
            return nil
        }

        return year
    }

    var isSupportedCloseCutMedia: Bool {
        mediaType == .movie || mediaType == .tv
    }
}

struct TMDBMediaSearchResult: Identifiable, Equatable {
    let id: String
    let tmdbId: Int
    let mediaType: TMDBMediaType

    let title: String
    let releaseYear: Int?
    let overview: String?
    let posterPath: String?
    let backdropPath: String?
    let voteAverage: Double?
    let popularity: Double?
    let genreIds: [Int]

    var entryType: EntryType {
        mediaType.entryType ?? .movie
    }

    var subtitle: String {
        var parts: [String] = []

        if let releaseYear {
            parts.append("\(releaseYear)")
        }

        parts.append(mediaType.displayName)

        if let voteAverage, voteAverage > 0 {
            parts.append(String(format: "%.1f TMDB", voteAverage))
        }

        return parts.joined(separator: " • ")
    }
}

extension TMDBMediaSearchResult {
    init?(dto: TMDBSearchResultDTO) {
        guard dto.isSupportedCloseCutMedia else {
            return nil
        }

        let title = dto.displayTitle

        guard title.isEmpty == false else {
            return nil
        }

        self.tmdbId = dto.id
        self.mediaType = dto.mediaType
        self.id = "\(dto.mediaType.rawValue)-\(dto.id)"
        self.title = title
        self.releaseYear = dto.releaseYear
        self.overview = dto.overview
        self.posterPath = dto.posterPath
        self.backdropPath = dto.backdropPath
        self.voteAverage = dto.voteAverage
        self.popularity = dto.popularity
        self.genreIds = dto.genreIds ?? []
    }
}
struct TMDBDiscoverMovieResponse: Decodable {
    let page: Int
    let results: [TMDBDiscoverMovieDTO]
    let totalPages: Int
    let totalResults: Int

    enum CodingKeys: String, CodingKey {
        case page
        case results
        case totalPages = "total_pages"
        case totalResults = "total_results"
    }
}

struct TMDBDiscoverTVResponse: Decodable {
    let page: Int
    let results: [TMDBDiscoverTVDTO]
    let totalPages: Int
    let totalResults: Int

    enum CodingKeys: String, CodingKey {
        case page
        case results
        case totalPages = "total_pages"
        case totalResults = "total_results"
    }
}

struct TMDBDiscoverMovieDTO: Decodable, Identifiable {
    let id: Int
    let title: String?
    let overview: String?
    let posterPath: String?
    let backdropPath: String?
    let releaseDate: String?
    let voteAverage: Double?
    let popularity: Double?
    let genreIds: [Int]?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case overview
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case releaseDate = "release_date"
        case voteAverage = "vote_average"
        case popularity
        case genreIds = "genre_ids"
    }

    var displayTitle: String {
        (title ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var releaseYear: Int? {
        guard let yearText = releaseDate?.prefix(4),
              let year = Int(yearText) else {
            return nil
        }

        return year
    }
}

struct TMDBDiscoverTVDTO: Decodable, Identifiable {
    let id: Int
    let name: String?
    let overview: String?
    let posterPath: String?
    let backdropPath: String?
    let firstAirDate: String?
    let voteAverage: Double?
    let popularity: Double?
    let genreIds: [Int]?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case overview
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case firstAirDate = "first_air_date"
        case voteAverage = "vote_average"
        case popularity
        case genreIds = "genre_ids"
    }

    var displayTitle: String {
        (name ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var releaseYear: Int? {
        guard let yearText = firstAirDate?.prefix(4),
              let year = Int(yearText) else {
            return nil
        }

        return year
    }
}

extension TMDBMediaSearchResult {
    init?(movieDTO: TMDBDiscoverMovieDTO) {
        let title = movieDTO.displayTitle

        guard title.isEmpty == false else {
            return nil
        }

        self.tmdbId = movieDTO.id
        self.mediaType = .movie
        self.id = "movie-\(movieDTO.id)"
        self.title = title
        self.releaseYear = movieDTO.releaseYear
        self.overview = movieDTO.overview
        self.posterPath = movieDTO.posterPath
        self.backdropPath = movieDTO.backdropPath
        self.voteAverage = movieDTO.voteAverage
        self.popularity = movieDTO.popularity
        self.genreIds = movieDTO.genreIds ?? []
    }

    init?(tvDTO: TMDBDiscoverTVDTO) {
        let title = tvDTO.displayTitle

        guard title.isEmpty == false else {
            return nil
        }

        self.tmdbId = tvDTO.id
        self.mediaType = .tv
        self.id = "tv-\(tvDTO.id)"
        self.title = title
        self.releaseYear = tvDTO.releaseYear
        self.overview = tvDTO.overview
        self.posterPath = tvDTO.posterPath
        self.backdropPath = tvDTO.backdropPath
        self.voteAverage = tvDTO.voteAverage
        self.popularity = tvDTO.popularity
        self.genreIds = tvDTO.genreIds ?? []
    }
}
