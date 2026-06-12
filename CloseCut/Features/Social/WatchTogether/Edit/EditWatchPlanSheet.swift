//
//  EditWatchPlanSheet.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 03/06/26.
//

import SwiftUI

struct EditWatchPlanSheet: View {
    @Environment(\.dismiss) private var dismiss

    let plan: WatchPlan
    let isSaving: Bool
    let onCancel: () -> Void
    let onSave: (
        _ title: String,
        _ note: String?,
        _ proposedStartAt: Date?,
        _ proposedEndAt: Date?,
        _ clearProposedSchedule: Bool,
        _ proposedDateText: String?,
        _ locationType: WatchPlanLocationType,
        _ locationName: String?,
        _ locationAddress: String?,
        _ streamingService: String?
    ) -> Void

    @State private var title: String
    @State private var note: String
    @State private var proposedDateText: String
    @State private var hasRealSchedule: Bool
    @State private var proposedStartAt: Date
    @State private var proposedEndAt: Date

    @State private var locationType: WatchPlanLocationType
    @State private var locationName: String
    @State private var locationAddress: String
    @State private var streamingService: String

    @FocusState private var focusedField: Field?

    private enum Field {
        case title
        case note
        case date
        case locationName
        case locationAddress
        case streamingService
    }

    init(
        plan: WatchPlan,
        isSaving: Bool,
        onCancel: @escaping () -> Void,
        onSave: @escaping (
            _ title: String,
            _ note: String?,
            _ proposedStartAt: Date?,
            _ proposedEndAt: Date?,
            _ clearProposedSchedule: Bool,
            _ proposedDateText: String?,
            _ locationType: WatchPlanLocationType,
            _ locationName: String?,
            _ locationAddress: String?,
            _ streamingService: String?
        ) -> Void
    ) {
        self.plan = plan
        self.isSaving = isSaving
        self.onCancel = onCancel
        self.onSave = onSave

        let fallbackStartDate = plan.proposedStartAt ?? plan.confirmedStartAt ?? Calendar.current.date(
            bySettingHour: 20,
            minute: 0,
            second: 0,
            of: Date()
        ) ?? Date()

        let fallbackEndDate = plan.proposedEndAt ?? plan.confirmedEndAt ?? fallbackStartDate.addingTimeInterval(
            plan.media.type == .series ? 60 * 60 : 150 * 60
        )

        _title = State(initialValue: plan.title)
        _note = State(initialValue: plan.note ?? "")
        _proposedDateText = State(initialValue: plan.proposedDateText ?? "")
        _hasRealSchedule = State(initialValue: plan.proposedStartAt != nil || plan.confirmedStartAt != nil)
        _proposedStartAt = State(initialValue: fallbackStartDate)
        _proposedEndAt = State(initialValue: fallbackEndDate)

        _locationType = State(initialValue: plan.locationType)
        _locationName = State(initialValue: plan.locationName ?? "")
        _locationAddress = State(initialValue: plan.locationAddress ?? "")
        _streamingService = State(initialValue: plan.streamingService ?? "")
    }

    private var cleanedTitle: String {
        title.trimmed
    }

    private var cleanedNote: String {
        note.trimmed
    }

    private var cleanedProposedDateText: String {
        proposedDateText.trimmed
    }

    private var cleanedLocationName: String {
        locationName.trimmed
    }

    private var cleanedLocationAddress: String {
        locationAddress.trimmed
    }

    private var cleanedStreamingService: String {
        streamingService.trimmed
    }

    private var canSave: Bool {
        cleanedTitle.isEmpty == false &&
        isSaving == false
    }

    var body: some View {
        NavigationStack {
            ZStack {
                CloseCutColors.backgroundPrimary
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        header

                        mediaCard

                        basicInfoSection

                        scheduleSection

                        locationSection

                        privacyNote

                        if isSaving {
                            savingRow
                        }

                        Spacer(minLength: 24)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle("Edit Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                    }
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .disabled(isSaving)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(
                            cleanedTitle,
                            cleanedNote.nilIfBlank,
                            hasRealSchedule ? proposedStartAt : nil,
                            hasRealSchedule ? proposedEndAt : nil,
                            hasRealSchedule == false,
                            cleanedProposedDateText.nilIfBlank,
                            locationType,
                            cleanedLocationName.nilIfBlank,
                            cleanedLocationAddress.nilIfBlank,
                            cleanedStreamingService.nilIfBlank
                        )
                    }
                    .disabled(canSave == false)
                }
            }
        }
        .preferredColorScheme(.dark)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                focusedField = .title
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: "calendar.badge.clock")
                .font(.title3.weight(.semibold))
                .foregroundStyle(CloseCutColors.accentLight)
                .frame(width: 50, height: 50)
                .background(CloseCutColors.input)
                .clipShape(SwiftUI.Circle())

            VStack(alignment: .leading, spacing: 6) {
                Text("Edit Watch Together plan.")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textPrimary)

                Text("Update the plan details without changing the selected movie or series.")
                    .font(.subheadline)
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Media

    private var mediaCard: some View {
        HStack(alignment: .top, spacing: 12) {
            posterView

            VStack(alignment: .leading, spacing: 7) {
                Text("Selected title")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textTertiary)
                    .textCase(.uppercase)
                    .tracking(0.8)

                Text(plan.media.displayTitle)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textPrimary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Text(plan.media.metadataText)
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .lineLimit(2)

                Text("Media cannot be changed from this edit screen.")
                    .font(.caption2)
                    .foregroundStyle(CloseCutColors.textTertiary)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(CloseCutColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(CloseCutColors.separator, lineWidth: 0.5)
        }
    }

    private var posterView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .fill(CloseCutColors.input)

            if let posterURL = plan.media.posterURL {
                AsyncImage(url: posterURL) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .scaleEffect(0.7)

                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()

                    case .failure:
                        fallbackPoster

                    @unknown default:
                        fallbackPoster
                    }
                }
            } else {
                fallbackPoster
            }
        }
        .frame(width: 62, height: 92)
        .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .stroke(CloseCutColors.separator, lineWidth: 0.5)
        }
        .accessibilityHidden(true)
    }

    private var fallbackPoster: some View {
        ZStack {
            LinearGradient(
                colors: [
                    CloseCutColors.accent.opacity(0.22),
                    CloseCutColors.card.opacity(0.96)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Image(systemName: plan.media.type == .movie ? "film.fill" : "tv.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(CloseCutColors.accentLight)
        }
    }

    // MARK: - Sections

    private var basicInfoSection: some View {
        editSection(
            title: "Plan info",
            subtitle: "Make the plan easy to understand."
        ) {
            VStack(alignment: .leading, spacing: 14) {
                inputField(
                    label: "Plan title",
                    placeholder: "Watch \(plan.media.displayTitle)",
                    text: $title,
                    focusedField: .title,
                    axis: .vertical,
                    lineLimit: 1...2
                )

                inputField(
                    label: "Note optional",
                    placeholder: "Anything the group should know?",
                    text: $note,
                    focusedField: .note,
                    axis: .vertical,
                    lineLimit: 2...4
                )
            }
        }
    }

    private var scheduleSection: some View {
        editSection(
            title: "Schedule",
            subtitle: "Use a real date for calendar export, plus optional friendly text."
        ) {
            VStack(alignment: .leading, spacing: 14) {
                inputField(
                    label: "Proposed date text",
                    placeholder: "Friday night, Sunday afternoon, next week…",
                    text: $proposedDateText,
                    focusedField: .date,
                    axis: .vertical,
                    lineLimit: 1...3
                )

                Toggle(isOn: $hasRealSchedule) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Use real date & time")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(CloseCutColors.textPrimary)

                        Text("Required for calendar export.")
                            .font(.caption)
                            .foregroundStyle(CloseCutColors.textTertiary)
                    }
                }
                .tint(CloseCutColors.accent)
                .padding(14)
                .background(CloseCutColors.input.opacity(0.74))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                if hasRealSchedule {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Starts")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(CloseCutColors.textTertiary)
                            .textCase(.uppercase)
                            .tracking(0.8)

                        DatePicker(
                            "Start date",
                            selection: $proposedStartAt,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .tint(CloseCutColors.accent)
                        .onChange(of: proposedStartAt) { _, newValue in
                            if proposedEndAt <= newValue {
                                proposedEndAt = newValue.addingTimeInterval(
                                    plan.media.type == .series ? 60 * 60 : 150 * 60
                                )
                            }
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(CloseCutColors.input)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Ends")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(CloseCutColors.textTertiary)
                            .textCase(.uppercase)
                            .tracking(0.8)

                        DatePicker(
                            "End date",
                            selection: $proposedEndAt,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .tint(CloseCutColors.accent)
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(CloseCutColors.input)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }

                    Text("This real schedule will be used for Calendar Export. The text field above can still be used as friendly context for the Circle.")
                        .font(.caption2)
                        .foregroundStyle(CloseCutColors.textTertiary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var locationSection: some View {
        editSection(
            title: "Location",
            subtitle: "Choose how this plan will happen."
        ) {
            VStack(alignment: .leading, spacing: 14) {
                Picker("Location type", selection: $locationType) {
                    ForEach(WatchPlanLocationType.allCases) { type in
                        Label(type.displayName, systemImage: type.systemImage)
                            .tag(type)
                    }
                }
                .pickerStyle(.segmented)

                switch locationType {
                case .notDecided:
                    locationHint(
                        icon: "questionmark.circle",
                        text: "You can leave the location undecided and update it later."
                    )

                case .inPerson:
                    inputField(
                        label: "Place name",
                        placeholder: "Cinema, house, venue…",
                        text: $locationName,
                        focusedField: .locationName,
                        axis: .vertical,
                        lineLimit: 1...2
                    )

                    inputField(
                        label: "Address optional",
                        placeholder: "Street, neighborhood, city…",
                        text: $locationAddress,
                        focusedField: .locationAddress,
                        axis: .vertical,
                        lineLimit: 1...3
                    )

                case .streaming:
                    inputField(
                        label: "Streaming service",
                        placeholder: "Netflix, Max, Disney+, Prime…",
                        text: $streamingService,
                        focusedField: .streamingService,
                        axis: .vertical,
                        lineLimit: 1...2
                    )

                case .hybrid:
                    inputField(
                        label: "Place name optional",
                        placeholder: "Cinema, house, venue…",
                        text: $locationName,
                        focusedField: .locationName,
                        axis: .vertical,
                        lineLimit: 1...2
                    )

                    inputField(
                        label: "Streaming service optional",
                        placeholder: "Netflix, Max, Disney+, Prime…",
                        text: $streamingService,
                        focusedField: .streamingService,
                        axis: .vertical,
                        lineLimit: 1...2
                    )
                }
            }
        }
    }

    private func editSection<Content: View>(
        title: String,
        subtitle: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textPrimary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            content()
        }
        .padding(16)
        .background(CloseCutColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(CloseCutColors.separator, lineWidth: 0.5)
        }
    }

    private func inputField(
        label: String,
        placeholder: String,
        text: Binding<String>,
        focusedField: Field,
        axis: Axis,
        lineLimit: ClosedRange<Int>
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(CloseCutColors.textTertiary)
                .textCase(.uppercase)
                .tracking(0.8)

            TextField(placeholder, text: text, axis: axis)
                .focused($focusedField, equals: focusedField)
                .font(.body)
                .foregroundStyle(CloseCutColors.textPrimary)
                .textInputAutocapitalization(.sentences)
                .lineLimit(lineLimit)
                .padding(14)
                .background(CloseCutColors.input)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    private func locationHint(
        icon: String,
        text: String
    ) -> some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(CloseCutColors.textTertiary)
                .padding(.top, 2)

            Text(text)
                .font(.caption)
                .foregroundStyle(CloseCutColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(CloseCutColors.input.opacity(0.74))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var privacyNote: some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: "lock.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(CloseCutColors.textTertiary)
                .padding(.top, 2)

            Text("Edits stay inside this private Circle plan. Nothing from your Personal Timeline is shared automatically.")
                .font(.caption)
                .foregroundStyle(CloseCutColors.textTertiary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(13)
        .background(CloseCutColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var savingRow: some View {
        HStack(spacing: 10) {
            ProgressView()

            Text("Saving plan changes…")
                .font(.caption)
                .foregroundStyle(CloseCutColors.textSecondary)

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(CloseCutColors.input)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
