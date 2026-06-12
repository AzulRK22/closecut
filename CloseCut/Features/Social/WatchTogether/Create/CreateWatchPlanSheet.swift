//
//  CreateWatchPlanSheet.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 03/06/26.
//

import SwiftUI

struct CreateWatchPlanSheet: View {
    let circleRows: [(circle: CloseCircle, membership: CircleMembership)]
    let selectedCircleId: String?
    let initialMedia: WatchPlanMediaSnapshot?
    let isCreating: Bool
    let onCancel: () -> Void
    let onCreate: (WatchPlanCreationDraft) -> Void

    @State private var selectedCircleIdInternal: String

    @State private var selectedTMDBMedia: TMDBMediaSearchResult?
    @State private var selectedMediaSnapshotFromSource: WatchPlanMediaSnapshot?
    @State private var showMediaSearchSheet = false

    @State private var mediaTitle = ""
    @State private var planTitle = ""
    @State private var note = ""
    @State private var proposedDateText = ""

    @State private var hasRealSchedule = false
    @State private var proposedStartAt = Calendar.current.date(
        bySettingHour: 20,
        minute: 0,
        second: 0,
        of: Date()
    ) ?? Date()

    @State private var proposedEndAt = Calendar.current.date(
        byAdding: .minute,
        value: 150,
        to: Calendar.current.date(
            bySettingHour: 20,
            minute: 0,
            second: 0,
            of: Date()
        ) ?? Date()
    ) ?? Date().addingTimeInterval(150 * 60)

    @State private var selectedType: EntryType = .movie
    @State private var locationType: WatchPlanLocationType = .notDecided
    @State private var locationName = ""
    @State private var locationAddress = ""
    @State private var streamingService = ""
    @State private var selectedInviteeIds: Set<String> = []

    @FocusState private var focusedField: Field?

    private enum Field {
        case mediaTitle
        case planTitle
        case note
        case proposedDate
        case locationName
        case locationAddress
        case streamingService
    }

    init(
        circleRows: [(circle: CloseCircle, membership: CircleMembership)],
        selectedCircleId: String?,
        initialMedia: WatchPlanMediaSnapshot? = nil,
        isCreating: Bool,
        onCancel: @escaping () -> Void,
        onCreate: @escaping (WatchPlanCreationDraft) -> Void
    ) {
        self.circleRows = circleRows
        self.selectedCircleId = selectedCircleId
        self.initialMedia = initialMedia
        self.isCreating = isCreating
        self.onCancel = onCancel
        self.onCreate = onCreate

        let fallbackCircleId = circleRows.first?.circle.id ?? ""
        let resolvedCircleId = selectedCircleId?.trimmed.nilIfBlank ?? fallbackCircleId

        _selectedCircleIdInternal = State(initialValue: resolvedCircleId)
        _selectedMediaSnapshotFromSource = State(initialValue: initialMedia)
        _mediaTitle = State(initialValue: initialMedia?.displayTitle ?? "")
        _selectedType = State(initialValue: initialMedia?.type ?? .movie)
        _planTitle = State(initialValue: initialMedia.map { "Watch \($0.displayTitle)" } ?? "")
    }

    private var cleanedMediaTitle: String {
        selectedTMDBMedia?.title.trimmed ??
        selectedMediaSnapshotFromSource?.displayTitle.trimmed ??
        mediaTitle.trimmed
    }

    private var cleanedPlanTitle: String? {
        planTitle.trimmed.nilIfBlank
    }

    private var cleanedNote: String? {
        note.trimmed.nilIfBlank
    }

    private var cleanedProposedDateText: String? {
        proposedDateText.trimmed.nilIfBlank
    }

    private var cleanedLocationName: String? {
        locationName.trimmed.nilIfBlank
    }

    private var cleanedLocationAddress: String? {
        locationAddress.trimmed.nilIfBlank
    }

    private var cleanedStreamingService: String? {
        streamingService.trimmed.nilIfBlank
    }

    private var selectedCircle: CloseCircle? {
        circleRows.first { row in
            row.circle.id == selectedCircleIdInternal
        }?.circle
    }

    private var selectedCircleMembership: CircleMembership? {
        circleRows.first { row in
            row.circle.id == selectedCircleIdInternal
        }?.membership
    }

    private var availableInviteeIds: [String] {
        guard let selectedCircle else {
            return []
        }

        let currentUserId = selectedCircleMembership?.userId.trimmed

        return selectedCircle.memberIds
            .map { $0.trimmed }
            .filter { $0.isEmpty == false }
            .filter { memberId in
                memberId != currentUserId
            }
            .sorted()
    }

    private var hasInviteesAvailable: Bool {
        availableInviteeIds.isEmpty == false
    }

    private var selectedInviteeIdsArray: [String] {
        selectedInviteeIds
            .map { $0.trimmed }
            .filter { $0.isEmpty == false }
            .sorted()
    }

    private var selectedMediaSnapshot: WatchPlanMediaSnapshot? {
        if let selectedTMDBMedia {
            return WatchPlanMediaSnapshotFactory.fromTMDBResult(
                selectedTMDBMedia,
                source: .discover
            )
        }

        if let selectedMediaSnapshotFromSource {
            return selectedMediaSnapshotFromSource
        }

        let cleanedManualTitle = mediaTitle.trimmed

        guard cleanedManualTitle.isEmpty == false else {
            return nil
        }

        return WatchPlanMediaSnapshotFactory.manual(
            title: cleanedManualTitle,
            type: selectedType
        )
    }

    private var canCreate: Bool {
        selectedCircle != nil &&
        selectedMediaSnapshot != nil &&
        selectedInviteeIds.isEmpty == false &&
        isCreating == false
    }

    var body: some View {
        NavigationStack {
            ZStack {
                CloseCutColors.backgroundPrimary
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        header

                        circleSection

                        mediaSection

                        planDetailsSection

                        locationSection

                        inviteesSection

                        privacyNote

                        createButton

                        if isCreating {
                            loadingRow
                        }

                        Spacer(minLength: 24)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle("New Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                    }
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .disabled(isCreating)
                }
            }
        }
        .preferredColorScheme(.dark)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .onAppear {
            syncInviteesForSelectedCircle()

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                if selectedTMDBMedia == nil && selectedMediaSnapshotFromSource == nil {
                    focusedField = .mediaTitle
                }
            }
        }
        .sheet(isPresented: $showMediaSearchSheet) {
            MediaSearchView(
                title: "Choose Title",
                subtitle: "Search TMDB and select the exact movie or series for this Watch Together plan.",
                placeholder: "Search movies or series",
                onCancel: {
                    showMediaSearchSheet = false
                },
                onSelect: { result in
                    applySelectedMedia(result)
                    showMediaSearchSheet = false
                }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack {
                SwiftUI.Circle()
                    .fill(CloseCutColors.accent.opacity(0.18))
                    .frame(width: 52, height: 52)

                Image(systemName: "calendar.badge.plus")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(CloseCutColors.accentLight)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Plan something to watch.")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Create a private Watch Together plan for one Circle. Search TMDB to attach the correct title, poster, year, and metadata.")
                    .font(.subheadline)
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Circle

    private var circleSection: some View {
        formCard {
            sectionHeader(
                title: "Circle",
                subtitle: "Choose who this plan is for."
            )

            if circleRows.isEmpty {
                EmptyStateView(
                    title: "No Circles yet",
                    message: "Create or join a Circle before making a Watch Together plan.",
                    systemImage: "person.2.slash",
                    actionTitle: nil,
                    action: nil
                )
            } else {
                Picker("Circle", selection: $selectedCircleIdInternal) {
                    ForEach(circleRows, id: \.circle.id) { row in
                        Text(row.circle.displayName)
                            .tag(row.circle.id)
                    }
                }
                .pickerStyle(.menu)
                .tint(CloseCutColors.accent)
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(CloseCutColors.input)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .onChange(of: selectedCircleIdInternal) { _, _ in
                    syncInviteesForSelectedCircle()
                }

                if let selectedCircle {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "person.2.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(CloseCutColors.accentLight)
                            .padding(.top, 1)

                        Text(selectedCircle.memberCount == 1 ? "1 member in this Circle." : "\(selectedCircle.memberCount) members in this Circle.")
                            .font(.caption)
                            .foregroundStyle(CloseCutColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer(minLength: 0)
                    }
                    .padding(12)
                    .background(CloseCutColors.input.opacity(0.7))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
        }
    }

    // MARK: - Media

    private var mediaSection: some View {
        formCard {
            sectionHeader(
                title: "Title",
                subtitle: "Search TMDB to attach the correct poster, year, rating, and overview."
            )

            if let selectedTMDBMedia {
                selectedTMDBMediaCard(selectedTMDBMedia)
            } else if let selectedMediaSnapshotFromSource {
                selectedSnapshotCard(selectedMediaSnapshotFromSource)
            } else {
                Button {
                    showMediaSearchSheet = true
                } label: {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(CloseCutColors.accentLight)
                            .frame(width: 34, height: 34)
                            .background(CloseCutColors.input)
                            .clipShape(SwiftUI.Circle())

                        VStack(alignment: .leading, spacing: 5) {
                            Text("Search TMDB")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(CloseCutColors.textPrimary)

                            Text("Recommended. This adds the correct poster, release year, rating, and metadata to the plan.")
                                .font(.caption)
                                .foregroundStyle(CloseCutColors.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Spacer(minLength: 0)

                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(CloseCutColors.textTertiary)
                            .padding(.top, 8)
                    }
                    .padding(14)
                    .background(CloseCutColors.input.opacity(0.74))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)

                Divider()
                    .overlay(CloseCutColors.separator)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Manual fallback")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textTertiary)
                        .textCase(.uppercase)
                        .tracking(0.8)

                    TextField("Movie or series title", text: $mediaTitle)
                        .focused($focusedField, equals: .mediaTitle)
                        .font(.body)
                        .foregroundStyle(CloseCutColors.textPrimary)
                        .textInputAutocapitalization(.words)
                        .submitLabel(.next)
                        .onSubmit {
                            focusedField = .planTitle
                        }
                        .padding(14)
                        .background(CloseCutColors.input)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }

                Picker("Type", selection: $selectedType) {
                    Text("Movie").tag(EntryType.movie)
                    Text("Series").tag(EntryType.series)
                }
                .pickerStyle(.segmented)

                Text("Manual titles still work, but they will not include poster or TMDB metadata.")
                    .font(.caption2)
                    .foregroundStyle(CloseCutColors.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func selectedTMDBMediaCard(
        _ media: TMDBMediaSearchResult
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                MediaPosterView(
                    posterPath: media.posterPath,
                    mediaType: media.mediaType,
                    width: 68,
                    height: 102,
                    cornerRadius: 14
                )

                VStack(alignment: .leading, spacing: 7) {
                    HStack(spacing: 7) {
                        Label("TMDB", systemImage: "sparkles.tv")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(CloseCutColors.accentLight)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(CloseCutColors.input)
                            .clipShape(Capsule())

                        Text(media.entryType.displayName)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(CloseCutColors.textTertiary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(CloseCutColors.input)
                            .clipShape(Capsule())
                    }

                    Text(media.title)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textPrimary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(media.subtitle)
                        .font(.caption)
                        .foregroundStyle(CloseCutColors.textSecondary)
                        .lineLimit(1)

                    if let overview = media.overview?.trimmed.nilIfBlank {
                        Text(overview)
                            .font(.caption)
                            .foregroundStyle(CloseCutColors.textTertiary)
                            .lineLimit(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Spacer(minLength: 0)
            }

            HStack(spacing: 10) {
                Button {
                    showMediaSearchSheet = true
                } label: {
                    Label("Change title", systemImage: "magnifyingglass")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(CloseCutColors.accentLight)
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .background(CloseCutColors.input)
                        .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                }
                .buttonStyle(.plain)

                Button {
                    clearSelectedMedia()
                } label: {
                    Label("Use manual", systemImage: "pencil")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .background(CloseCutColors.input)
                        .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .background(CloseCutColors.input.opacity(0.74))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(CloseCutColors.accentLight.opacity(0.45), lineWidth: 0.7)
        }
    }

    private func selectedSnapshotCard(
        _ media: WatchPlanMediaSnapshot
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                MediaPosterView(
                    posterPath: media.posterPath,
                    mediaType: media.tmdbMediaTypeRaw == TMDBMediaType.tv.rawValue ? .tv : .movie,
                    width: 68,
                    height: 102,
                    cornerRadius: 14
                )

                VStack(alignment: .leading, spacing: 7) {
                    HStack(spacing: 7) {
                        Label(media.source.displayName, systemImage: media.source.systemImage)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(CloseCutColors.accentLight)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(CloseCutColors.input)
                            .clipShape(Capsule())

                        Text(media.type.displayName)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(CloseCutColors.textTertiary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(CloseCutColors.input)
                            .clipShape(Capsule())
                    }

                    Text(media.displayTitle)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textPrimary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(media.metadataText)
                        .font(.caption)
                        .foregroundStyle(CloseCutColors.textSecondary)
                        .lineLimit(1)

                    if let overview = media.overview?.trimmed.nilIfBlank {
                        Text(overview)
                            .font(.caption)
                            .foregroundStyle(CloseCutColors.textTertiary)
                            .lineLimit(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Spacer(minLength: 0)
            }

            HStack(spacing: 10) {
                Button {
                    showMediaSearchSheet = true
                } label: {
                    Label("Change title", systemImage: "magnifyingglass")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(CloseCutColors.accentLight)
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .background(CloseCutColors.input)
                        .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                }
                .buttonStyle(.plain)

                Button {
                    clearSelectedMedia()
                } label: {
                    Label("Use manual", systemImage: "pencil")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .background(CloseCutColors.input)
                        .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .background(CloseCutColors.input.opacity(0.74))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(CloseCutColors.accentLight.opacity(0.45), lineWidth: 0.7)
        }
    }

    // MARK: - Plan Details

    private var planDetailsSection: some View {
        formCard {
            sectionHeader(
                title: "Plan details",
                subtitle: "Optional context helps people respond faster."
            )

            VStack(alignment: .leading, spacing: 8) {
                Text("Plan title optional")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textTertiary)
                    .textCase(.uppercase)
                    .tracking(0.8)

                TextField("Friday movie night, Rewatch plan…", text: $planTitle)
                    .focused($focusedField, equals: .planTitle)
                    .font(.body)
                    .foregroundStyle(CloseCutColors.textPrimary)
                    .textInputAutocapitalization(.sentences)
                    .submitLabel(.next)
                    .onSubmit {
                        focusedField = .proposedDate
                    }
                    .padding(14)
                    .background(CloseCutColors.input)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("When optional")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textTertiary)
                    .textCase(.uppercase)
                    .tracking(0.8)

                TextField("Tonight, Friday 8 PM, next weekend…", text: $proposedDateText)
                    .focused($focusedField, equals: .proposedDate)
                    .font(.body)
                    .foregroundStyle(CloseCutColors.textPrimary)
                    .textInputAutocapitalization(.sentences)
                    .submitLabel(.next)
                    .onSubmit {
                        focusedField = .note
                    }
                    .padding(14)
                    .background(CloseCutColors.input)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }

            realScheduleSection

            VStack(alignment: .leading, spacing: 8) {
                Text("Note optional")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textTertiary)
                    .textCase(.uppercase)
                    .tracking(0.8)

                TextField("Why this pick?", text: $note, axis: .vertical)
                    .focused($focusedField, equals: .note)
                    .font(.body)
                    .foregroundStyle(CloseCutColors.textPrimary)
                    .textInputAutocapitalization(.sentences)
                    .lineLimit(2...4)
                    .submitLabel(.done)
                    .padding(14)
                    .background(CloseCutColors.input)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
    }

    private var realScheduleSection: some View {
        VStack(alignment: .leading, spacing: 10) {
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
                                selectedType == .series ? 60 * 60 : 150 * 60
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

    // MARK: - Location

    private var locationSection: some View {
        formCard {
            sectionHeader(
                title: "Where",
                subtitle: "Keep it flexible if the group has not decided yet."
            )

            Picker("Location", selection: $locationType) {
                ForEach(WatchPlanLocationType.allCases) { type in
                    Text(type.displayName)
                        .tag(type)
                }
            }
            .pickerStyle(.menu)
            .tint(CloseCutColors.accent)
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(CloseCutColors.input)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            if locationType == .inPerson || locationType == .hybrid {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Place optional")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textTertiary)
                        .textCase(.uppercase)
                        .tracking(0.8)

                    TextField("Cinema, home, venue…", text: $locationName)
                        .focused($focusedField, equals: .locationName)
                        .font(.body)
                        .foregroundStyle(CloseCutColors.textPrimary)
                        .textInputAutocapitalization(.words)
                        .submitLabel(.next)
                        .onSubmit {
                            focusedField = .locationAddress
                        }
                        .padding(14)
                        .background(CloseCutColors.input)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Address optional")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textTertiary)
                        .textCase(.uppercase)
                        .tracking(0.8)

                    TextField("Street, neighborhood, city…", text: $locationAddress)
                        .focused($focusedField, equals: .locationAddress)
                        .font(.body)
                        .foregroundStyle(CloseCutColors.textPrimary)
                        .textInputAutocapitalization(.words)
                        .padding(14)
                        .background(CloseCutColors.input)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }

            if locationType == .streaming || locationType == .hybrid {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Streaming optional")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textTertiary)
                        .textCase(.uppercase)
                        .tracking(0.8)

                    TextField("Netflix, Max, Disney+…", text: $streamingService)
                        .focused($focusedField, equals: .streamingService)
                        .font(.body)
                        .foregroundStyle(CloseCutColors.textPrimary)
                        .textInputAutocapitalization(.words)
                        .padding(14)
                        .background(CloseCutColors.input)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
        }
    }

    // MARK: - Invitees

    private var inviteesSection: some View {
        formCard {
            sectionHeader(
                title: "Invitees",
                subtitle: "Choose who should respond to this plan."
            )

            if selectedCircle == nil {
                Text("Choose a Circle first.")
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else if hasInviteesAvailable == false {
                HStack(alignment: .top, spacing: 9) {
                    Image(systemName: "person.badge.plus")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textTertiary)
                        .padding(.top, 2)

                    Text("This Circle does not have other members available locally yet. Add or sync members before creating a Watch Together plan.")
                        .font(.caption)
                        .foregroundStyle(CloseCutColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer(minLength: 0)
                }
                .padding(12)
                .background(CloseCutColors.input.opacity(0.74))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            } else {
                HStack(spacing: 10) {
                    Button {
                        selectedInviteeIds = Set(availableInviteeIds)
                    } label: {
                        Text("Select all")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(CloseCutColors.accentLight)
                    }
                    .buttonStyle(.plain)
                    .disabled(isCreating)

                    Button {
                        selectedInviteeIds = []
                    } label: {
                        Text("Clear")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(CloseCutColors.textTertiary)
                    }
                    .buttonStyle(.plain)
                    .disabled(isCreating)

                    Spacer(minLength: 0)

                    Text(selectedInviteeIds.isEmpty ? "Required" : "\(selectedInviteeIds.count) selected")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(selectedInviteeIds.isEmpty ? CloseCutColors.failed : CloseCutColors.textTertiary)
                }

                VStack(spacing: 10) {
                    ForEach(availableInviteeIds, id: \.self) { memberId in
                        inviteeToggleRow(memberId: memberId)
                    }
                }

                Text("Member names can be improved later when Circle member profile snapshots are available locally.")
                    .font(.caption2)
                    .foregroundStyle(CloseCutColors.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func inviteeToggleRow(
        memberId: String
    ) -> some View {
        let isSelected = selectedInviteeIds.contains(memberId)

        return Button {
            if isSelected {
                selectedInviteeIds.remove(memberId)
            } else {
                selectedInviteeIds.insert(memberId)
            }
        } label: {
            HStack(spacing: 11) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(isSelected ? CloseCutColors.accentLight : CloseCutColors.textTertiary)

                VStack(alignment: .leading, spacing: 3) {
                    Text(memberId)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textPrimary)
                        .lineLimit(1)

                    Text("Circle member")
                        .font(.caption)
                        .foregroundStyle(CloseCutColors.textTertiary)
                }

                Spacer(minLength: 0)
            }
            .padding(12)
            .background(isSelected ? CloseCutColors.accent.opacity(0.14) : CloseCutColors.input.opacity(0.74))
            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .stroke(isSelected ? CloseCutColors.accent.opacity(0.55) : CloseCutColors.separator, lineWidth: 0.5)
            }
        }
        .buttonStyle(.plain)
        .disabled(isCreating)
    }

    // MARK: - Privacy

    private var privacyNote: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "lock.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(CloseCutColors.accentLight)
                .frame(width: 28, height: 28)
                .background(CloseCutColors.input)
                .clipShape(SwiftUI.Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text("Private Circle plan")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textPrimary)

                Text("This creates a plan only inside the selected Circle. It does not add anything to your Personal Timeline until you choose to mark it watched later.")
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(CloseCutColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(CloseCutColors.separator, lineWidth: 0.5)
        }
    }

    // MARK: - Actions

    private var createButton: some View {
        Button {
            guard canCreate else {
                return
            }

            guard let mediaSnapshot = selectedMediaSnapshot else {
                return
            }

            let draft = WatchPlanCreationDraft(
                circleId: selectedCircleIdInternal,
                media: mediaSnapshot,
                planTitle: cleanedPlanTitle,
                note: cleanedNote,
                proposedStartAt: hasRealSchedule ? proposedStartAt : nil,
                proposedEndAt: hasRealSchedule ? proposedEndAt : nil,
                proposedDateText: cleanedProposedDateText,
                locationType: locationType,
                locationName: cleanedLocationName,
                locationAddress: cleanedLocationAddress,
                streamingService: cleanedStreamingService,
                invitedMemberIds: selectedInviteeIdsArray
            )

            onCreate(draft)
        } label: {
            HStack(spacing: 8) {
                if isCreating {
                    ProgressView()
                        .scaleEffect(0.85)
                }

                Text(isCreating ? "Creating plan…" : "Create Watch Plan")
                    .font(.headline.weight(.semibold))
            }
            .foregroundStyle(canCreate ? .white : CloseCutColors.textTertiary)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(canCreate ? CloseCutColors.accent : CloseCutColors.input)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(canCreate == false)
    }

    private var loadingRow: some View {
        HStack(spacing: 10) {
            ProgressView()

            Text("Saving your Watch Together plan…")
                .font(.caption)
                .foregroundStyle(CloseCutColors.textSecondary)

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(CloseCutColors.input)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    // MARK: - Helpers

    private func applySelectedMedia(
        _ media: TMDBMediaSearchResult
    ) {
        selectedTMDBMedia = media
        selectedMediaSnapshotFromSource = nil
        mediaTitle = media.title
        selectedType = media.entryType

        if planTitle.trimmed.isEmpty {
            planTitle = "Watch \(media.title)"
        }

        if proposedEndAt <= proposedStartAt {
            proposedEndAt = proposedStartAt.addingTimeInterval(
                media.entryType == .series ? 60 * 60 : 150 * 60
            )
        }

        focusedField = .planTitle
    }

    private func clearSelectedMedia() {
        selectedTMDBMedia = nil
        selectedMediaSnapshotFromSource = nil
        mediaTitle = ""
        focusedField = .mediaTitle
    }

    private func syncInviteesForSelectedCircle() {
        selectedInviteeIds = Set(availableInviteeIds)
    }

    private func formCard<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
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

    private func sectionHeader(
        title: String,
        subtitle: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline.weight(.semibold))
                .foregroundStyle(CloseCutColors.textPrimary)

            Text(subtitle)
                .font(.caption)
                .foregroundStyle(CloseCutColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct WatchPlanCreationDraft: Equatable {
    let circleId: String
    let media: WatchPlanMediaSnapshot
    let planTitle: String?
    let note: String?
    let proposedStartAt: Date?
    let proposedEndAt: Date?
    let proposedDateText: String?
    let locationType: WatchPlanLocationType
    let locationName: String?
    let locationAddress: String?
    let streamingService: String?
    let invitedMemberIds: [String]

    var mediaTitle: String {
        media.displayTitle
    }

    var type: EntryType {
        media.type
    }
}
