import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import UserNotifications

struct SectionCard<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.07), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.3), radius: 6, x: 0, y: 4)
    }
}

struct SettingsView: View {
    @Binding var isUserLoggedIn: Bool
    @AppStorage("expiringTasks") private var expiringTasks = true
    @AppStorage("newTasks") private var newTasks = true
    @AppStorage("sleepTime") private var sleepTime = true
    @AppStorage("animationsEnabled") private var animationsEnabled = true
    @State private var userEmail = ""
    @State private var name = ""
    @State private var showLogoutConfirmation = false
    @State private var showDeleteConfirmation = false
    @State private var preferencesLoaded = false
    @State private var showGoogleSignInAlert = false
    @State private var navigateToChangePassword = false
    @State private var isLoading = true
    @State private var showPaywall = false
    @State private var expiringTasksTime = "18:00"
    @State private var extraReminders: [Reminder] = []
@State private var showReminderEditor = false
    @State private var exportURL: URL?
    @State private var showExportShare = false
    @State private var exportError: String?
    @State private var isExporting = false
    @State private var exportMessage: String?
    @Environment(ProStore.self) private var proStore
    
    private var versionInfo: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        return "v\(version)"
    }

#if DEBUG
    private var currentProOverrideLabel: String {
        ProDebugOverride.current?.label ?? "Off"
    }
#endif
    
    let gradient = LinearGradient.brand

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 24) {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                            .padding(.top, 40)
                    } else {
                        // ARISE PRO
                        sectionBlock("ARISE PRO") {
                            Button {
                                showPaywall = true
                            } label: {
                                HStack(spacing: 12) {
                                    plainIcon(systemImage: "crown.fill")
                                    Text("Arise Pro").foregroundColor(.white)
                                    Spacer()
                                    Text(proStore.isPro ? "Active" : "Learn More")
                                        .font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.4))
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(.white.opacity(0.2))
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 13)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Arise Pro")
                            .accessibilityHint(proStore.isPro ? "You own Arise Pro" : "Opens the Arise Pro upgrade")
                        }

                        // ACCOUNT
                        sectionBlock("ACCOUNT") {
                            inputRow(systemImage: "person", label: "Name", binding: $name, isEditable: true) {
                                saveNameToFirestore(name)
                            }
                            .accessibilityLabel("Name")
                            dividerLine()
                            inputRow(systemImage: "envelope",
                                     label: "Email",
                                     binding: .constant(userEmail.isEmpty ? "No email set" : userEmail),
                                     isEditable: false)
                            dividerLine()
                            userIDRow
                            dividerLine()
                            navRow(systemImage: "slider.horizontal.3", label: "Preferences") { ManagePreferencesView() }
                            dividerLine()
                            buttonRow(systemImage: "lock.rotation", label: "Change Password") {
                                if let provider = Auth.auth().currentUser?.providerData.first?.providerID,
                                   provider == "password" {
                                    navigateToChangePassword = true
                                } else {
                                    showGoogleSignInAlert = true
                                }
                            }
                            .accessibilityLabel("Change password")
                            .alert(isPresented: $showGoogleSignInAlert) {
                                Alert(
                                    title: Text("Cannot Change Password"),
                                    message: Text("This account uses Apple or Google sign-in. To change your password, update it from your Apple ID or Google Account settings."),
                                    dismissButton: .default(Text("OK"))
                                )
                            }
                            dividerLine()
                            navRow(systemImage: "trash", label: "Delete Account") {
                                DeleteAccountView(isUserLoggedIn: $isUserLoggedIn)
                            }
                            .accessibilityLabel("Delete account")
                        }

                        // NOTIFICATIONS
                        sectionBlock("NOTIFICATIONS") {
                            notificationsContent()
                        }

                        // DATA
                        sectionBlock("DATA") {
                            if proStore.isPro {
                                Button {
                                    performExport()
                                } label: {
                                    HStack(spacing: 12) {
                                        plainIcon(systemImage: "square.and.arrow.up")
                                        Text("Export My Data").foregroundColor(.white)
                                        Spacer()
                                        if isExporting {
                                            ProgressView()
                                                .tint(.white.opacity(0.7))
                                        } else {
                                            Image(systemName: "chevron.right")
                                                .font(.system(size: 13, weight: .semibold))
                                                .foregroundColor(.white.opacity(0.2))
                                        }
                                    }
                                    .padding(.horizontal)
                                    .padding(.vertical, 13)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .disabled(isExporting)
                                .accessibilityLabel("Export My Data")
                                .accessibilityHint("Downloads your Arise history as a JSON file")
                            } else {
                                LockedFeatureRow(
                                    icon: "square.and.arrow.up",
                                    title: "Export My Data",
                                    subtitle: "Download your history as JSON"
                                )
                            }
                        }

                        // APPEARANCE
                        sectionBlock("APPEARANCE") {
                            staticRow(systemImage: "circle.lefthalf.filled", label: "Mode", value: "Dark")
                            dividerLine()
                            Toggle(isOn: $animationsEnabled) {
                                HStack(spacing: 12) {
                                    plainIcon(systemImage: "circle.dotted.and.circle")
                                    Text("Animations").foregroundColor(.white)
                                }
                            }
                            .tint(Color(red: 84/255, green: 0/255, blue: 232/255))
                            .accessibilityLabel("Enable Animations")
                            .accessibilityHint("Double tap to toggle")
                            .padding(.horizontal)
                            .padding(.vertical, 13)
                            .onChange(of: animationsEnabled) { _, newValue in
                                guard preferencesLoaded else { return }
                                PreferenceManager.saveTopLevelPreference(key: "animationsEnabled", value: newValue)
                            }
                        }

                        // APP
                        sectionBlock("APP") {
                            appRow(systemImage: "questionmark.circle", label: "Help Center") { HelpCenterView() }
                            dividerLine()
                            appRow(systemImage: "doc.text", label: "Terms of Use") { TermsOfUseView() }
                            dividerLine()
                            buttonRow(systemImage: "lock.shield", label: "Privacy Policy") {
                                if let url = URL(string: "https://ranaveery.github.io/Arise/") {
                                    UIApplication.shared.open(url)
                                }
                            }
                            dividerLine()
                            staticRow(systemImage: "info.circle", label: "Version", value: versionInfo)
                            .accessibilityLabel("Version \(versionInfo)")
                        }

#if DEBUG
                        // DEBUG — PRO OVERRIDE (never compiled into Release)
                        sectionBlock("DEBUG — PRO OVERRIDE") {
                            HStack(spacing: 12) {
                                plainIcon(systemImage: "wrench.and.screwdriver")
                                Text("Pro Status").foregroundColor(.white)
                                Spacer()
                                Menu {
                                    Button("Off (use real entitlements)") {
                                        proStore.setDebugOverride(nil)
                                    }
                                    ForEach(ProDebugOverride.allCases, id: \.self) { override in
                                        Button(override.label) {
                                            proStore.setDebugOverride(override)
                                        }
                                    }
                                } label: {
                                    HStack(spacing: 4) {
                                        Text(currentProOverrideLabel)
                                            .font(.system(size: 14))
                                            .foregroundColor(.white.opacity(0.5))
                                        Image(systemName: "chevron.up.chevron.down")
                                            .font(.system(size: 10))
                                            .foregroundColor(.white.opacity(0.3))
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 13)
                        }
#endif

                        // LOG OUT
                        Button(action: { showLogoutConfirmation = true }) {
                            Text("Log Out")
                                .fontWeight(.semibold)
                                .font(.system(size: 15, design: .rounded))
                                .foregroundColor(.white.opacity(0.7))
                                .padding(.horizontal, 24)
                                .padding(.vertical, 11)
                                .background(
                                    Capsule()
                                        .fill(Color.white.opacity(0.07))
                                        .overlay(
                                            Capsule()
                                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                        )
                                )
                        }
                        .accessibilityLabel("Log out")
                        .accessibilityHint("Signs you out of your account")
                        .alert(isPresented: $showLogoutConfirmation) {
                            Alert(
                                title: Text("Are you sure?"),
                                message: Text("Do you really want to log out?"),
                                primaryButton: .destructive(Text("Log Out")) {
                                    do {
                                        let defaults = UserDefaults.standard
                                        defaults.removeObject(forKey: "cachedUserData")
                                        defaults.removeObject(forKey: "unlockedAchievementIndices")
                                        defaults.removeObject(forKey: "lastResetDate")
                                        defaults.removeObject(forKey: "lastRankId")
                                        try Auth.auth().signOut()
                                        isUserLoggedIn = false
                                    } catch { }
                                },
                                secondaryButton: .cancel()
                            )
                        }
                        .padding(.bottom, 100)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }
            .background(Color.black.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $navigateToChangePassword) {
                ChangePasswordView()
            }
            .onReceive(NotificationCenter.default.publisher(for: .ariseRescheduleNotifications)) { _ in
                fetchUserTimesAndReschedule()
            }
            .onAppear {
                if let cached = UserDefaults.standard.dictionary(forKey: "cachedUserData") {
                    self.name = cached["name"] as? String ?? ""
                    self.userEmail = cached["email"] as? String ?? ""
                }
                loadUserDataAndPreferences()
                requestNotificationAuthorizationIfNeeded()
                fetchUserTimesAndReschedule()
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .sheet(isPresented: $showReminderEditor) {
            ReminderEditorView(
                reminders: extraReminders,
                expiringTasksTime: expiringTasksTime,
                onSave: { newReminders, newTime in
                    expiringTasksTime = newTime
                    extraReminders = newReminders
                    persistReminderSettings()
                }
            )
        }
        .sheet(isPresented: $showExportShare) {
            if let exportURL {
                ShareSheet(items: [exportURL])
            }
        }
        .alert("Export failed", isPresented: Binding(
            get: { exportError != nil },
            set: { if !$0 { exportError = nil } }
        )) {
            Button("OK", role: .cancel) { exportError = nil }
        } message: {
            Text(exportError ?? "")
        }
    }

    private func performExport() {
        guard let uid = Auth.auth().currentUser?.uid else {
            exportError = DataExporter.ExportError.noUser.localizedDescription
            return
        }
        isExporting = true
        Task {
            do {
                let data = try await DataExporter.exportData(uid: uid)
                let url = try DataExporter.writeTemporaryFile(data: data, uid: uid)
                await MainActor.run {
                    isExporting = false
                    exportURL = url
                    showExportShare = true
                }
            } catch {
                await MainActor.run {
                    isExporting = false
                    exportError = error.localizedDescription
                }
            }
        }
    }

    private func persistReminderSettings() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let payload: [String: Any] = [
            "notifications": [
                "expiringTasksTime": expiringTasksTime,
                "extraReminders": extraReminders.map { $0.toDict() }
            ]
        ]
        Firestore.firestore().collection("users").document(uid).setData(payload, merge: true) { _ in
            NotificationCenter.default.post(name: .ariseRescheduleNotifications, object: nil)
        }
    }




    // MARK: - Profile Card
    // MARK: - SECTION BLOCK (title + card grouped)
    private func sectionBlock<Content: View>(_ title: String,
                                             @ViewBuilder content: @escaping () -> Content) -> some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(gradient)
                .tracking(0.5)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 0)

            SectionCard {
                VStack(spacing: 0) {
                    content()
                }
            }
        }
    }

    // MARK: - Notifications content (content-only, wrapped by sectionBlock)
    @ViewBuilder
    private func notificationsContent() -> some View {
        Toggle(isOn: $expiringTasks) {
            HStack(spacing: 12) {
                plainIcon(systemImage: "clock.badge.exclamationmark")
                Text("Expiring Tasks").foregroundColor(.white)
            }
        }
        .tint(Color(red: 84/255, green: 0/255, blue: 232/255))
        .accessibilityLabel("Enable Expiring Tasks notifications")
        .accessibilityHint("Double tap to toggle")
        .padding(.horizontal)
        .padding(.vertical, 13)
        .onChange(of: expiringTasks) { _, newValue in
            guard preferencesLoaded else { return }
            PreferenceManager.savePreference(key: "expiringTasks", value: newValue)
            fetchUserTimesAndReschedule()
        }

        dividerLine()

        Toggle(isOn: $newTasks) {
            HStack(spacing: 12) {
                plainIcon(systemImage: "plus.square.on.square")
                Text("New Tasks").foregroundColor(.white)
            }
        }
        .tint(Color(red: 84/255, green: 0/255, blue: 232/255))
        .accessibilityLabel("Enable New Tasks notifications")
        .accessibilityHint("Double tap to toggle")
        .padding(.horizontal)
        .padding(.vertical, 13)
        .onChange(of: newTasks) { _, newValue in
            guard preferencesLoaded else { return }
            PreferenceManager.savePreference(key: "newTasks", value: newValue)
            fetchUserTimesAndReschedule()
        }

        dividerLine()

        Toggle(isOn: $sleepTime) {
            HStack(spacing: 12) {
                plainIcon(systemImage: "moon.fill")
                Text("Bedtime").foregroundColor(.white)
            }
        }
        .tint(Color(red: 84/255, green: 0/255, blue: 232/255))
        .accessibilityLabel("Enable Bedtime notifications")
        .accessibilityHint("Double tap to toggle")
        .padding(.horizontal)
        .padding(.vertical, 13)
        .onChange(of: sleepTime) { _, newValue in
            guard preferencesLoaded else { return }
            PreferenceManager.savePreference(key: "sleepTime", value: newValue)
            fetchUserTimesAndReschedule()
        }

        dividerLine()

        customRemindersContent()
    }

    // MARK: - Custom Reminders (Pro)

    @ViewBuilder
    private func customRemindersContent() -> some View {
        if proStore.isPro {
            Button {
                showReminderEditor = true
            } label: {
                HStack(spacing: 12) {
                    plainIcon(systemImage: "bell.badge")
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Custom Reminders").foregroundColor(.white)
                        Text(remindersSubtitle)
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.4))
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(0.2))
                }
                .padding(.horizontal)
                .padding(.vertical, 13)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Custom Reminders")
            .accessibilityHint("Opens custom reminder settings")
        } else {
            LockedFeatureRow(
                icon: "bell.badge",
                title: "Custom Reminders",
                subtitle: "Set your own reminder times"
            )
        }
    }

    private var remindersSubtitle: String {
        var parts: [String] = ["Expiring tasks at \(formattedReminderTime(expiringTasksTime))"]
        let count = extraReminders.filter { $0.enabled }.count
        if count > 0 {
            parts.append("\(count) extra reminder\(count == 1 ? "" : "s")")
        }
        return parts.joined(separator: " · ")
    }

    private func formattedReminderTime(_ hhmm: String) -> String {
        guard let date = dateFromTimeString(hhmm) else { return hhmm }
        let fmt = DateFormatter()
        fmt.timeStyle = .short
        return fmt.string(from: date)
    }

    // MARK: - Divider between rows (no gaps)
    private func dividerLine() -> some View {
        Divider()
            .background(Color.white.opacity(0.06))
            .padding(.leading, 45)
    }

    // MARK: - Reusable Rows
    private func plainIcon(systemImage: String) -> some View {
        Image(systemName: systemImage)
            .foregroundColor(.white.opacity(0.45))
            .frame(width: 20)
    }

    private var userIDRow: some View {
        Button {
            if let uid = Auth.auth().currentUser?.uid {
                UIPasteboard.general.string = uid
            }
        } label: {
            HStack(spacing: 12) {
                plainIcon(systemImage: "number")
                Text("User ID").foregroundColor(.white)
                Spacer()
                if let uid = Auth.auth().currentUser?.uid {
                    let short = uid.count > 12 ? String(uid.prefix(8)) + "…" + String(uid.suffix(4)) : uid
                    Text(short)
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundColor(.white.opacity(0.35))
                }
                Image(systemName: "doc.on.doc")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.35))
            }
            .padding(.horizontal)
            .padding(.vertical, 13)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Copy User ID")
    }

    private func staticRow(systemImage: String, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            plainIcon(systemImage: systemImage)
            Text(label).foregroundColor(.white)
            Spacer()
            Text(value).foregroundColor(.white.opacity(0.4))
                .font(.system(size: 14))
        }
        .padding(.horizontal)
        .padding(.vertical, 13)
    }

    private func navRow<Destination: View>(systemImage: String, label: String, destination: @escaping () -> Destination) -> some View {
        NavigationLink(destination: destination()) {
            HStack(spacing: 12) {
                plainIcon(systemImage: systemImage)
                Text(label).foregroundColor(.white)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white.opacity(0.2))
            }
            .padding(.horizontal)
            .padding(.vertical, 13)
        }
    }

    private func buttonRow(systemImage: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                plainIcon(systemImage: systemImage)
                Text(label).foregroundColor(.white)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white.opacity(0.2))
            }
            .padding(.horizontal)
            .padding(.vertical, 13)
        }
    }

    @ViewBuilder
    private func appRow<Destination: View>(systemImage: String, label: String, destination: @escaping () -> Destination) -> some View {
        navRow(systemImage: systemImage, label: label, destination: destination)
    }

    private func inputRow(
        systemImage: String,
        label: String,
        binding: Binding<String>,
        isEditable: Bool,
        onCommit: (() -> Void)? = nil
    ) -> some View {
        HStack(spacing: 12) {
            plainIcon(systemImage: systemImage)
            Text(label)
                .foregroundColor(.white)
            Spacer()
            if isEditable {
                EditableTextField(text: binding, onCommit: onCommit)
            } else {
                Text(binding.wrappedValue)
                    .foregroundColor(.white.opacity(0.4))
                    .font(.system(size: 14))
                    .multilineTextAlignment(.trailing)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 13)
    }


    // MARK: - Firestore helpers
    private func saveNameToFirestore(_ newName: String) {
        let cleanedName = sanitizeName(newName)
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        db.collection("users").document(uid).setData([
            "name": cleanedName
        ], merge: true) { error in
            if error == nil {
                var cached = UserDefaults.standard.dictionary(forKey: "cachedUserData") ?? [:]
                cached["name"] = cleanedName
                UserDefaults.standard.set(cached, forKey: "cachedUserData")
                self.name = cleanedName
            }
        }
    }

    private func loadUserDataAndPreferences() {
        guard let uid = Auth.auth().currentUser?.uid else {
            DispatchQueue.main.async { self.isLoading = false }
            return
        }
        let db = Firestore.firestore()
        db.collection("users").document(uid).getDocument { snapshot, error in
            guard let data = snapshot?.data(), error == nil else {
                DispatchQueue.main.async { self.isLoading = false }
                return
            }
            let fetchedName = sanitizeName(data["name"] as? String ?? "")
            let fetchedEmail = data["email"] as? String ?? ""
            UserDefaults.standard.set(["name": fetchedName, "email": fetchedEmail], forKey: "cachedUserData")

            let fetchedNotifications = data["notifications"] as? [String: Any] ?? [:]
            let fetchedAnimations = data["animationsEnabled"] as? Bool
            let fetchedReminders = Reminder.list(from: fetchedNotifications["extraReminders"])
            let fetchedExpiringTime = fetchedNotifications["expiringTasksTime"] as? String

            DispatchQueue.main.async {
                self.name = fetchedName
                self.userEmail = fetchedEmail
                self.isLoading = false
                self.preferencesLoaded = false
                self.expiringTasks = fetchedNotifications["expiringTasks"] as? Bool ?? self.expiringTasks
                self.newTasks = fetchedNotifications["newTasks"] as? Bool ?? self.newTasks
                self.sleepTime = fetchedNotifications["sleepTime"] as? Bool ?? self.sleepTime
                if let fetchedExpiringTime { self.expiringTasksTime = fetchedExpiringTime }
                self.extraReminders = fetchedReminders
                if let anim = fetchedAnimations { self.animationsEnabled = anim }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.preferencesLoaded = true
                }
            }
        }
    }

    struct PreferenceManager {
        static func savePreference(key: String, value: Bool) {
            guard let uid = Auth.auth().currentUser?.uid else { return }
            let db = Firestore.firestore()
            db.collection("users").document(uid).setData([
                "notifications": [key: value]
            ], merge: true)
        }
        
        static func saveTopLevelPreference(key: String, value: Bool) {
            guard let uid = Auth.auth().currentUser?.uid else { return }
            let db = Firestore.firestore()
            db.collection("users").document(uid).setData([
                key: value
            ], merge: true)
        }
    }
    
    struct EditableTextField: View {
        @Binding var text: String
        var onCommit: (() -> Void)?
        @FocusState private var isFocused: Bool

        var body: some View {
            TextField("", text: $text)
                .multilineTextAlignment(.trailing)
                .foregroundColor(isFocused ? .white : .gray)
                .frame(minWidth: 100)
                .focused($isFocused)
                .onChange(of: text) { _, newValue in
                    text = sanitizeName(newValue)
                }
                .onSubmit {
                    onCommit?()
                    isFocused = false
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
        }
    }
    
    // MARK: NOTIFICATION HELPERS

    private enum NotificationIDs {
        static let expiringTasks = "notif.expiringTasks"
        static let bedTime = "notif.bedTime"
        static let newTasks = "notif.newTasks"
        static let extraPrefix = "notif.extra."
    }

    private func fetchUserTimesAndReschedule() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        db.collection("users").document(uid).getDocument { snapshot, error in
            guard let data = snapshot?.data(), error == nil else {
                return
            }
            // schedule/cancel using that single snapshot
            scheduleExpiringTasksNotificationIfNeeded()  // independent of user times
            scheduleBedtimeNotificationIfNeeded(wakeOrBedData: data)
            scheduleNewTasksNotificationIfNeeded(userData: data)
            scheduleExtraReminders()
        }
    }

    private func requestNotificationAuthorizationIfNeeded() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            if settings.authorizationStatus != .authorized {
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
            }
        }
    }

    private func scheduleDailyNotification(id: String,
                                           title: String,
                                           body: String,
                                           hour: Int,
                                           minute: Int,
                                           weekdays: [Int]? = nil) {
        // build content
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        if let weekdays, !weekdays.isEmpty {
            // One repeating weekly trigger per weekday (a single DateComponents
            // can only match one weekday). Calendar weekday: 1=Sun ... 7=Sat.
            for weekday in weekdays {
                var comps = DateComponents()
                comps.weekday = weekday
                comps.hour = hour
                comps.minute = minute

                let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
                let request = UNNotificationRequest(identifier: "\(id).\(weekday)", content: content, trigger: trigger)
                UNUserNotificationCenter.current().add(request) { _ in }
            }
        } else {
            var comps = DateComponents()
            comps.hour = hour
            comps.minute = minute

            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
            let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request) { _ in }
        }
    }

    private func cancelNotification(id: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
        // Also drop the per-weekday copies (`<id>.<weekday>`) scheduled by
        // scheduleDailyNotification.
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let prefixed = requests.filter { $0.identifier.hasPrefix(id + ".") }.map { $0.identifier }
            if !prefixed.isEmpty {
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: prefixed)
            }
        }
    }

    private func timeFromMilitaryInt(_ intTime: Int) -> DateComponents {
        // e.g. 730 -> 07:30, 2130 -> 21:30
        let hour = intTime / 100
        let minute = intTime % 100
        return DateComponents(hour: hour, minute: minute)
    }

    private func scheduleExpiringTasksNotificationIfNeeded() {
        if expiringTasks {
            let components = timeComponents(from: expiringTasksTime) ?? (18, 0)
            scheduleDailyNotification(id: NotificationIDs.expiringTasks,
                                      title: "Expiring Tasks",
                                      body: "Reminder to get all your tasks done.",
                                      hour: components.0,
                                      minute: components.1)
        } else {
            cancelNotification(id: NotificationIDs.expiringTasks)
        }
    }

    // MARK: - Custom reminder scheduling (Pro)

    /// Schedules the Pro user's extra reminders and removes any stale ones.
    /// Free users have all extra reminders cancelled.
    private func scheduleExtraReminders() {
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { requests in
            let stale = requests
                .map(\.identifier)
                .filter { $0.hasPrefix(NotificationIDs.extraPrefix) }
            if !stale.isEmpty {
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: stale)
            }

            guard proStore.isPro else { return }

            for reminder in extraReminders where reminder.enabled {
                let id = "\(NotificationIDs.extraPrefix)\(reminder.id)"
                let weekdays = reminder.days.isEmpty
                    ? nil
                    : reminder.days.map { ($0 % 7) + 1 } // Mon=1...Sun=7 -> Calendar 1=Sun...7=Sat
                scheduleDailyNotification(id: id,
                                          title: "Arise",
                                          body: reminder.label,
                                          hour: reminder.hour,
                                          minute: reminder.minute,
                                          weekdays: weekdays)
            }
        }
    }

    /// Parses "HH:mm" into an (hour, minute) pair.
    private func timeComponents(from value: String) -> (Int, Int)? {
        let parts = value.split(separator: ":")
        guard parts.count == 2,
              let hour = Int(parts[0]), let minute = Int(parts[1]),
              (0...23).contains(hour), (0...59).contains(minute) else { return nil }
        return (hour, minute)
    }

    private func dateFromTimeString(_ value: String) -> Date? {
        guard let (hour, minute) = timeComponents(from: value) else { return nil }
        return Calendar.current.date(from: DateComponents(hour: hour, minute: minute))
    }

    private func scheduleBedtimeNotificationIfNeeded(wakeOrBedData: [String: Any]) {
        // you store sleep / wake data in Firestore. Find the user's bedtime time using your keys.
        // Example: you have wakeWeekday/wakeWeekend (Int) and sleepHoursWeekday/sleepHoursWeekend (Double).
        guard sleepTime else {
            cancelNotification(id: NotificationIDs.bedTime)
            return
        }

        // Clear any previous copies first (including old bare-id schedules).
        cancelNotification(id: NotificationIDs.bedTime)

        // Weekday (Mon-Fri) and weekend (Sat-Sun) use their own wake times.
        scheduleBedtimeVariant(data: wakeOrBedData, wakeKey: "wakeWeekday", sleepHoursKey: "sleepHoursWeekday", weekdays: [2, 3, 4, 5, 6])
        scheduleBedtimeVariant(data: wakeOrBedData, wakeKey: "wakeWeekend", sleepHoursKey: "sleepHoursWeekend", weekdays: [7, 1])
    }

    private func scheduleBedtimeVariant(data: [String: Any], wakeKey: String, sleepHoursKey: String, weekdays: [Int]) {
        let id = NotificationIDs.bedTime
        if let wakeInt = data[wakeKey] as? Int,
           let sleepHours = data[sleepHoursKey] as? Double,
           let wakeDate = Calendar.current.date(from: DateComponents(hour: wakeInt/100, minute: wakeInt%100)),
           let bedtimeDate = Calendar.current.date(byAdding: .minute, value: Int(-sleepHours*60), to: wakeDate),
           let notifyDate = Calendar.current.date(byAdding: .minute, value: -30, to: bedtimeDate) {
            let comps = Calendar.current.dateComponents([.hour, .minute], from: notifyDate)
            scheduleDailyNotification(id: id,
                                      title: "Bedtime Reminder",
                                      body: "It's almost bedtime — wind down for rest.",
                                      hour: comps.hour ?? 0,
                                      minute: comps.minute ?? 0,
                                      weekdays: weekdays)
        } else {
            // couldn't compute this variant's time; remove any copies for these weekdays
            for weekday in weekdays {
                cancelNotification(id: "\(id).\(weekday)")
            }
        }
    }

    private func scheduleNewTasksNotificationIfNeeded(userData: [String: Any]) {
        guard newTasks else {
            cancelNotification(id: NotificationIDs.newTasks)
            return
        }

        // Clear any previous copies first (including old bare-id schedules).
        cancelNotification(id: NotificationIDs.newTasks)

        scheduleNewTasksVariant(data: userData, wakeKey: "wakeWeekday", weekdays: [2, 3, 4, 5, 6])
        scheduleNewTasksVariant(data: userData, wakeKey: "wakeWeekend", weekdays: [7, 1])
    }

    private func scheduleNewTasksVariant(data: [String: Any], wakeKey: String, weekdays: [Int]) {
        let id = NotificationIDs.newTasks
        guard let wakeInt = data[wakeKey] as? Int else {
            for weekday in weekdays {
                cancelNotification(id: "\(id).\(weekday)")
            }
            return
        }

        let hour = wakeInt / 100
        let minute = wakeInt % 100
        if let wakeDate = Calendar.current.date(from: DateComponents(hour: hour, minute: minute)),
           let notifyDate = Calendar.current.date(byAdding: .minute, value: 30, to: wakeDate) {
            let final = Calendar.current.dateComponents([.hour, .minute], from: notifyDate)
            scheduleDailyNotification(id: id,
                                      title: "New Tasks Assigned",
                                      body: "Your daily tasks are here — check your list and get started!",
                                      hour: final.hour ?? 0,
                                      minute: final.minute ?? 0,
                                      weekdays: weekdays)
        } else {
            for weekday in weekdays {
                cancelNotification(id: "\(id).\(weekday)")
            }
        }
    }


}
