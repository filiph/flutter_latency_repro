#include <metal_stdlib>
using namespace metal;

// Vertex input structure
struct Vertex {
    float2 position [[attribute(0)]];
    float4 color [[attribute(1)]];
};

// Data passed from vertex to fragment shader
struct VertexOut {
    float4 position [[position]];
    float4 color;
};

// Vertex shader
vertex VertexOut vertex_main(uint vertexID [[vertex_id]],
                           constant float *vertexArray [[buffer(0)]]) {
    // Each vertex has 6 floats: x, y, r, g, b, a
    int index = vertexID * 6;

    VertexOut out;
    out.position = float4(vertexArray[index], vertexArray[index + 1], 0.0, 1.0);
    out.color = float4(vertexArray[index + 2], vertexArray[index + 3],
                       vertexArray[index + 4], vertexArray[index + 5]);
    return out;
}

// Fragment shader
fragment float4 fragment_main(VertexOut in [[stage_in]]) {
    return in.color;
}
