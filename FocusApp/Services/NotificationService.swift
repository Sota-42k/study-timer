import AVFoundation
import UserNotifications

final class NotificationService: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationService()

    private var audioPlayer: AVAudioPlayer?

    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        if let url = Bundle.main.url(forResource: "timer", withExtension: "wav") {
            audioPlayer = try? AVAudioPlayer(contentsOf: url)
            audioPlayer?.prepareToPlay()
        }
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    func fireCompletionNotification(for type: SessionType) {
        playSound()

        let content = UNMutableNotificationContent()
        switch type {
        case .focus:
            content.title = "Focus session complete!"
            content.body  = "Time for a break. You earned it."
        case .shortBreak, .longBreak:
            content.title = "Break over!"
            content.body  = "Ready to focus again?"
        }
        content.sound = .default
        let request = UNNotificationRequest(identifier: UUID().uuidString,
                                             content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }

    private func playSound() {
        let stored = UserDefaults.standard.double(forKey: UserDefaultsKeys.soundVolume)
        audioPlayer?.volume = stored > 0 ? Float(stored) : 1.0
        audioPlayer?.currentTime = 0
        audioPlayer?.play()
    }
}
