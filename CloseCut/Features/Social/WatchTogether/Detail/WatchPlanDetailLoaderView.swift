//
//  WatchPlanDetailLoaderView.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 03/06/26.
//

import SwiftUI
import SwiftData

struct WatchPlanDetailLoaderView: View {
    @Environment(\.modelContext) private var modelContext

    let planId: String
    let currentUserId: String
    let currentUserDisplayName: String

    @Query(sort: \LocalWatchPlan.updatedAt, order: .reverse)
    private var localPlans: [LocalWatchPlan]

    @State private var didAttemptRemoteRefresh = false
    @State private var isRefreshing = false
    @State private var errorMessage: String?

    private let remoteDataSource = WatchPlanRemoteDataSource()

    private var cleanedPlanId: String {
        planId.trimmed
    }

    private var localPlan: WatchPlan? {
        localPlans.first { $0.id == cleanedPlanId }?.domain
    }

    var body: some View {
        Group {
            if let localPlan {
                WatchPlanDetailView(
                    initialPlan: localPlan,
                    currentUserId: currentUserId,
                    currentUserDisplayName: currentUserDisplayName
                )
            } else {
                missingPlanView
            }
        }
        .task(id: cleanedPlanId) {
            await refreshIfNeeded()
        }
    }

    private var missingPlanView: some View {
        ZStack {
            CloseCutColors.backgroundPrimary
                .ignoresSafeArea()

            VStack(spacing: 16) {
                if isRefreshing {
                    ProgressView()
                        .tint(CloseCutColors.accent)

                    Text("Loading Watch Together plan…")
                        .font(.subheadline)
                        .foregroundStyle(CloseCutColors.textSecondary)
                } else {
                    EmptyStateView(
                        title: "Plan not found",
                        message: errorMessage ?? "This Watch Together plan is not available locally yet. Pull to refresh from Social or Settings.",
                        systemImage: "calendar.badge.exclamationmark",
                        actionTitle: "Try again",
                        action: {
                            Task {
                                await refreshIfNeeded(force: true)
                            }
                        }
                    )
                }
            }
            .padding(20)
        }
        .preferredColorScheme(.dark)
    }

    private func refreshIfNeeded(force: Bool = false) async {
        guard cleanedPlanId.isEmpty == false else {
            errorMessage = "The plan id is missing."
            return
        }

        guard force || didAttemptRemoteRefresh == false else {
            return
        }

        guard localPlan == nil else {
            return
        }

        didAttemptRemoteRefresh = true
        isRefreshing = true
        errorMessage = nil

        defer {
            isRefreshing = false
        }

        do {
            let allPlans = try await fetchPlanFromKnownLocalCircles()

            guard let plan = allPlans.first(where: { $0.id == cleanedPlanId }) else {
                errorMessage = "This plan could not be found in your active Circles."
                return
            }

            try upsertRemotePlan(plan)

            let responses = try await remoteDataSource.fetchResponses(
                circleId: plan.circleId,
                planId: plan.id,
                includeDeleted: true
            )

            for response in responses {
                try upsertRemoteResponse(response)
            }
        } catch {
            errorMessage = error.localizedDescription

            #if DEBUG
            print("⚠️ WatchPlanDetailLoaderView refresh failed:", error.localizedDescription)
            #endif
        }
    }

    private func fetchPlanFromKnownLocalCircles() async throws -> [WatchPlan] {
        let localCircleIds = try fetchLocalCircleIds()

        guard localCircleIds.isEmpty == false else {
            return []
        }

        return try await remoteDataSource.fetchPlansForCircles(
            circleIds: localCircleIds,
            includeDeleted: true,
            limitPerCircle: 50
        )
    }

    private func fetchLocalCircleIds() throws -> [String] {
        let descriptor = FetchDescriptor<LocalCircle>(
            sortBy: [
                SortDescriptor(\LocalCircle.updatedAt, order: .reverse)
            ]
        )

        return try modelContext.fetch(descriptor)
            .filter { $0.deletedAt == nil }
            .map { $0.id.trimmed }
            .filter { $0.isEmpty == false }
    }

    private func upsertRemotePlan(_ remotePlan: WatchPlan) throws {
        let descriptor = FetchDescriptor<LocalWatchPlan>(
            predicate: #Predicate { plan in
                plan.id == remotePlan.id
            }
        )

        if let existing = try modelContext.fetch(descriptor).first {
            var syncedPlan = remotePlan
            syncedPlan.syncStatus = .synced
            existing.update(from: syncedPlan)
            existing.syncStatusRaw = SyncStatus.synced.rawValue
            try modelContext.save()
            return
        }

        var syncedPlan = remotePlan
        syncedPlan.syncStatus = .synced

        let localPlan = LocalWatchPlan(
            id: syncedPlan.id,
            ownerId: syncedPlan.ownerId,
            ownerDisplayName: syncedPlan.ownerDisplayName,
            circleId: syncedPlan.circleId,
            circleName: syncedPlan.circleName,
            title: syncedPlan.title,
            note: syncedPlan.note,
            media: syncedPlan.media,
            proposedStartAt: syncedPlan.proposedStartAt,
            proposedEndAt: syncedPlan.proposedEndAt,
            proposedDateText: syncedPlan.proposedDateText,
            locationType: syncedPlan.locationType,
            locationName: syncedPlan.locationName,
            locationAddress: syncedPlan.locationAddress,
            streamingService: syncedPlan.streamingService,
            status: syncedPlan.status,
            source: syncedPlan.source,
            invitedMemberIds: syncedPlan.invitedMemberIds,
            acceptedMemberIds: syncedPlan.acceptedMemberIds,
            declinedMemberIds: syncedPlan.declinedMemberIds,
            maybeMemberIds: syncedPlan.maybeMemberIds,
            confirmedStartAt: syncedPlan.confirmedStartAt,
            confirmedEndAt: syncedPlan.confirmedEndAt,
            createdAt: syncedPlan.createdAt,
            updatedAt: syncedPlan.updatedAt,
            deletedAt: syncedPlan.deletedAt,
            syncStatus: .synced
        )

        modelContext.insert(localPlan)
        try modelContext.save()
    }

    private func upsertRemoteResponse(_ remoteResponse: WatchPlanResponse) throws {
        let descriptor = FetchDescriptor<LocalWatchPlanResponse>(
            predicate: #Predicate { response in
                response.id == remoteResponse.id
            }
        )

        if let existing = try modelContext.fetch(descriptor).first {
            var syncedResponse = remoteResponse
            syncedResponse.syncStatus = .synced
            existing.update(from: syncedResponse)
            existing.syncStatusRaw = SyncStatus.synced.rawValue
            try modelContext.save()
            return
        }

        var syncedResponse = remoteResponse
        syncedResponse.syncStatus = .synced

        let localResponse = LocalWatchPlanResponse(
            id: syncedResponse.id,
            planId: syncedResponse.planId,
            circleId: syncedResponse.circleId,
            userId: syncedResponse.userId,
            userDisplayName: syncedResponse.userDisplayName,
            responseType: syncedResponse.responseType,
            note: syncedResponse.note,
            suggestedStartAt: syncedResponse.suggestedStartAt,
            suggestedDateText: syncedResponse.suggestedDateText,
            createdAt: syncedResponse.createdAt,
            updatedAt: syncedResponse.updatedAt,
            deletedAt: syncedResponse.deletedAt,
            syncStatus: .synced
        )

        modelContext.insert(localResponse)
        try modelContext.save()
    }
}
