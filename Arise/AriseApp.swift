import SwiftUI
import FirebaseCore
import FirebaseFirestore
import GoogleSignIn

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        let settings = Firestore.firestore().settings
        var cache = settings.cacheSettings
        cache = PersistentCacheSettings()
        settings.cacheSettings = cache
        Firestore.firestore().settings = settings
        return true
    }

    //  Lock orientation to portrait only
    func application(_ application: UIApplication,
                     supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return .portrait
    }
}


@main
struct AriseApp: App {
    // Register AppDelegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    @State private var proStore = ProStore()
    @State private var showDeepLinkPaywall = false

    var body: some Scene {
        WindowGroup {
            AuthGateView()
                .environment(proStore)
                .task {
                    proStore.start()
                }
                .onOpenURL { url in
                    if url.scheme == "arise", url.host == "pro" {
                        showDeepLinkPaywall = true
                    }
                }
                .sheet(isPresented: $showDeepLinkPaywall) {
                    PaywallView()
                }
        }
    }
}
