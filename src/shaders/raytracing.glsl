#version 460 core

layout (local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(rgba32f, binding = 2) uniform image2D imgOutput;

layout(std140, binding = 3) uniform Camera {
    vec3 cameraPosition;
    // mat4 cameraRotationMatrix;
    vec2 cameraResolution;
    float cameraFov;
};

layout(std140, binding = 4) uniform Sphere {
    vec3 spherePosition;
    vec3 sphereColor;
    float sphereRadius;
};

layout(std140, binding = 5) uniform Light {
    vec3 lightPosition;
    vec3 lightColor;
    float lightIntensity;
};

layout (location = 0) uniform float t;                 /** Time */

vec3 genLocalRayVector(){
    vec3 rayVector;
    rayVector.yz = gl_GlobalInvocationID.xy;

    rayVector.x = (cameraResolution.x / 2.f) / (tan(radians(cameraFov/2.f)));

    rayVector.yz = rayVector.yz - (cameraResolution / 2.f);

    rayVector = normalize(rayVector);

    return rayVector;
}

void main() {
    vec4 value = vec4(1.0, 0.0, 0.0, 1.0);
    ivec2 texelCoord = ivec2(gl_GlobalInvocationID.xy);

    value.xyz = genLocalRayVector();
    // value.xyz = sphereColor;

    imageStore(imgOutput, texelCoord, value);
}