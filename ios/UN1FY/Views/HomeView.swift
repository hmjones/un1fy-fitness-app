import SwiftUI

struct HomeView: View {
    let store: MemberStore
    @State private var appeared: Bool = false
    var onOpenCommunity: () -> Void = {}

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                greetingSection
                if store.isMindbodyConnected {
                    if let issue = store.dataIssue {
                        dataIssueBanner(issue)
                    }
                    UpcomingClassCard(store: store)
                    WeeklyAttendanceView(store: store)
                    if store.upcomingClass != nil { bookClassButton }
                } else {
                    mindbodyConnectionCard
                }
                communitySection
            }
            .padding(.horizontal, 22)
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
        .background(Theme.background.ignoresSafeArea())
        .refreshable {
            await store.refreshData()
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                appeared = true
            }
        }
    }

    private var communitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Better together.").font(.title3.weight(.bold))
                Spacer()
                Button(action: onOpenCommunity) {
                    Label("Community", systemImage: "arrow.right").font(.caption.weight(.semibold))
                }
                .frame(minHeight: 44)
                .accessibilityIdentifier("home.community")
            }
            .foregroundStyle(Theme.cream)
            CommunityFeedSection(store: store, previewLimit: 1)
        }
    }

    private func dataIssueBanner(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.subheadline)
                .foregroundStyle(Theme.danger)
            VStack(alignment: .leading, spacing: 4) {
                Text("Some stats may be out of date")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.cream)
                Text(message)
                    .font(.caption)
                    .foregroundStyle(Theme.creamSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Theme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Theme.danger.opacity(0.35), lineWidth: 1)
                )
                .shadow(color: Theme.cardShadow, radius: 14, x: 0, y: 6)
        )
        .transition(.scale(scale: 0.97).combined(with: .opacity))
        .opacity(appeared ? 1 : 0)
    }

    private var greetingSection: some View {
        PageIntroduction(
            eyebrow: Date().formatted(.dateTime.weekday(.wide).month(.wide).day()),
            title: "Your next strong day.",
            subtitle: store.profile.firstName.isEmpty ? "Let’s make time for you." : "Hey, \(store.profile.firstName). Let’s make time for you."
        )
    }

    private var mindbodyConnectionCard: some View {
        VStack(alignment: .leading, spacing: 16) {
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
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("MINDBODY")
                            .font(.caption.weight(.bold))
                            .tracking(1.5)
                            .foregroundStyle(Theme.creamTertiary)

                        Text("Connect Your Account")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(Theme.cream)

                        Text(store.mindbodyConnectionMessage)
                            .font(.subheadline)
                            .foregroundStyle(Theme.creamSecondary)
                    }

                    Spacer()

                    Image(systemName: "link.badge.plus")
                        .font(.title2)
                        .foregroundStyle(Theme.cream)
                }
                .transition(.scale.combined(with: .opacity))

                if let error = store.mindbodyConnectionError {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.footnote)
                        Text(error)
                            .font(.footnote)
                    }
                    .foregroundStyle(Theme.danger)
                }

                Button {
                    Task {
                        await store.connectMindbody()
                    }
                } label: {
                    HStack(spacing: 10) {
                        if store.mindbodyConnectionState == .connecting {
                            ProgressView()
                                .tint(Theme.buttonForeground)
                        } else {
                            Image(systemName: "link")
                                .font(.body.weight(.semibold))
                        }

                        Text(store.mindbodyConnectionState == .connecting ? "Opening Mindbody…" : "Connect Mindbody")
                            .font(.headline)
                    }
                    .foregroundStyle(Theme.buttonForeground)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Theme.buttonBackground)
                    .clipShape(.rect(cornerRadius: 14))
                }
                .disabled(store.mindbodyConnectionState == .connecting)

                HStack(spacing: 6) {
                    Image(systemName: "lock.shield.fill")
                        .font(.caption2)
                    Text("You'll sign in securely via Mindbody")
                        .font(.caption)
                }
                .foregroundStyle(Theme.creamTertiary)
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
        .offset(y: appeared ? 0 : 12)
    }

    private var bookClassButton: some View {
        Button {
            store.openMindbody()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                Text("Book a Class")
                    .font(.headline)
            }
            .foregroundStyle(Theme.buttonForeground)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Theme.buttonBackground)
            .clipShape(.rect(cornerRadius: 18, style: .continuous))
        }
        .sensoryFeedback(.impact(weight: .medium), trigger: false)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 15)
    }

}
