#version 460 core

/**
 * ubo bind = 1 ==> 
 * ubo bind = 2 ==> 
 * ubo bind = 3 ==> Camera
 * ubo bind = 4 ==> Sphere
 * ubo bind = 5 ==> Light
 */

layout (local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(rgba32f, binding = 2) uniform image2D imgOutput;

layout(std140, binding = 3) uniform Camera {
    vec3 position;
    mat4 rotationMatrix;
    vec2 resolution;
    float fov;
};

layout(std140, binding = 4) uniform Sphere {
    float radius;
    vec3 position;
    vec3 color;
};

layout(std140, binding = 5) uniform Light {
    float intensity;
    vec3 position;
    vec3 color;
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