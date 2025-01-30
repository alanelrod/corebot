import SwiftUI
import Cocoa
import AVKit
import AVFoundation
import Combine

class CoreBotManager: ObservableObject {
    static let shared = CoreBotManager()
    
    @Published var currentTime: String = ""
    @Published var nextVideo: (name: String, minute: Int)? = nil
    
    private let videoFolderPath = "/Users/alanelrod/Downloads/corebot"
    private var videoSchedule: [(url: URL, minute: Int)] = []
    private var timer: AnyCancellable?
    private var audioPlayer: AVAudioPlayer?  // Stores the MP3 player
    private let mp3FilePath = "/Users/alanelrod/Downloads/corebot/corebot=.mp3" // Path to your MP3 file

    private init() {
        setupVideoSchedule()
        startClock()
    }

    // 🎵 Function to Play MP3
    private func playMP3() {
        let url = URL(fileURLWithPath: mp3FilePath)
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.numberOfLoops = -1  // Loop indefinitely
            audioPlayer?.play()
            print("🔊 Playing MP3: \(url.lastPathComponent)")
        } catch {
            print("❌ ERROR: Could not play MP3 - \(error.localizedDescription)")
        }
    }

    // 🛑 Function to Stop MP3
    private func stopMP3() {
        audioPlayer?.stop()
        print("🔇 Stopping MP3")
    }

    // 🕒 Start Timers
    func startClock() {
        // Timer for updating the clock every second
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            self.updateCurrentTime()
        }

        // Timer for checking videos every 60 seconds
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            print("⏰ Timer fired! Checking videos...")
            self.checkVideoPlayback()
        }
    }

    // 🕒 Updates UI Clock
    private func updateCurrentTime() {
        DispatchQueue.main.async {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm:ss"
            self.currentTime = formatter.string(from: Date())
        }
    }

    private func getCurrentMinute() -> Int {
        return Calendar.current.component(.minute, from: Date())
    }

    // 📂 Loads Videos and Schedules Random Playback Times
    func setupVideoSchedule() {
        guard let videoFiles = getVideoURLs(), !videoFiles.isEmpty else {
            print("❌ No videos found in folder: \(videoFolderPath)")
            return
        }

        videoSchedule = videoFiles.shuffled().map { video in
            let assignedMinute = Int.random(in: 0..<60)
            print("📅 Scheduled \(video.lastPathComponent) at minute \(assignedMinute)")
            return (url: video, minute: assignedMinute)
        }

        nextVideo = getNextVideo()
    }

    // 📂 Get All Videos in the Folder
    private func getVideoURLs() -> [URL]? {
        let fileManager = FileManager.default
        guard let videoFiles = try? fileManager.contentsOfDirectory(atPath: videoFolderPath)
                .filter({ $0.hasSuffix(".mp4") || $0.hasSuffix(".mov") }) else {
            return nil
        }
        return videoFiles.map { URL(fileURLWithPath: "\(videoFolderPath)/\($0)") }
    }

    // 🎬 Checks if a Video Should Play
    func checkVideoPlayback() {
        let currentMinute = getCurrentMinute()
        print("🔎 Checking schedule at minute: \(currentMinute)")

        if let index = videoSchedule.firstIndex(where: { $0.minute == currentMinute }) {
            let video = videoSchedule.remove(at: index)
            print("🎬 Playing \(video.url.lastPathComponent) at \(video.minute):00")
            showVideoWindow(videoURL: video.url)
            nextVideo = getNextVideo()
        } else {
            print("⏳ No video scheduled for this minute.")
        }
    }

    // 🎥 Opens Video in a Pop-up Window
    func showVideoWindow(videoURL: URL) {
        guard let videoDimensions = getVideoDimensions(url: videoURL) else {
            print("❌ ERROR: Could not get video dimensions for \(videoURL.lastPathComponent)")
            return
        }

        let popUpWindow = NSWindow(
            contentRect: NSMakeRect(0, 0, videoDimensions.width, videoDimensions.height),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )

        popUpWindow.center()
        popUpWindow.makeKeyAndOrderFront(nil)

        let player = AVPlayer(url: videoURL)
        let playerView = AVPlayerView(frame: popUpWindow.contentView!.bounds)
        playerView.player = player
        popUpWindow.contentView?.addSubview(playerView)

        print("🎬 Playing Video: \(videoURL.lastPathComponent)")
        
        // 🎵 Play MP3 when the video starts
        playMP3()

        // 🚀 Start Video
        player.play()

        // 🛑 Stop MP3 When Video Ends
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player.currentItem, queue: .main) { _ in
            self.stopMP3()
            popUpWindow.close()
        }
    }

    // 📏 Gets Video Dimensions
    private func getVideoDimensions(url: URL) -> CGSize? {
        let asset = AVAsset(url: url)
        if let track = asset.tracks(withMediaType: .video).first {
            let size = track.naturalSize.applying(track.preferredTransform)
            return CGSize(width: abs(size.width), height: abs(size.height))
        }
        return nil
    }

    // 🎬 Get the Next Scheduled Video
    private func getNextVideo() -> (name: String, minute: Int)? {
        let currentMinute = getCurrentMinute()
        if let next = videoSchedule.first(where: { $0.minute >= currentMinute }) {
            return (name: next.url.lastPathComponent, minute: next.minute)
        }
        return nil
    }
}
