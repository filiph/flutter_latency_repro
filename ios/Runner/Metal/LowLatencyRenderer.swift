import Metal
import MetalKit
import Foundation

class LowLatencyRenderer: NSObject {
    private var device: MTLDevice!
    private var commandQueue: MTLCommandQueue!
    private var renderPipelineState: MTLRenderPipelineState!
    private var vertexBuffer: MTLBuffer!

    override init() {
        super.init()
        setupMetal()
        createPipeline()
        createVertexData()
    }

    private func setupMetal() {
        // 1. Get the GPU device
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Metal not supported on this device")
        }
        self.device = device

        // 2. Create command queue (manages GPU work)
        guard let commandQueue = device.makeCommandQueue() else {
            fatalError("Could not create command queue")
        }
        self.commandQueue = commandQueue

        print("Metal initialized successfully")
    }

    private func createPipeline() {
        // 1. Load shader library
        guard let library = device.makeDefaultLibrary() else {
            fatalError("Could not load shader library")
        }

        guard let vertexFunction = library.makeFunction(name: "vertex_main") else {
            fatalError("Could not find vertex_main function")
        }

        guard let fragmentFunction = library.makeFunction(name: "fragment_main") else {
            fatalError("Could not find fragment_main function")
        }

        // 2. Create pipeline descriptor
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm

        // 3. Create pipeline state
        do {
            renderPipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
            print("Render pipeline created successfully")
        } catch {
            fatalError("Could not create render pipeline state: \(error)")
        }
    }

    private func createVertexData() {
        // Create a simple triangle - each vertex has position (x,y) and color (r,g,b,a)
        let vertices: [Float] = [
            // Positions    Colors
             0.0,  0.8,     1.0, 0.0, 0.0, 1.0,  // Top vertex - Red
            -0.8, -0.8,     0.0, 1.0, 0.0, 1.0,  // Bottom Left - Green  
             0.8, -0.8,     0.0, 0.0, 1.0, 1.0   // Bottom Right - Blue
        ]

        let dataSize = vertices.count * MemoryLayout<Float>.size
        vertexBuffer = device.makeBuffer(bytes: vertices, length: dataSize, options: [])

        guard vertexBuffer != nil else {
            fatalError("Could not create vertex buffer")
        }

        print("Vertex buffer created with \(vertices.count) floats")
    }

    // Configuration method for future use
    func initialize(with data: [String: Any]) {
        print("Renderer initialized with data: \(data)")
    }

    // Update method for future sprite updates
    func updateSprites(_ data: [String: Any]) {
        print("Sprites updated: \(data)")
    }
}

// MARK: - MTKViewDelegate
extension LowLatencyRenderer: MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        print("Drawable size changed to: \(size)")
    }

    func draw(in view: MTKView) {
        // Get drawable surface
        guard let drawable = view.currentDrawable else {
            print("No drawable available")
            return
        }

        // Create command buffer
        guard let commandBuffer = commandQueue.makeCommandBuffer() else {
            print("Could not create command buffer")
            return
        }

        // Get render pass descriptor
        guard let renderPass = view.currentRenderPassDescriptor else {
            print("No render pass descriptor")
            return
        }

        // Set clear color to black
        renderPass.colorAttachments[0].clearColor = MTLClearColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)

        // Create render command encoder
        guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPass) else {
            print("Could not create render encoder")
            return
        }

        // Set the render pipeline
        encoder.setRenderPipelineState(renderPipelineState)

        // Bind vertex data
        encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)

        // Draw the triangle (3 vertices)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)

        // End encoding
        encoder.endEncoding()

        // Present to screen
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
