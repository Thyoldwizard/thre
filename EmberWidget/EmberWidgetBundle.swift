// EmberWidgetBundle.swift
import WidgetKit
import SwiftUI

@main
struct EmberWidgetBundle: WidgetBundle {
    var body: some Widget {
        EmberTodayWidget()
        EmberLockScreenWidget()
        if #available(iOS 16.1, *) {
            FocusSessionLiveActivity()
        }
    }
}
