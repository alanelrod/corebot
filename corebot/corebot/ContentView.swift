import SwiftUI
struct ContentView: View {
    @StateObject private var model = CoreBotManager.shared

    var body: some View {
        VStack(spacing: 20) {
            Text("corebot")
                .font(.title)
                .bold()

            Image("yaguey")
                .resizable()
                .scaledToFit()
                .frame(width: 102.4, height: 102.4)

            Text("Current Time: \(model.currentTime)")
                .font(.headline)

            if let upcoming = model.nextVideo {
                Text("Next Video: \(upcoming.name)")
                    .font(.subheadline)
                Text("Scheduled Time: \(formatTime(upcoming.minute))")
                    .font(.subheadline)
            } else {
                Text("No upcoming videos.")
                    .font(.subheadline)
            }

            Button("Force Check Video") {
                print("🔍 Manually checking video playback...")
                model.checkVideoPlayback()
            }
            .padding()

            Button("Reload Videos") {
                model.setupVideoSchedule()
            }
            .padding()
        }
        .padding()
        .frame(width: 350, height: 300)
    }

    private func formatTime(_ minute: Int) -> String {
        let now = Date()
        let calendar = Calendar.current
        var components = calendar.dateComponents([.hour, .minute], from: now)
        components.minute = minute
        guard let newTime = calendar.date(from: components) else { return "--:--" }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: newTime)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
