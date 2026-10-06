import WidgetKit
import AlarmKit
import SwiftUI

// Mirrors the app-target metadata so the AlarmKit Live Activity can render
// alarm info. Keep in sync with AlarmedIOS/Models/AlarmedAlarmMetadata.swift.
nonisolated struct AlarmedAlarmMetadata: AlarmMetadata {
    var alarmId: String
    var challengeMode: String
}

nonisolated struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: .now)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        completion(SimpleEntry(date: .now))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
        let entries = [SimpleEntry(date: .now)]
        completion(Timeline(entries: entries, policy: .atEnd))
    }
}

nonisolated struct SimpleEntry: TimelineEntry {
    let date: Date
}

struct WidgetView: View {
    var entry: Provider.Entry

    var body: some View {
        Text(entry.date, style: .time)
    }
}

/// Home-screen widget showing the current time (template scaffold retained).
struct AlarmedWidget: Widget {
    let kind: String = "AlarmedWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            WidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("AlarmedWidget")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

/// Live Activity presentation for AlarmKit alarms. The alerting (ringing) UI
/// is rendered by the system; this customizes the non-alerting states on the
/// Lock Screen, Dynamic Island, and StandBy.
struct AlarmedAlarmLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: AlarmAttributes<AlarmedAlarmMetadata>.self) { context in
            AlarmedAlarmActivityView(metadata: context.attributes.metadata)
                .padding()
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "alarm.waves.left.and.right")
                        .foregroundStyle(Color.blue)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(challengeLabel(context.attributes.metadata))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Alarm set")
                        .font(.headline)
                }
            } compactLeading: {
                Image(systemName: "alarm.waves.left.and.right")
                    .foregroundStyle(Color.blue)
            } compactTrailing: {
                Image(systemName: "alarm.waves.left.and.right")
                    .foregroundStyle(Color.blue)
            } minimal: {
                Image(systemName: "alarm.waves.left.and.right")
                    .foregroundStyle(Color.blue)
            }
        }
    }

    private func challengeLabel(_ metadata: AlarmedAlarmMetadata?) -> String {
        metadata?.challengeMode == "phrase" ? "Phrase challenge" : "Questions challenge"
    }
}

private struct AlarmedAlarmActivityView: View {
    let metadata: AlarmedAlarmMetadata?

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "alarm.waves.left.and.right")
                .font(.title2)
                .foregroundStyle(Color.blue)
            VStack(alignment: .leading, spacing: 2) {
                Text("Alarmed")
                    .font(.headline)
                Text(metadata?.challengeMode == "phrase" ? "Phrase challenge ready" : "Questions challenge ready")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }
}
