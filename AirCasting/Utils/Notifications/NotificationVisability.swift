import Foundation

/// ℹ️ Notification Visibility Levels:
/// - `Prominent`: Includes sound and appears on screen; also appears in the notification center.
/// - `Visible`: Appears on screen and in the notification center, but without sound.
/// - `Unnoticed`: Only appears in the notification center, without sound or on-screen alert.
enum NotificationVisability: String {
    case prominent
    case visible
    case unnoticed
}
