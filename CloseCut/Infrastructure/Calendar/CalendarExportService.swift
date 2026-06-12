//
//  CalendarExportService.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 12/06/26.
//

import Foundation

struct CalendarExportItem: Identifiable {
    let id = UUID()
    let url: URL
}

enum CalendarExportError: LocalizedError {
    case missingSchedule
    case couldNotWriteFile

    var errorDescription: String? {
        switch self {
        case .missingSchedule:
            return "This plan needs a confirmed or proposed date before it can be exported."
        case .couldNotWriteFile:
            return "Couldn’t create the calendar file."
        }
    }
}

enum CalendarExportService {
    static func exportICS(
        for plan: WatchPlan
    ) throws -> CalendarExportItem {
        guard let startDate = effectiveStartDate(for: plan) else {
            throw CalendarExportError.missingSchedule
        }

        let endDate = effectiveEndDate(
            for: plan,
            startDate: startDate
        )

        let fileName = sanitizedFileName(
            "\(plan.media.displayTitle)-CloseCut"
        ) + ".ics"

        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(fileName)

        let ics = buildICS(
            plan: plan,
            startDate: startDate,
            endDate: endDate
        )

        do {
            try ics.write(
                to: fileURL,
                atomically: true,
                encoding: .utf8
            )

            return CalendarExportItem(url: fileURL)
        } catch {
            throw CalendarExportError.couldNotWriteFile
        }
    }

    static func canExport(
        _ plan: WatchPlan
    ) -> Bool {
        plan.isActive &&
        plan.status != .canceled &&
        effectiveStartDate(for: plan) != nil
    }

    static func exportReadinessText(
        for plan: WatchPlan
    ) -> String {
        if plan.status == .canceled {
            return "Canceled plans cannot be added to calendar."
        }

        if effectiveStartDate(for: plan) == nil {
            return "Set a proposed or confirmed date before exporting."
        }

        if plan.confirmedStartAt != nil {
            return "Ready to export using the confirmed schedule."
        }

        return "Ready to export using the proposed schedule."
    }

    // MARK: - ICS

    private static func buildICS(
        plan: WatchPlan,
        startDate: Date,
        endDate: Date
    ) -> String {
        let uid = "\(plan.id)@closecut.app"
        let now = Date()

        let summary = "CloseCut: \(plan.media.displayTitle)"
        let location = locationText(for: plan)
        let description = descriptionText(for: plan)

        return """
        BEGIN:VCALENDAR
        VERSION:2.0
        PRODID:-//CloseCut//Watch Together//EN
        CALSCALE:GREGORIAN
        METHOD:PUBLISH
        BEGIN:VEVENT
        UID:\(escapeICS(uid))
        DTSTAMP:\(formatICSDate(now))
        DTSTART:\(formatICSDate(startDate))
        DTEND:\(formatICSDate(endDate))
        SUMMARY:\(escapeICS(summary))
        DESCRIPTION:\(escapeICS(description))
        LOCATION:\(escapeICS(location))
        END:VEVENT
        END:VCALENDAR
        """
    }

    private static func descriptionText(
        for plan: WatchPlan
    ) -> String {
        var lines: [String] = []

        lines.append("Watch Together plan from CloseCut")
        lines.append("Circle: \(plan.displayCircleName)")
        lines.append("Media: \(plan.media.displayTitle)")
        lines.append("Status: \(plan.status.displayName)")

        if let note = plan.displayNote {
            lines.append("")
            lines.append("Note:")
            lines.append(note)
        }

        if let proposedDateText = plan.proposedDateText?.trimmed.nilIfBlank,
           plan.proposedStartAt == nil,
           plan.confirmedStartAt == nil {
            lines.append("")
            lines.append("Proposed time:")
            lines.append(proposedDateText)
        }

        if plan.responseSummaryText != "No responses yet" {
            lines.append("")
            lines.append("Responses: \(plan.responseSummaryText)")
        }

        lines.append("")
        lines.append("Created in CloseCut.")

        return lines.joined(separator: "\n")
    }

    private static func locationText(
        for plan: WatchPlan
    ) -> String {
        switch plan.locationType {
        case .inPerson:
            return [
                plan.locationName?.trimmed.nilIfBlank,
                plan.locationAddress?.trimmed.nilIfBlank
            ]
            .compactMap { $0 }
            .joined(separator: ", ")

        case .streaming:
            return plan.streamingService?.trimmed.nilIfBlank ?? "Streaming"

        case .hybrid:
            let inPerson = [
                plan.locationName?.trimmed.nilIfBlank,
                plan.locationAddress?.trimmed.nilIfBlank
            ]
            .compactMap { $0 }
            .joined(separator: ", ")

            let streaming = plan.streamingService?.trimmed.nilIfBlank

            if inPerson.isEmpty == false,
               let streaming {
                return "\(inPerson) + \(streaming)"
            }

            if inPerson.isEmpty == false {
                return inPerson
            }

            return streaming ?? "Hybrid"

        case .notDecided:
            return ""
        }
    }

    // MARK: - Dates

    private static func effectiveStartDate(
        for plan: WatchPlan
    ) -> Date? {
        if let confirmedStartAt = plan.confirmedStartAt {
            return confirmedStartAt
        }

        if let proposedStartAt = plan.proposedStartAt {
            return proposedStartAt
        }

        return nil
    }

    private static func effectiveEndDate(
        for plan: WatchPlan,
        startDate: Date
    ) -> Date {
        if let confirmedEndAt = plan.confirmedEndAt,
           confirmedEndAt > startDate {
            return confirmedEndAt
        }

        if let proposedEndAt = plan.proposedEndAt,
           proposedEndAt > startDate {
            return proposedEndAt
        }

        let fallbackDuration: TimeInterval = plan.media.type == .series
            ? 60 * 60
            : 150 * 60

        return startDate.addingTimeInterval(fallbackDuration)
    }

    private static func formatICSDate(
        _ date: Date
    ) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        return formatter.string(from: date)
    }

    // MARK: - Escaping

    private static func escapeICS(
        _ value: String
    ) -> String {
        value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: ";", with: "\\;")
            .replacingOccurrences(of: ",", with: "\\,")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "")
    }

    private static func sanitizedFileName(
        _ value: String
    ) -> String {
        let cleaned = value
            .trimmed
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
            .replacingOccurrences(of: "\\", with: "-")
            .replacingOccurrences(of: "?", with: "")
            .replacingOccurrences(of: "*", with: "")
            .replacingOccurrences(of: "\"", with: "")
            .replacingOccurrences(of: "<", with: "")
            .replacingOccurrences(of: ">", with: "")
            .replacingOccurrences(of: "|", with: "")

        return cleaned.isEmpty ? "CloseCut-Watch-Plan" : cleaned
    }
}
