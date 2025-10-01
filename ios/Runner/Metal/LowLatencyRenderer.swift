import Metal
import MetalKit
import Foundation

class LowLatencyRenderer: NSObject {
    private var device: MTLDevice!
    private var renderPipelineState: MTLRenderPipelineState!
    private let vertexBuffer: MTLBuffer

    override init() {
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Metal not supported on this device")
        }
        self.device = device

        let vertexDataSize = 3 * 6 * MemoryLayout<Float>.size
        guard let buffer = device.makeBuffer(length: vertexDataSize, options: .storageModeShared) else {
            fatalError("Could not create vertex buffer")
        }
        self.vertexBuffer = buffer

        super.init()
        createPipeline()
    }

    private func createPipeline() {
        guard let library = device.makeDefaultLibrary(),
              let vertexFunction = library.makeFunction(name: "vertex_main"),
              let fragmentFunction = library.makeFunction(name: "fragment_main") else {
            fatalError("Could not load shader library or functions")
        }

        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm

        do {
            renderPipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            fatalError("Could not create render pipeline state: \(error)")
        }
    }

    func encodeRenderCommands(
        _ counter: Int,
        into commandBuffer: MTLCommandBuffer,
        using renderPassDescriptor: MTLRenderPassDescriptor)
    {
        let vertices: [Float] = (counter % 2 == 0) ?
        [ 0.9, -0.8, 1.0, 1.0, 1.0, 1.0, // Top right
          0.9, -0.9, 1.0, 1.0, 1.0, 1.0, // Bottom right
          0.8, -0.9, 1.0, 1.0, 1.0, 1.0, // Bottom left
        ] :
        [ 0.8, -0.8, 1.0, 1.0, 1.0, 1.0, // Top left
          0.9, -0.9, 1.0, 1.0, 1.0, 1.0, // Bottom right
          0.8, -0.9, 1.0, 1.0, 1.0, 1.0, // Bottom left
        ];

        memcpy(vertexBuffer.contents(), vertices, vertices.count * MemoryLayout<Float>.size)

        guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else { return }

        encoder.setRenderPipelineState(renderPipelineState)
        encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        encoder.endEncoding()
    }

    // Configuration method for future use
    func initialize(with data: [String: Any]) {
        print("Renderer initialized with data: \(data)")
    }
}

// MARK: - MTKViewDelegate
extension LowLatencyRenderer: MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        print("Drawable size changed to: \(size)")
    }

    func draw(in view: MTKView) {}
}
