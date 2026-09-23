import SwiftUI
import UserNotifications

struct OnboardingView: View {
    let store: MemberStore
    let onComplete: () -> Void

    @State private var currentStep: Int = 0
    @State private var appeared: Bool = false
    @State private var mindbodyConnected: Bool = false
    @State private var editedFirstName: String = ""
    @State private var celebrationAppeared: Bool = false
    @State private var badgeRevealed: Bool = false
    @State private var sparklePhase: Int = 0
    @State private var showWhyInfo: Bool = false
    @State private var isConnecting: Bool = false
    @State private var connectionError: String?

    private let totalSteps: Int = 5

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                if currentStep > 0 && currentStep < 4 {
                    progressDots
                        .padding(.top, 16)
                }

                Spacer(minLength: 0)

                Group {
                    switch currentStep {
                    case 0: welcomeScreen
                    case 1: connectMindbodyScreen
                    case 2: notificationsScreen
                    case 3: personalizationScreen
                    case 4: celebrationScreen
                    default: EmptyView()
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))

                Spacer(minLength: 0)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.85)) {
                appeared = true
            }
        }
    }

    private var progressDots: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalSteps, id: \.self) { index in
                Capsule()
                    .fill(index <= currentStep ? Theme.cream : Theme.creamTertiary)
                    .frame(width: index == currentStep ? 24 : 8, height: 8)
                    .animation(.spring(response: 0.4), value: currentStep)
            }
        }
    }

    private var welcomeScreen: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 20) {
                Image("UN1FYLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 260)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)

                Rectangle()
                    .fill(Theme.accent)
                    .frame(width: 40, height: 3)
                    .opacity(appeared ? 1 : 0)

                Text("Track your progress.\nEarn achievements.\nStay motivated.")
                    .font(.title3.weight(.medium))
                    .foregroundStyle(Theme.creamSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 12)
                    .animation(.spring(response: 0.8).delay(0.2), value: appeared)
            }

            Spacer()

            Button {
                advanceStep()
            } label: {
                Text("Get Started")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Theme.buttonForeground)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Theme.buttonBackground)
                    .clipShape(.rect(cornerRadius: 16))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)
            .animation(.spring(response: 0.8).delay(0.4), value: appeared)
        }
    }

    private var connectMindbodyScreen: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(Theme.accent.opacity(0.08))
                        .frame(width: 100, height: 100)

                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 40, weight: .medium))
                        .foregroundStyle(Theme.cream)
                }

                VStack(spacing: 12) {
                    Text("Let's sync your classes")
                        .font(.title.weight(.bold))
                        .foregroundStyle(Theme.cream)

                    Text("Connect your Mindbody account to automatically track your attendance, streaks, and stats.")
                        .font(.body)
                        .foregroundStyle(Theme.creamSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                .padding(.horizontal, 8)
            }
            .padding(.horizontal, 24)

            Spacer()

            VStack(spacing: 16) {
                if let error = connectionError {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.footnote)
                        Text(error)
                            .font(.footnote)
                    }
                    .foregroundStyle(Theme.danger)
                    .padding(.horizontal, 24)
                }

                if mindbodyConnected {
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(Theme.success)
                        Text("Connected!")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(Theme.cream)
                    }
                    .transition(.scale.combined(with: .opacity))

                    Button {
                        advanceStep()
                    } label: {
                        Text("Continue")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(Theme.background)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Theme.cream)
                            .clipShape(.rect(cornerRadius: 16))
                    }
                    .padding(.horizontal, 24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                } else {
                    Button {
                        Task {
                            await connectMindbody()
                        }
                    } label: {
                        HStack(spacing: 10) {
                            if isConnecting {
                                ProgressView()
                                    .tint(Theme.buttonForeground)
                            } else {
                                Image(systemName: "link")
                                    .font(.body.weight(.semibold))
                            }
                            Text(isConnecting ? "Connecting…" : "Connect with Mindbody")
                                .font(.headline.weight(.bold))
                        }
                        .foregroundStyle(Theme.background)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Theme.cream)
                        .clipShape(.rect(cornerRadius: 16))
                    }
                    .disabled(isConnecting)
                    .padding(.horizontal, 24)
                }

                Button {
                    withAnimation(.spring(response: 0.3)) {
                        showWhyInfo.toggle()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: showWhyInfo ? "chevron.up" : "questionmark.circle")
                            .font(.caption)
                        Text("Why do we need this?")
                            .font(.caption)
                    }
                    .foregroundStyle(Theme.creamTertiary)
                }

                if showWhyInfo {
                    Text("UN1FY uses your Mindbody class data to calculate streaks, unlock badges, and track your fitness journey. We never modify your bookings or share your data.")
                        .font(.caption)
                        .foregroundStyle(Theme.creamSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .animation(.spring(response: 0.4), value: mindbodyConnected)
            .padding(.bottom, 40)
        }
    }

    private var notificationsScreen: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(Theme.cream.opacity(0.08))
                        .frame(width: 100, height: 100)

                    Image(systemName: "bell.badge.fill")
                        .font(.system(size: 40, weight: .medium))
                        .foregroundStyle(Theme.cream)
                        .symbolEffect(.bounce, value: currentStep == 2)
                }

                VStack(spacing: 12) {
                    Text("Stay on track")
                        .font(.title.weight(.bold))
                        .foregroundStyle(Theme.cream)

                    Text("Get streak reminders and milestone celebrations so you never miss a beat.")
                        .font(.body)
                        .foregroundStyle(Theme.creamSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                .padding(.horizontal, 8)
            }
            .padding(.horizontal, 24)

            Spacer()

            VStack(spacing: 12) {
                Button {
                    requestNotifications()
                } label: {
                    Text("Enable Notifications")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(Theme.background)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Theme.cream)
                        .clipShape(.rect(cornerRadius: 16))
                }

                Button {
                    advanceStep()
                } label: {
                    Text("Maybe Later")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Theme.creamTertiary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }

    private var personalizationScreen: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 32) {
                ZStack {
                    Circle()
                        .fill(Theme.cardBackground)
                        .frame(width: 120, height: 120)
                        .overlay(
                            Circle()
                                .stroke(Theme.cardBorder, lineWidth: 1)
                        )

                    Image(systemName: "person.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(Theme.creamTertiary)

                    Circle()
                        .fill(Theme.cream)
                        .frame(width: 36, height: 36)
                        .overlay(
                            Image(systemName: "camera.fill")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Theme.background)
                        )
                        .offset(x: 42, y: 42)
                }

                VStack(spacing: 8) {
                    Text(store.profile.firstName.isEmpty ? "What's your name?" : "Confirm your name")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Theme.cream)

                    Text(store.profile.firstName.isEmpty ? "Enter your first name to personalize your experience." : "We pulled this from Mindbody — feel free to change it.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.creamSecondary)
                        .multilineTextAlignment(.center)
                }

                TextField("Enter your first name", text: $editedFirstName)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Theme.cream)
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 16)
                    .padding(.horizontal, 24)
                    .background(Theme.cardBackground)
                    .clipShape(.rect(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Theme.cardBorder, lineWidth: 1)
                    )
                    .padding(.horizontal, 40)
            }
            .padding(.horizontal, 24)

            Spacer()

            Button {
                if !editedFirstName.trimmingCharacters(in: .whitespaces).isEmpty {
                    store.profile.firstName = editedFirstName.trimmingCharacters(in: .whitespaces)
                }
                advanceStep()
            } label: {
                Text("Continue")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Theme.buttonForeground)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Theme.buttonBackground)
                    .clipShape(.rect(cornerRadius: 16))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .onAppear {
            editedFirstName = store.profile.firstName
        }
    }

    private var celebrationScreen: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 28) {
                ZStack {
                    ForEach(0..<8, id: \.self) { i in
                        Image(systemName: "sparkle")
                            .font(.system(size: CGFloat.random(in: 10...18)))
                            .foregroundStyle(Theme.flame)
                            .offset(
                                x: CGFloat.random(in: -80...80),
                                y: CGFloat.random(in: -80...80)
                            )
                            .opacity(celebrationAppeared ? 1 : 0)
                            .scaleEffect(celebrationAppeared ? 1 : 0.3)
                            .animation(
                                .spring(response: 0.6, dampingFraction: 0.5)
                                    .delay(Double(i) * 0.08 + 0.3),
                                value: celebrationAppeared
                            )
                    }

                    ZStack {
                        Circle()
                            .fill(Theme.flame.opacity(0.15))
                            .frame(width: 120, height: 120)
                            .scaleEffect(badgeRevealed ? 1 : 0.5)
                            .opacity(badgeRevealed ? 1 : 0)

                        Image(systemName: "star.fill")
                            .font(.system(size: 52))
                            .foregroundStyle(Theme.flame)
                            .scaleEffect(badgeRevealed ? 1 : 0)
                            .rotationEffect(.degrees(badgeRevealed ? 0 : -30))
                    }
                    .animation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.1), value: badgeRevealed)
                }
                .frame(height: 180)

                VStack(spacing: 12) {
                    Text("Welcome to the crew,")
                        .font(.title2.weight(.medium))
                        .foregroundStyle(Theme.creamSecondary)
                        .opacity(celebrationAppeared ? 1 : 0)
                        .animation(.easeOut(duration: 0.4).delay(0.5), value: celebrationAppeared)

                    Text(store.profile.firstName.isEmpty ? "You." : "\(store.profile.firstName).")
                        .font(.system(size: 36, weight: .black))
                        .foregroundStyle(Theme.cream)
                        .opacity(celebrationAppeared ? 1 : 0)
                        .animation(.easeOut(duration: 0.4).delay(0.7), value: celebrationAppeared)
                }

                VStack(spacing: 8) {
                    Text("BADGE UNLOCKED")
                        .font(.caption.weight(.bold))
                        .tracking(2)
                        .foregroundStyle(Theme.flame)

                    Text("Early Adopter")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(Theme.cream)

                    Text("One of the first to join UN1FY.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.creamSecondary)
                }
                .padding(.vertical, 20)
                .padding(.horizontal, 24)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Theme.cardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Theme.flame.opacity(0.3), lineWidth: 1)
                        )
                )
                .scaleEffect(celebrationAppeared ? 1 : 0.8)
                .opacity(celebrationAppeared ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.9), value: celebrationAppeared)
            }
            .padding(.horizontal, 24)

            Spacer()

            Button {
                onComplete()
            } label: {
                Text("Let's Go")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Theme.buttonForeground)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Theme.buttonBackground)
                    .clipShape(.rect(cornerRadius: 16))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
            .opacity(celebrationAppeared ? 1 : 0)
            .animation(.easeOut(duration: 0.4).delay(1.2), value: celebrationAppeared)
        }
        .onAppear {
            withAnimation {
                celebrationAppeared = true
                badgeRevealed = true
            }
        }
    }

    // MARK: - Actions

    private func advanceStep() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
            currentStep += 1
        }
    }

    private func connectMindbody() async {
        isConnecting = true
        connectionError = nil

        do {
            let response = try await MindbodyService().connect()

            print("[UN1FY] Exchange response member: \(String(describing: response.member))")
            print("[UN1FY] Member firstName=\(response.member?.firstName ?? "nil") lastName=\(response.member?.lastName ?? "nil")")
            if let firstName = response.member?.firstName, !firstName.isEmpty {
                store.profile.firstName = firstName
                print("[UN1FY] Set profile.firstName to: \(firstName)")
            } else {
                print("[UN1FY] WARNING: No firstName in response, profile.firstName remains: \(store.profile.firstName)")
            }
            if let lastName = response.member?.lastName, !lastName.isEmpty {
                store.profile.lastName = lastName
                print("[UN1FY] Set profile.lastName to: \(lastName)")
            } else {
                print("[UN1FY] WARNING: No lastName in response, profile.lastName remains: \(store.profile.lastName)")
            }

            if let accessToken = response.accessToken, !accessToken.isEmpty {
                KeychainService.accessToken = accessToken
            }
            if let refreshToken = response.refreshToken, !refreshToken.isEmpty {
                KeychainService.refreshToken = refreshToken
            }
            KeychainService.isConnected = true
            KeychainService.lastSyncDate = Date()

            store.mindbodyConnectionState = .connected
            store.mindbodyConnectionMessage = response.message ?? "Connected. Your UN1FY account is synced with Mindbody."
            store.lastMindbodySync = Date()

            if let history = response.attendanceHistory, !history.isEmpty {
                store.attendanceHistory = history
            }
            if let nextClass = response.nextClass {
                store.upcomingClass = nextClass
            }

            await store.refreshPersonalStatsFromLeaderboard()

            withAnimation(.spring(response: 0.4)) {
                mindbodyConnected = true
            }
        } catch {
            print("[UN1FY] Onboarding connectMindbody error: \(error)")
            let nsError = error as NSError
            if nsError.domain == "com.apple.AuthenticationServices.WebAuthenticationSession",
               nsError.code == 1 {
                connectionError = nil
            } else if let urlError = error as? URLError {
                switch urlError.code {
                case .notConnectedToInternet, .networkConnectionLost:
                    connectionError = "No internet connection. Please try again."
                case .timedOut:
                    connectionError = "Connection timed out. Please try again."
                case .cancelled:
                    connectionError = nil
                default:
                    connectionError = "Something went wrong. Please try again."
                }
            } else {
                connectionError = "Something went wrong. Please try again."
            }
        }

        isConnecting = false
    }

    private func requestNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in
            DispatchQueue.main.async {
                advanceStep()
            }
        }
    }
}
