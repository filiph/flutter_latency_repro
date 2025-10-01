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

        metalView.preferredFramesPerSecond = 120 // ProMotion displays
        metalView.enableSetNeedsDisplay = false // Continuous rendering
        metalView.presentsWithTransaction = true

        metalView.delegate = renderer

        view.addSubview(metalView)
        
        setupTapGesture()
    }
    
    private func setupTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        tapGesture.numberOfTapsRequired = 1

        metalView.addGestureRecognizer(tapGesture)

        print("Tap gesture added - tap anywhere to dismiss")
    }
    
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        print("Metal view tapped - dismissing")
        dismiss(animated: false, completion: nil)
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

    func configure(with data: [String: Any]) {
        renderer.initialize(with: data)
    }

    func updateScreenData(_ data: [String: Any]) {
        renderer.updateScreenData(data)
        
        // Get the resources needed for this frame.
        guard let drawable = metalView.currentDrawable,
              let renderPassDescriptor = metalView.currentRenderPassDescriptor else {
            return
        }
        
        // Create a command buffer.
        guard let commandBuffer = commandQueue.makeCommandBuffer() else { return }
        
        // Synchronous presentation (see https://developer.apple.com/documentation/quartzcore/cametallayer/presentswithtransaction)
        
        // Ask the renderer to encode its drawing commands.
        renderer.encodeRenderCommands(into: commandBuffer, using: renderPassDescriptor)
        
        // 1. Commit the command buffer.
        commandBuffer.commit()
        
        // 2. Wait until the GPU has scheduled the work.
        //    This is the crucial step to ensure a transaction is available.
        commandBuffer.waitUntilScheduled()
        
        // 3. Present the drawable. This is now synchronized with the CATransaction.
        drawable.present()
    }

    // Add gesture recognizer for going back
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(dismissSelf))
        swipeGesture.direction = .down
        view.addGestureRecognizer(swipeGesture)
        
        updateScreenData(["counter": 0]);
    }

    @objc private func dismissSelf() {
        dismiss(animated: false, completion: nil)
    }
}
