//
//  SpliteasyApp.swift
//  Spliteasy
//
//  Created by SIDHARTHA JAVVADI on 3/11/26.
//

import SwiftUI
import FirebaseCore

@main
struct SplitEasyApp: App {
    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
