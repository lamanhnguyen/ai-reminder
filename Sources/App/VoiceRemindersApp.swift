import SwiftUI
import UserNotifications
import AVFoundation
import Foundation
import ObjectiveC

// Define fallback bundle identifier
let kAppBundleIdentifier = "com.example.VoiceReminders"

// Swizzle NSBundle to ensure bundleIdentifier is never nil
@objc class BundleFix: NSObject {
    static var originalMethod: Method?
    static var swizzledMethod: Method?
    static var isApplied = false
    static var hasLoggedFallback = false
    
    static func applyFix() {
        // Only run on main thread to avoid UIKit threading issues
        if !Thread.isMainThread {
            DispatchQueue.main.sync {
                applyFix()
            }
            return
        }
        
        // Only apply once
        if self.isApplied { return }
        self.isApplied = true
        
        // Set environment variables first (safer approach that doesn't involve swizzling)
        setenv("CFBUNDLEIDENTIFIER", kAppBundleIdentifier, 1)
        setenv("APP_BUNDLE_IDENTIFIER", kAppBundleIdentifier, 1)
        
        print("Environment variables set: \(kAppBundleIdentifier)")
        
        // Check if bundle identifier already works properly
        if let identifier = Bundle.main.bundleIdentifier, !identifier.isEmpty {
            print("Bundle identifier already available: \(identifier)")
            return
        }
        
        // Only proceed with swizzling if necessary
        do {
            // Get Bundle class
            guard let bundleClass = object_getClass(Bundle.main) else {
                print("Failed to get Bundle class")
                return
            }
            
            // Get original and swizzled methods
            guard let origMethod = class_getInstanceMethod(bundleClass, #selector(getter: Bundle.bundleIdentifier)),
                  let swizMethod = class_getInstanceMethod(BundleFix.self, #selector(BundleFix.fakeBundleIdentifier)) else {
                print("Failed to get methods")
                return
            }
            
            // Store references
            originalMethod = origMethod
            swizzledMethod = swizMethod
            
            // Exchange implementations
            method_exchangeImplementations(origMethod, swizMethod)
            
            print("Bundle identifier patch applied")
        } catch {
            print("Failed to apply bundle identifier patch: \(error)")
        }
    }
    
    // Our replacement implementation that always returns a value
    @objc func fakeBundleIdentifier() -> String? {
        // Safety check to prevent crashes during event processing
        guard let _ = self as? Bundle else {
            return kAppBundleIdentifier
        }
        
        // Return fallback directly to avoid any recursive calls
        return kAppBundleIdentifier
    }
}

@available(macOS 11.0, iOS 14.0, *)
@main
struct VoiceRemindersApp: App {
    // Initialize core services
    let dependencyContainer = DependencyContainer()
    
    init() {
        // Set environment variables before anything else
        setenv("CFBUNDLEIDENTIFIER", kAppBundleIdentifier, 1)
        setenv("APP_BUNDLE_IDENTIFIER", kAppBundleIdentifier, 1)
        
        // Apply bundle identifier fix safely
        BundleFix.applyFix()
        
        // Set up app defaults
        let defaults: [String: Any] = [
            "AppBundleIdentifier": kAppBundleIdentifier,
            "AppFirstLaunch": Date().timeIntervalSince1970
        ]
        
        UserDefaults.standard.register(defaults: defaults)
        
        #if DEBUG
        // Print bundle info
        print("--- Bundle Debug Info ---")
        print("Bundle identifier: \(Bundle.main.bundleIdentifier ?? "nil")")
        print("Bundle path: \(Bundle.main.bundlePath)")
        print("Info.plist path: \(Bundle.main.path(forResource: "Info", ofType: "plist") ?? "not found")")
        print("Main bundle URL: \(Bundle.main.bundleURL)")
        print("--- End Bundle Debug Info ---")
        #endif
    }
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(dependencyContainer)
        }
    }
    
    private func requestNotificationPermissions() {
        #if os(iOS)
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
            if let error = error {
                print("Error requesting notification permission: \(error.localizedDescription)")
            } else {
                print("Notification permission granted: \(success)")
            }
        }
        #endif
    }
} 
