import SwiftUI
import PhotosUI

struct ProfileView: View {
    @Bindable var store: MemberStore
    @Binding var appearanceMode: AppearanceMode
    @State private var appeared: Bool = false
    @State private var showingDisconnectConfirmation: Bool = false
    @State private var showingPhotoOptions: Bool = false
    @State private var showingLibraryPicker: Bool = false
    @State private var showingCamera: Bool = false
    @State private var pickedItem: PhotosPickerItem?

    private var avatars: AvatarStore { AvatarStore.shared }

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                PageIntroduction(
                    eyebrow: "Your space",
                    title: store.profile.firstName.isEmpty ? "Your space." : "Hey, \(store.profile.firstName).",
                    subtitle: "Part of something stronger."
                )
                profileHeader
                pinnedBadges
                allTimeStats
                appearanceSection
                settingsSection
                mindbodyConnectionSection
                mindbodyLink
            }
            .padding(.horizontal, 22)
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
        .background(Theme.background.ignoresSafeArea())
        .task {
            await avatars.loadIfNeeded()
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                appeared = true
            }
        }
        .confirmationDialog("Profile Photo", isPresented: $showingPhotoOptions, titleVisibility: .visible) {
            if CameraPicker.isAvailable {
                Button("Take Photo") { showingCamera = true }
            }
            Button("Choose from Library") { showingLibraryPicker = true }
            if avatars.hasOwnPhoto {
                Button("Remove Photo", role: .destructive) {
                    Task { await avatars.removePhoto() }
                }
            }
            Button("Cancel", role: .cancel) {}
        }
        .photosPicker(isPresented: $showingLibraryPicker, selection: $pickedItem, matching: .images)
        .fullScreenCover(isPresented: $showingCamera) {
            CameraPicker { data in
                Task { await avatars.setPhoto(imageData: data, memberName: displayName) }
            }
            .ignoresSafeArea()
        }
        .onChange(of: pickedItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self) {
                    await avatars.setPhoto(imageData: data, memberName: displayName)
                }
                pickedItem = nil
            }
        }
        .alert("Disconnect Mindbody?", isPresented: $showingDisconnectConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Disconnect", role: .destructive) {
                store.disconnectMindbody()
            }
        } message: {
            Text("This will remove your saved Mindbody credentials. You can reconnect anytime.")
        }
    }

    private var profileHeader: some View {
        VStack(spacing: 16) {
            Button {
                showingPhotoOptions = true
            } label: {
                ZStack(alignment: .bottomTrailing) {
                    AvatarView(
                        clientId: avatars.ownClientId,
                        initials: profileInitials,
                        size: 64
                    )
                    .overlay {
                        if avatars.isUploading {
                            ZStack {
                                Circle().fill(Color.black.opacity(0.35))
                                ProgressView()
                                    .tint(.white)
                            }
                        }
                    }

                    ZStack {
                        Circle()
                            .fill(Theme.buttonBackground)
                        Image(systemName: "camera.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Theme.buttonForeground)
                    }
                    .frame(width: 30, height: 30)
                    .overlay(Circle().stroke(Theme.background, lineWidth: 2))
                }
            }
            .disabled(avatars.isUploading)
            .sensoryFeedback(.impact(weight: .light), trigger: showingPhotoOptions)

            if let error = avatars.errorMessage {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption)
                    Text(error)
                        .font(.caption)
                }
                .foregroundStyle(Theme.danger)
                .multilineTextAlignment(.center)
            }

            VStack(spacing: 4) {
                Text(store.profile.fullName)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Theme.cream)
                Text("Member since \(store.profile.memberSince.formatted(.dateTime.month(.wide).year()))")
                    .font(.subheadline)
                    .foregroundStyle(Theme.creamSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .opacity(appeared ? 1 : 0)
    }

    private var profileInitials: String {
        let initials = "\(store.profile.firstName.prefix(1))\(store.profile.lastName.prefix(1))"
        return initials.isEmpty ? "U" : initials.uppercased()
    }

    /// Same "First L." display name the feed and leaderboard use.
    private var displayName: String {
        let first = store.profile.firstName
        let lastInitial = store.profile.lastName.first.map { String($0) } ?? ""
        guard !first.isEmpty else { return "Member" }
        return lastInitial.isEmpty ? first : "\(first) \(lastInitial)."
    }

    private var pinnedBadges: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Badge Showcase")
                .font(.headline.weight(.bold))
                .foregroundStyle(Theme.cream)

            HStack(spacing: 20) {
                ForEach(pinnedBadgesList) { badge in
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(Theme.accent)
                                .frame(width: 56, height: 56)
                            Image(systemName: badge.icon)
                                .font(.system(size: 22))
                                .foregroundStyle(Theme.accentInk)
                        }
                        Text(badge.name)
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(Theme.creamSecondary)
                            .lineLimit(1)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(20)
        .softCard()
        .opacity(appeared ? 1 : 0)
    }

    private var pinnedBadgesList: [Badge] {
        store.profile.pinnedBadgeIds.compactMap { id in
            store.badges.first(where: { $0.id == id })
        }
    }

    private var allTimeStats: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("All-Time Stats")
                .font(.headline.weight(.bold))
                .foregroundStyle(Theme.cream)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ProfileStatCell(value: "\(store.profile.totalClasses)", label: "Total Classes")
                ProfileStatCell(value: "\(store.profile.longestStreak)", label: "Longest Streak")
                ProfileStatCell(value: "\(store.profile.mostClassesInMonth)", label: "Best Month")
                ProfileStatCell(value: "\(store.badges.filter { $0.isUnlocked }.count)", label: "Badges Earned")
            }
        }
        .padding(20)
        .softCard()
        .opacity(appeared ? 1 : 0)
    }

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Settings")
                .font(.headline.weight(.bold))
                .foregroundStyle(Theme.cream)

            VStack(spacing: 0) {
                SettingsToggleRow(title: "Streak Reminders", isOn: $store.profile.streakReminders)
                dividerLine
                SettingsToggleRow(title: "Milestone Notifications", isOn: $store.profile.milestoneNotifications)
                dividerLine
                SettingsToggleRow(title: "Challenge Updates", isOn: $store.profile.challengeUpdates)
                dividerLine
                SettingsToggleRow(title: "Class Reminders", isOn: $store.profile.classReminders)
                dividerLine
                SettingsToggleRow(title: "Hide from Leaderboard", isOn: $store.profile.hideFromLeaderboard)
                dividerLine
                SettingsToggleRow(title: "Hide Check-ins", isOn: $store.profile.hideCheckIns)
            }
        }
        .padding(20)
        .softCard()
        .opacity(appeared ? 1 : 0)
    }

    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Appearance")
                .font(.headline.weight(.bold))
                .foregroundStyle(Theme.cream)

            HStack(spacing: 8) {
                ForEach(AppearanceMode.allCases, id: \.rawValue) { mode in
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            appearanceMode = mode
                            UserDefaults.standard.set(mode.rawValue, forKey: "appearanceMode")
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: mode.icon)
                                .font(.subheadline)
                            Text(mode.label)
                                .font(.subheadline.weight(.medium))
                        }
                        .foregroundStyle(appearanceMode == mode ? Theme.buttonForeground : Theme.cream)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(appearanceMode == mode ? Theme.buttonBackground : Theme.neutralFill)
                        .clipShape(.rect(cornerRadius: 14, style: .continuous))
                    }
                    .sensoryFeedback(.selection, trigger: appearanceMode)
                }
            }
        }
        .padding(20)
        .softCard()
        .opacity(appeared ? 1 : 0)
    }

    private var dividerLine: some View {
        Rectangle()
            .fill(Theme.subtleDivider)
            .frame(height: 0.5)
    }

    private var mindbodyConnectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Mindbody Sync")
                .font(.headline.weight(.bold))
                .foregroundStyle(Theme.cream)

            if store.showConnectionSuccess {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(Theme.success)
                        .symbolEffect(.bounce, value: store.showConnectionSuccess)
                    Text("Connected!")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(Theme.cream)
                    Text("Your Mindbody account is synced.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.creamSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .transition(.scale.combined(with: .opacity))
            } else {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: store.isMindbodyConnected ? "checkmark.circle.fill" : "link.badge.plus")
                        .font(.title3)
                        .foregroundStyle(store.isMindbodyConnected ? Theme.success : Theme.cream)
                        .frame(width: 38, height: 38)
                        .background(Theme.neutralFill)
                        .clipShape(.rect(cornerRadius: 12))

                    VStack(alignment: .leading, spacing: 6) {
                        Text(store.isMindbodyConnected ? "Account connected" : "Mindbody not connected")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(Theme.cream)

                        Text(store.mindbodyConnectionMessage)
                            .font(.subheadline)
                            .foregroundStyle(Theme.creamSecondary)

                        if let lastMindbodySync = store.lastMindbodySync {
                            Text("Last synced \(lastMindbodySync.formatted(.dateTime.month().day().hour().minute()))")
                                .font(.caption)
                                .foregroundStyle(Theme.creamTertiary)
                        }

                        if let error = store.mindbodyConnectionError {
                            HStack(spacing: 6) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.caption)
                                Text(error)
                                    .font(.caption)
                            }
                            .foregroundStyle(Theme.danger)
                        }
                    }

                    Spacer(minLength: 0)
                }

                HStack(spacing: 12) {
                    Button {
                        Task {
                            if store.isMindbodyConnected {
                                await store.syncMindbody()
                            } else {
                                await store.connectMindbody()
                            }
                        }
                    } label: {
                        HStack(spacing: 8) {
                            if store.mindbodyConnectionState == .connecting || store.isSyncing {
                                ProgressView()
                                    .tint(Theme.buttonForeground)
                            }
                            Text(buttonLabel)
                                .font(.headline)
                        }
                        .foregroundStyle(Theme.buttonForeground)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Theme.buttonBackground)
                        .clipShape(.rect(cornerRadius: 14))
                    }
                    .disabled(store.mindbodyConnectionState == .connecting || store.isSyncing)

                    if store.isMindbodyConnected {
                        Button {
                            showingDisconnectConfirmation = true
                        } label: {
                            Image(systemName: "link.badge.minus")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(Theme.danger)
                                .frame(width: 50, height: 50)
                                .background(Theme.danger.opacity(0.12))
                                .clipShape(.rect(cornerRadius: 14))
                        }
                    }
                }

                if !store.isMindbodyConnected {
                    HStack(spacing: 6) {
                        Image(systemName: "lock.shield.fill")
                            .font(.caption2)
                        Text("You'll sign in securely via Mindbody")
                            .font(.caption)
                    }
                    .foregroundStyle(Theme.creamTertiary)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Theme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(store.showConnectionSuccess ? Theme.success.opacity(0.4) : Theme.cardBorder, lineWidth: 1)
                )
                .shadow(color: Theme.cardShadow, radius: 14, x: 0, y: 6)
        )
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: store.showConnectionSuccess)
        .opacity(appeared ? 1 : 0)
    }

    private var buttonLabel: String {
        if store.mindbodyConnectionState == .connecting {
            return "Opening Mindbody\u{2026}"
        } else if store.isSyncing {
            return "Syncing\u{2026}"
        } else if store.isMindbodyConnected {
            return "Refresh Sync"
        } else {
            return "Connect Account"
        }
    }

    private var mindbodyLink: some View {
        Button {
            store.openMindbody()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "link")
                    .font(.body.weight(.medium))
                Text("Manage Membership on Mindbody")
                    .font(.subheadline.weight(.medium))
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.caption)
            }
            .foregroundStyle(Theme.creamSecondary)
            .padding(16)
            .softCard(cornerRadius: 18)
        }
        .opacity(appeared ? 1 : 0)
    }
}

struct ProfileStatCell: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(.title2, weight: .bold))
                .foregroundStyle(Theme.cream)
            Text(label)
                .font(.caption2.weight(.medium))
                .foregroundStyle(Theme.creamSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Theme.neutralFill)
        .clipShape(.rect(cornerRadius: 16, style: .continuous))
    }
}

struct SettingsToggleRow: View {
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            Text(title)
                .font(.body)
                .foregroundStyle(Theme.cream)
        }
        .tint(Theme.accent)
        .padding(.vertical, 8)
    }
}
