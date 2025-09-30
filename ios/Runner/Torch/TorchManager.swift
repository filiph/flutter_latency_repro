import Foundation
import AVFoundation

struct TorchManager {
    
    /// Turns the torch on for a specified duration, then turns it off.
    /// This is an async fire-and-forget function.
    /// - Parameter durationMilliseconds: The duration to keep the torch on, in milliseconds.
    static func blink(durationMilliseconds: Int = 100) async {
        // Ensure we're on a real device
        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else {
            print("Torch is not available on this device.")
            return
        }
        
        // --- Turn Torch ON ---
        do {
            try device.lockForConfiguration()
            device.torchMode = .on
            device.unlockForConfiguration()
        } catch {
            print("Error enabling torch: \(error)")
            return // Exit if we can't turn it on
        }
        
        // --- Wait for the specified duration ---
        try? await Task.sleep(nanoseconds: UInt64(durationMilliseconds) * 1_000_000)
        
        // --- Turn Torch OFF ---
        do {
            try device.lockForConfiguration()
            device.torchMode = .off
            device.unlockForConfiguration()
        } catch {
            print("Error disabling torch: \(error)")
        }
    }
}
