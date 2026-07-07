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
    
    private var versionInfo: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        return "v\(version)"
    }
    
    let gradient = LinearGradient.brand

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 26) {
                    // HEADER
                    VStack(spacing: 4) {
                        Text("Settings")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.white)

                        Text("Customize your experience")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(.top, 20)

                    if isLoading {
                        ProgressView()
                            .tint(.white)
                            .padding(.top, 60)
                    } else {
                        // ACCOUNT (title + card grouped)
                        sectionBlock("ACCOUNT") {
                        inputRow(systemImage: "person", label: "Name", binding: $name, isEditable: true) {
                            saveNameToFirestore(name)
                        }
                        dividerLine()
                        inputRow(systemImage: "envelope",
                                 label: "Email",
                                 binding: .constant(userEmail.isEmpty ? "No email set" : userEmail),
                                 isEditable: false)
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
                    }

                    // NOTIFICATIONS (title + card grouped)
                    sectionBlock("NOTIFICATIONS") {
                        notificationsContent()
                    }

                    // APPEARANCE
                    sectionBlock("APPEARANCE") {
                        staticRow(systemImage: "circle.lefthalf.filled", label: "Mode", value: "Dark")
                        dividerLine()
                        Toggle(isOn: $animationsEnabled) {
                            HStack {
                                Image(systemName: "circle.dotted.and.circle")
                                    .foregroundColor(.gray)
                                    .frame(width: 20)
                                Text("Animations").foregroundColor(.white)
                            }
                        }
                        .tint(Color(red: 84/255, green: 0/255, blue: 232/255))
                        .padding(.horizontal)
                        .padding(.vertical, 12)
                        .onChange(of: animationsEnabled) { _, newValue in
                            PreferenceManager.saveTopLevelPreference(key: "animationsEnabled", value: newValue)
                        }
                    }

                    // APP / ABOUT
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
                        userIDRow()
                        dividerLine()
                        staticRow(systemImage: "info.circle", label: "Version", value: versionInfo)
                    }

                    // LOG OUT
                    Button(action: { showLogoutConfirmation = true }) {
                        Text("Log Out")
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Capsule().fill(Color.white.opacity(0.1)))
                    }
                    .alert(isPresented: $showLogoutConfirmation) {
                        Alert(
                            title: Text("Are you sure?"),
                            message: Text("Do you really want to log out?"),
                            primaryButton: .destructive(Text("Log Out")) {
                                do {
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
                .padding(.top)
            }
            .background(Color.black.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $navigateToChangePassword) {
                ChangePasswordView()
            }
            .onAppear {
                if let cached = UserDefaults.standard.dictionary(forKey: "cachedUserData") {
                    self.name = cached["name"] as? String ?? ""
                    self.userEmail = cached["email"] as? String ?? ""
                }
                loadUserData()
                loadPreferences()
                requestNotificationAuthorizationIfNeeded()
                fetchUserTimesAndReschedule()
            }
        }
        .preferredColorScheme(.dark)
    }




    // MARK: - SECTION BLOCK (title + card grouped)
    private func sectionBlock<Content: View>(_ title: String,
                                             @ViewBuilder content: @escaping () -> Content) -> some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(gradient)
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
            HStack {
                Image(systemName: "clock.badge.exclamationmark").foregroundColor(.gray).frame(width: 20)
                Text("Expiring Tasks").foregroundColor(.white)
            }
        }
        .tint(Color(red: 84/255, green: 0/255, blue: 232/255))
        .padding(.horizontal)
        .padding(.vertical, 12)
        .onChange(of: expiringTasks) { _, newValue in
            PreferenceManager.savePreference(key: "expiringTasks", value: newValue)
            fetchUserTimesAndReschedule()
        }

        dividerLine()

        Toggle(isOn: $newTasks) {
            HStack {
                Image(systemName: "plus.square.on.square").foregroundColor(.gray).frame(width: 20)
                Text("New Tasks").foregroundColor(.white)
            }
        }
        .tint(Color(red: 84/255, green: 0/255, blue: 232/255))
        .padding(.horizontal)
        .padding(.vertical, 12)
        .onChange(of: newTasks) { _, newValue in
            PreferenceManager.savePreference(key: "newTasks", value: newValue)
            fetchUserTimesAndReschedule()
        }

        dividerLine()

        Toggle(isOn: $sleepTime) {
            HStack {
                Image(systemName: "moon.fill").foregroundColor(.gray).frame(width: 20)
                Text("Bedtime").foregroundColor(.white)
            }
        }
        .tint(Color(red: 84/255, green: 0/255, blue: 232/255))
        .padding(.horizontal)
        .padding(.vertical, 12)
        .onChange(of: sleepTime) { _, newValue in
            PreferenceManager.savePreference(key: "sleepTime", value: newValue)
            fetchUserTimesAndReschedule()
        }
    }

    // MARK: - Divider between rows (no gaps)
    private func dividerLine() -> some View {
        Divider()
            .background(Color.white.opacity(0.06))
            .padding(.leading, 45)
    }

    // MARK: - Reusable Rows
    private func staticRow(systemImage: String, label: String, value: String) -> some View {
        HStack {
            Image(systemName: systemImage).foregroundColor(.white.opacity(0.5)).frame(width: 20)
            Text(label).foregroundColor(.white)
            Spacer()
            Text(value).foregroundColor(.white.opacity(0.5))
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }

    private func navRow<Destination: View>(systemImage: String, label: String, destination: @escaping () -> Destination) -> some View {
        NavigationLink(destination: destination()) {
            HStack {
                Image(systemName: systemImage).foregroundColor(.white.opacity(0.5)).frame(width: 20)
                Text(label).foregroundColor(.white)
                Spacer()
                Image(systemName: "chevron.right").foregroundColor(.white.opacity(0.5))
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
    }

    private func buttonRow(systemImage: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: systemImage).foregroundColor(.white.opacity(0.5)).frame(width: 20)
                Text(label).foregroundColor(.white)
                Spacer()
                Image(systemName: "chevron.right").foregroundColor(.white.opacity(0.5))
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
    }

    @ViewBuilder
    private func appRow<Destination: View>(systemImage: String, label: String, destination: @escaping () -> Destination) -> some View {
        navRow(systemImage: systemImage, label: label, destination: destination)
    }

    private func userIDRow() -> some View {
        HStack {
            Image(systemName: "grid.circle")
                .foregroundColor(.white.opacity(0.5))
                .frame(width: 20)
            Text("User ID").foregroundColor(.white)
            Spacer()
            if let user = Auth.auth().currentUser {
                Text(user.uid)
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.5))
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .textSelection(.enabled)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }

    private func inputRow(
        systemImage: String,
        label: String,
        binding: Binding<String>,
        isEditable: Bool,
        onCommit: (() -> Void)? = nil
    ) -> some View {
        HStack {
            Image(systemName: systemImage)
                .foregroundColor(.white.opacity(0.5))
                .frame(width: 20)
            Text(label)
                .foregroundColor(.white)
            Spacer()
            if isEditable {
                EditableTextField(text: binding, onCommit: onCommit)
            } else {
                Text(binding.wrappedValue)
                    .foregroundColor(.white.opacity(0.5))
                    .font(.footnote)
                    .multilineTextAlignment(.trailing)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
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

    private func loadPreferences() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        db.collection("users").document(uid).getDocument { snapshot, _ in
            if let data = snapshot?.data() {
                if let notifications = data["notifications"] as? [String: Bool] {
                    expiringTasks = notifications["expiringTasks"] ?? true
                    newTasks = notifications["newTasks"] ?? true
                    sleepTime = notifications["sleepTime"] ?? true
                }
                if let animationsPref = data["animationsEnabled"] as? Bool {
                    animationsEnabled = animationsPref
                }
            }
            preferencesLoaded = true
            DispatchQueue.main.async { self.isLoading = false }
        }
    }

    private func loadUserData() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        db.collection("users").document(uid).getDocument { snapshot, error in
            if let data = snapshot?.data(), error == nil {
                let fetchedName = sanitizeName(data["name"] as? String ?? "")
                let fetchedEmail = data["email"] as? String ?? ""
                DispatchQueue.main.async {
                    self.name = fetchedName
                    self.userEmail = fetchedEmail
                    self.isLoading = false
                }
                UserDefaults.standard.set(["name": fetchedName, "email": fetchedEmail], forKey: "cachedUserData")
            } else {
                DispatchQueue.main.async { self.isLoading = false }
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
                                           repeats: Bool = true) {
        // build content
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        // build calendar trigger
        var comps = DateComponents()
        comps.hour = hour
        comps.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: repeats)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { _ in }
    }

    private func cancelNotification(id: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
    }

    private func timeFromMilitaryInt(_ intTime: Int) -> DateComponents {
        // e.g. 730 -> 07:30, 2130 -> 21:30
        let hour = intTime / 100
        let minute = intTime % 100
        return DateComponents(hour: hour, minute: minute)
    }

    private func scheduleExpiringTasksNotificationIfNeeded() {
        if expiringTasks {
            // schedule at 18:00
            scheduleDailyNotification(id: NotificationIDs.expiringTasks,
                                      title: "Expiring Tasks",
                                      body: "Reminder to get all your tasks done.",
                                      hour: 18,
                                      minute: 0)
        } else {
            cancelNotification(id: NotificationIDs.expiringTasks)
        }
    }

    private func scheduleBedtimeNotificationIfNeeded(wakeOrBedData: [String: Any]) {
        // you store sleep / wake data in Firestore. Find the user's bedtime time using your keys.
        // Example: you have wakeWeekday/wakeWeekend (Int) and sleepHoursWeekday/sleepHoursWeekend (Double).
        guard sleepTime else {
            cancelNotification(id: NotificationIDs.bedTime)
            return
        }

        // pick weekday vs weekend based on today
        let calendar = Calendar.current
        let todaySystem = calendar.component(.weekday, from: Date()) // Sunday=1
        let todayIndex = (todaySystem == 1) ? 7 : (todaySystem - 1) // convert to 1=Monday..7=Sunday

        let isWeekend = (todayIndex == 6 || todayIndex == 7)

        let wakeKey = isWeekend ? "wakeWeekend" : "wakeWeekday"
        let sleepHoursKey = isWeekend ? "sleepHoursWeekend" : "sleepHoursWeekday"

        if let wakeInt = wakeOrBedData[wakeKey] as? Int,
           let sleepHours = wakeOrBedData[sleepHoursKey] as? Double,
           let wakeDate = Calendar.current.date(from: DateComponents(hour: wakeInt/100, minute: wakeInt%100)) {
            // compute bedtime by subtracting sleepHours
            if let bedtimeDate = Calendar.current.date(byAdding: .minute, value: Int(-sleepHours*60), to: wakeDate) {
                // subtract 30 minutes for the notification
                if let notifyDate = Calendar.current.date(byAdding: .minute, value: -30, to: bedtimeDate) {
                    let comps = Calendar.current.dateComponents([.hour, .minute], from: notifyDate)
                    scheduleDailyNotification(id: NotificationIDs.bedTime,
                                              title: "Bedtime Reminder",
                                              body: "It's almost bedtime — wind down for rest.",
                                              hour: comps.hour ?? 0,
                                              minute: comps.minute ?? 0)
                    return
                }
            }
        }

        // fallback: cancel if we couldn't compute
        cancelNotification(id: NotificationIDs.bedTime)
    }

    private func scheduleNewTasksNotificationIfNeeded(userData: [String: Any]) {
        if !newTasks {
            cancelNotification(id: NotificationIDs.newTasks)
            return
        }

        // Decide wake key depending on weekday/weekend similar to above
        let calendar = Calendar.current
        let todaySystem = calendar.component(.weekday, from: Date()) // Sunday=1
        let todayIndex = (todaySystem == 1) ? 7 : (todaySystem - 1)
        let isWeekend = (todayIndex == 6 || todayIndex == 7)
        let wakeKey = isWeekend ? "wakeWeekend" : "wakeWeekday"

        if let wakeInt = userData[wakeKey] as? Int {
            // compute wake time + 30 minutes
            let hour = wakeInt / 100
            let minute = wakeInt % 100
            var comps = DateComponents()
            comps.hour = hour
            comps.minute = minute
            if let wakeDate = Calendar.current.date(from: comps),
               let notifyDate = Calendar.current.date(byAdding: .minute, value: 30, to: wakeDate) {
                let final = Calendar.current.dateComponents([.hour, .minute], from: notifyDate)
                scheduleDailyNotification(id: NotificationIDs.newTasks,
                                          title: "New Tasks Assigned",
                                          body: "Your daily tasks are here — check your list and get started!",
                                          hour: final.hour ?? 0,
                                          minute: final.minute ?? 0)
                return
            }
        }

        // fallback
        cancelNotification(id: NotificationIDs.newTasks)
    }


}
