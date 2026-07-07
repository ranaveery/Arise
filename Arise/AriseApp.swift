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

    // Handle Google Sign-In redirect
    func scene(_ scene: UIScene,
               openURLContexts URLContexts: Set<UIOpenURLContext>) {
        for context in URLContexts {
            let url = context.url
            if GIDSignIn.sharedInstance.handle(url) {
                return
            }
        }
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

    var body: some Scene {
        WindowGroup {
            AuthGateView()
        }
    }
}
