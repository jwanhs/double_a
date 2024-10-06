//
//  hstundenplanLiveActivity.swift
//  hstundenplan
//
//  Created by Jwan Haj Sulaiman on 06/10/2024.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct hstundenplanAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct hstundenplanLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: hstundenplanAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension hstundenplanAttributes {
    fileprivate static var preview: hstundenplanAttributes {
        hstundenplanAttributes(name: "World")
    }
}

extension hstundenplanAttributes.ContentState {
    fileprivate static var smiley: hstundenplanAttributes.ContentState {
        hstundenplanAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: hstundenplanAttributes.ContentState {
         hstundenplanAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: hstundenplanAttributes.preview) {
   hstundenplanLiveActivity()
} contentStates: {
    hstundenplanAttributes.ContentState.smiley
    hstundenplanAttributes.ContentState.starEyes
}
