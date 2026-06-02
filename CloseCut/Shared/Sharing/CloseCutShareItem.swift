//
//  CloseCutShareItem.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 02/06/26.
//

import Foundation

struct CloseCutShareItem: Identifiable, Equatable {
    let id: String
    let kind: CloseCutShareKind
    let title: String
    let subtitle: String
    let body: String
    let footer: String
    let callToAction: String?

    init(
        id: String = UUID().uuidString,
        kind: CloseCutShareKind,
        title: String,
        subtitle: String,
        body: String,
        footer: String = "Shared from CloseCut.",
        callToAction: String? = nil
    ) {
        self.id = id
        self.kind = kind
        self.title = title.trimmed
        self.subtitle = subtitle.trimmed
        self.body = body.trimmed
        self.footer = footer.trimmed
        self.callToAction = callToAction?.trimmed.nilIfBlank
    }

    var shareText: String {
        var lines: [String] = []

        if title.isEmpty == false {
            lines.append(title)
        }

        if subtitle.isEmpty == false {
            lines.append(subtitle)
        }

        if body.isEmpty == false {
            lines.append("")
            lines.append(body)
        }

        if let callToAction,
           callToAction.isEmpty == false {
            lines.append("")
            lines.append(callToAction)
        }

        if footer.isEmpty == false {
            lines.append("")
            lines.append(footer)
        }

        return lines.joined(separator: "\n")
    }
}

enum CloseCutShareKind: String, Equatable {
    case app
    case battleWinner
    case circleInvite
    case insight
    case wrap

    var displayName: String {
        switch self {
        case .app:
            return "Share CloseCut"
        case .battleWinner:
            return "Battle Winner"
        case .circleInvite:
            return "Circle Invite"
        case .insight:
            return "Insight"
        case .wrap:
            return "Wrap"
        }
    }

    var systemImage: String {
        switch self {
        case .app:
            return "sparkles"
        case .battleWinner:
            return "crown.fill"
        case .circleInvite:
            return "person.2.fill"
        case .insight:
            return "chart.bar.fill"
        case .wrap:
            return "rectangle.stack.fill"
        }
    }
}
