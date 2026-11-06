import SwiftUI

/// Shows the deploy status returned by the API: Queued → Building → Publishing → Live.
/// It only displays what it is given; polling lives in `ProductsViewModel`.
struct PublishStatusSheet: View {
    let status: DeployStatus?
    let errorMessage: String?
    var isStarting = false
    let onRetry: () -> Void
    let onViewSite: () -> Void
    let onClose: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                steps
                footer
            }
            .padding(24)
        }
        .background(Theme.background)
        .presentationDetents([.medium, .large])
        .presentationCornerRadius(24)
        .presentationDragIndicator(.visible)
        .animation(.easeOut(duration: 0.2), value: status)
    }

    private var isLive: Bool { status?.stage == .live && status?.failed == false }

    private var header: some View {
        HStack(spacing: 12) {
            IconTile(
                icon: isLive ? .tickCircle : .flash,
                foreground: isLive ? Theme.success : Theme.brandStrong,
                background: isLive ? Theme.successSoft : Theme.brandSoft
            )
            VStack(alignment: .leading, spacing: 2) {
                Text(isLive ? "Your website is updated" : "Publishing your changes")
                    .font(Typography.section)
                    .foregroundStyle(Theme.foreground)
                    .accessibilityAddTraits(.isHeader)
                Text(isLive ? "Visitors now see your latest catalog."
                            : "You can close this. Publishing continues in the background.")
                    .font(Typography.secondary)
                    .foregroundStyle(Theme.mutedForeground)
            }
            Spacer(minLength: 0)
        }
    }

    private var steps: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(DeployStage.allCases.enumerated()), id: \.element) { index, stage in
                StepRow(
                    stage: stage,
                    state: state(for: stage),
                    message: stage == status?.stage && status?.failed == true ? status?.message : nil,
                    showsConnector: index < DeployStage.allCases.count - 1
                )
            }
        }
    }

    @ViewBuilder
    private var footer: some View {
        if let errorMessage {
            ErrorBanner(message: errorMessage, actionTitle: "Try again", action: onRetry)
        } else if status?.failed == true {
            HStack {
                PrimaryButton(title: "Close", variant: .ghost, action: onClose)
                Spacer()
                PrimaryButton(title: "Try again", icon: .refresh2, action: onRetry)
            }
        } else if isLive {
            HStack {
                PrimaryButton(title: "Done", variant: .ghost, action: onClose)
                Spacer()
                PrimaryButton(title: "View live site", icon: .exportSquare, action: onViewSite)
            }
        } else {
            HStack {
                Spacer()
                PrimaryButton(title: "Hide", variant: .secondary, action: onClose)
            }
        }
    }

    private func state(for stage: DeployStage) -> StepRow.State {
        guard let status, !isStarting else {
            return stage == .queued ? .current : .pending
        }
        let all = DeployStage.allCases
        let current = all.firstIndex(of: status.stage) ?? 0
        let index = all.firstIndex(of: stage) ?? 0
        if status.failed {
            if index < current { return .done }
            return index == current ? .failed : .pending
        }
        if status.stage == .live || index < current { return .done }
        return index == current ? .current : .pending
    }
}

private struct StepRow: View {
    enum State { case pending, current, done, failed }

    let stage: DeployStage
    let state: State
    let message: String?
    let showsConnector: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 0) {
                indicator
                if showsConnector {
                    Rectangle()
                        .fill(state == .done ? Theme.success : Theme.border)
                        .frame(width: 2)
                        .frame(minHeight: 16, maxHeight: .infinity)
                }
            }
            .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(stage.title)
                    .font(Typography.bodyMedium)
                    .foregroundStyle(titleColor)
                Text(message ?? stage.detail)
                    .font(Typography.secondary)
                    .foregroundStyle(message == nil ? Theme.mutedForeground : Theme.danger)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, 3)
            .padding(.bottom, showsConnector ? 14 : 0)
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(stage.title), \(stateDescription)")
        .accessibilityValue(message ?? "")
    }

    @ViewBuilder
    private var indicator: some View {
        switch state {
        case .done:
            Iconsax(.tickCircle, size: 26)
                .foregroundStyle(Theme.success)
                .frame(width: 28, height: 28)
        case .current:
            ProgressView()
                .controlSize(.small)
                .tint(Theme.primary)
                .frame(width: 28, height: 28)
                .background(Theme.primarySoft, in: Circle())
        case .failed:
            Iconsax(.closeCircle, size: 26)
                .foregroundStyle(Theme.danger)
                .frame(width: 28, height: 28)
        case .pending:
            Circle()
                .strokeBorder(Theme.border, lineWidth: 2)
                .frame(width: 22, height: 22)
                .frame(width: 28, height: 28)
        }
    }

    private var titleColor: Color {
        switch state {
        case .current: Theme.primary
        case .failed: Theme.danger
        case .done: Theme.foreground
        case .pending: Theme.mutedForeground
        }
    }

    private var stateDescription: String {
        switch state {
        case .pending: "waiting"
        case .current: "in progress"
        case .done: "done"
        case .failed: "failed"
        }
    }
}

// MARK: - Previews

private func previewStatus(_ stage: DeployStage, failed: Bool = false) -> DeployStatus {
    DeployStatus(
        deployId: "preview",
        stage: stage,
        failed: failed,
        message: failed ? "The build stopped because an image couldn't be processed. Your current website is still online." : nil,
        updatedAt: .now
    )
}

#Preview("Building") {
    Color.clear.sheet(isPresented: .constant(true)) {
        PublishStatusSheet(status: previewStatus(.building), errorMessage: nil, onRetry: {}, onViewSite: {}, onClose: {})
    }
}

#Preview("Failed") {
    Color.clear.sheet(isPresented: .constant(true)) {
        PublishStatusSheet(status: previewStatus(.building, failed: true), errorMessage: nil, onRetry: {}, onViewSite: {}, onClose: {})
    }
}

#Preview("Live") {
    Color.clear.sheet(isPresented: .constant(true)) {
        PublishStatusSheet(status: previewStatus(.live), errorMessage: nil, onRetry: {}, onViewSite: {}, onClose: {})
    }
}

#Preview("Mock deploy, first attempt fails") {
    @Previewable @State var viewModel = ProductsViewModel.preview(.init(failsFirstDeploy: true))
    Color.clear.sheet(isPresented: .constant(true)) {
        PublishStatusSheet(
            status: viewModel.deployStatus,
            errorMessage: viewModel.deployError,
            isStarting: viewModel.isTriggeringDeploy,
            onRetry: { Task { await viewModel.retryPublish() } },
            onViewSite: {},
            onClose: {}
        )
        .task(id: viewModel.deployPollToken) { await viewModel.pollDeployStatus() }
        .task { await viewModel.publishChanges() }
    }
}
