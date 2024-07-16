#version 460 core
layout (local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(rgba32f, binding = 2) uniform image2D imgOutput;

layout(std140, binding = 1) uniform MyUniforms {
    vec2 position;
};

layout (location = 0) uniform float t;                 /** Time */

void main() {
    vec4 value = vec4(0.0, 0.0, 0.0, 1.0);
    ivec2 texelCoord = ivec2(gl_GlobalInvocationID.xy);
    ivec2 center = {int(position.x), int(position.y)};

    float r = length(texelCoord - center);

    int enable = int(r < 300);

    value = vec4(1.f)*enable + vec4(0.0, 0.0, 0.0, 1.0)*(1-enable);

    imageStore(imgOutput, texelCoord, value);
}