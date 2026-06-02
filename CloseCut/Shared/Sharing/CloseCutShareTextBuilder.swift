//
//  CloseCutShareTextBuilder.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 02/06/26.
//

import Foundation

enum CloseCutShareTextBuilder {

    // MARK: - App

    static func appInvite(
        displayName: String
    ) -> CloseCutShareItem {
        let cleanedName = displayName.trimmed
        let senderName = cleanedName.isEmpty ? "Someone" : cleanedName

        let title = "\(senderName) invited you to try CloseCut"
        let subtitle = "A private movie and series journal."

        let body = """
        I’m using CloseCut to keep track of what I watch, save titles for later, and decide what to watch next.

        It’s private by default, and you only share what you choose.
        """

        let callToAction = "Try it when you want to stop forgetting good movies."

        return CloseCutShareItem(
            kind: .app,
            title: title,
            subtitle: subtitle,
            body: body,
            footer: "CloseCut",
            callToAction: callToAction
        )
    }

    // MARK: - Battle

    static func battleWinner(
        winnerTitle: String,
        metadataText: String,
        optionCount: Int,
        sourceText: String
    ) -> CloseCutShareItem {
        let cleanedTitle = winnerTitle.trimmed.isEmpty
            ? "Tonight’s pick"
            : winnerTitle.trimmed

        let cleanedMetadata = metadataText.trimmed
        let cleanedSource = sourceText.trimmed.isEmpty
            ? "Battle"
            : sourceText.trimmed

        let optionText = optionCount == 1
            ? "Picked from 1 option"
            : "Picked from \(optionCount) contenders"

        let subtitleParts = [
            optionText,
            cleanedMetadata
        ]
        .filter { $0.isEmpty == false }

        return CloseCutShareItem(
            kind: .battleWinner,
            title: "CloseCut Battle picked: \(cleanedTitle)",
            subtitle: subtitleParts.joined(separator: " • "),
            body: "A private Battle helped choose what deserved the night.",
            footer: "Decided privately in CloseCut.",
            callToAction: "Source: \(cleanedSource)"
        )
    }

    // MARK: - Circle

    static func circleInvite(
        circleName: String,
        inviteCode: String,
        ownerDisplayName: String?
    ) -> CloseCutShareItem {
        let cleanedCircleName = circleName.trimmed.isEmpty
            ? "my CloseCut Circle"
            : circleName.trimmed

        let cleanedInviteCode = inviteCode.normalizedInviteCode
        let cleanedOwnerName = ownerDisplayName?.trimmed.nilIfBlank

        let title: String

        if let cleanedOwnerName {
            title = "\(cleanedOwnerName) invited you to join \(cleanedCircleName)"
        } else {
            title = "Join \(cleanedCircleName)"
        }

        let body: String

        if cleanedInviteCode.isEmpty {
            body = "This is a private CloseCut Circle for sharing movie and series memories with people you trust."
        } else {
            body = """
            Use invite code: \(cleanedInviteCode)

            This is a private CloseCut Circle for sharing movie and series memories with people you trust.
            """
        }

        return CloseCutShareItem(
            kind: .circleInvite,
            title: title,
            subtitle: "Private Circle invite.",
            body: body,
            footer: "CloseCut — share with the people who matter.",
            callToAction: nil
        )
    }
}
