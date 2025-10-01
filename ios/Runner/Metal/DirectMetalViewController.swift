import UIKit
import MetalKit

class DirectMetalViewController: UIViewController {
    private var metalView: MTKView!
    private var renderer: LowLatencyRenderer!
    private var commandQueue: MTLCommandQueue!

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)

        renderer = LowLatencyRenderer()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let device = MTLCreateSystemDefaultDevice(),
              let queue = device.makeCommandQueue() else {
            fatalError("Metal is not supported on this device")
        }

        self.commandQueue = queue

        metalView = MTKView(frame: view.bounds)
        metalView.device = device
        metalView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        metalView.preferredFramesPerSecond = 120
        metalView.enableSetNeedsDisplay = false

        metalView.delegate = renderer

        view.addSubview(metalView)
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

    func configure(with data: [String: Any]) {
        renderer.initialize(with: data)
    }

    func updateScreen(with counter: Int) {
        guard let drawable = metalView.currentDrawable,
              let renderPassDescriptor = metalView.currentRenderPassDescriptor else {
            return
        }

        // Create a command buffer.
        guard let commandBuffer = commandQueue.makeCommandBuffer() else { return }

        // Let the renderer apply draw commands.
        renderer.encodeRenderCommands(counter, into: commandBuffer, using: renderPassDescriptor)
        commandBuffer.commit()

        // Synchronous presentation needs to wait before the call to present().
        // See https://developer.apple.com/documentation/quartzcore/cametallayer/presentswithtransaction.
        commandBuffer.waitUntilScheduled()
        drawable.present()
    }

    // Add gesture recognizer for going back.
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(dismissSelf))
        swipeGesture.direction = .down
        view.addGestureRecognizer(swipeGesture)

        updateScreen(with: 0);
    }

    @objc private func dismissSelf() {
        dismiss(animated: false, completion: nil)
    }
}
