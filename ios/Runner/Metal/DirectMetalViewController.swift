import UIKit
import MetalKit

class DirectMetalViewController: UIViewController {
    private var metalView: MTKView!
    private var renderer: LowLatencyRenderer!

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        renderer = LowLatencyRenderer()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        renderer = LowLatencyRenderer()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Metal is not supported on this device")
        }
        
        // Disable ALL iOS optimizations that could add latency
        metalView = MTKView(frame: view.bounds)
        metalView.device = device
        metalView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        // Critical: Set to max refresh rate, disable vsync if needed
        metalView.preferredFramesPerSecond = 120 // ProMotion displays
        metalView.enableSetNeedsDisplay = false // Continuous rendering

        metalView.delegate = renderer

        view.addSubview(metalView)

        // Hide status bar for maximum screen real estate
        modalPresentationStyle = .fullScreen
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

    func configure(with data: [String: Any]) {
        renderer.initialize(with: data)
    }

    func updateSprites(_ data: [String: Any]) {
        renderer.updateSprites(data)
    }

    // Add gesture recognizer for going back
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(dismissSelf))
        swipeGesture.direction = .down
        view.addGestureRecognizer(swipeGesture)
    }

    @objc private func dismissSelf() {
        dismiss(animated: false, completion: nil)
    }
}
