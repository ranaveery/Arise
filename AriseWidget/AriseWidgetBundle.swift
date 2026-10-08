//
//  AriseWidgetBundle.swift
//  AriseWidget
//
//  Widget extension entry point. Add this file (and AriseWidget.swift) to the
//  `AriseWidget` target, and add `Arise/SharedStore.swift` to that target too.
//

import WidgetKit
import SwiftUI

@main
struct AriseWidgetBundle: WidgetBundle {
    var body: some Widget {
        AriseWidget()
    }
}