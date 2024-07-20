#version 460 core

/*
    Binding n°      associated block
        0                 time
        1               
        2               imgOutput
        3              CameraBlock
        4              SpheresBlock
        5              LightsBlock
        6                           
*/

struct Camera {
    vec3 cameraPosition;
    vec2 cameraResolution;
    float cameraFov;
};

struct Light {
    vec3 lightPosition;
    vec3 lightColor;
    float lightIntensity;
};

struct Sphere {
    vec3 spherePosition;
    vec3 sphereColor;
    float sphereRadius;
};

struct SceneInfo {
    int nbLights;
    int nbSpheres;
};

layout (local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(rgba32f, binding = 2) uniform image2D imgOutput;

layout(std140, binding = 3) uniform CameraBlock {
    vec3 cameraPosition;
    vec2 cameraResolution;
    float cameraFov;
};

layout(std140, binding = 1) uniform SceneInfoBlock {
    SceneInfo sceneInfo;
};

layout(std430, binding = 4) buffer SpheresBlock {
    Sphere sphere[];
};

layout(std430, binding = 5) buffer LightsBlock {
    Light lights[];
};

layout (location = 0) uniform float t;                 /** Time */

float square(float x){
    return x * x;
}

vec3 genLocalRayVector(){
    vec3 rayVector;
    rayVector.yz = gl_GlobalInvocationID.xy;

    rayVector.x = (cameraResolution.x / 2.f) / (tan(radians(cameraFov/2.f)));

    rayVector.yz = rayVector.yz - (cameraResolution / 2.f);

    rayVector = normalize(rayVector);

    return rayVector;
}

float calculateSphereIntersection(vec3 rayVector, vec3 rayOrigin, vec3 spherePosition, float radius){
    vec3 L = spherePosition - rayOrigin;
    float b = 2.0 * dot(L, rayVector);
    float c = dot(L, L) - (radius * radius);

    float discriminant = (b * b) - 4.0 * c;
    float sqrtDiscriminant = sqrt(discriminant);

    float t1 = (-b + sqrtDiscriminant) / 2.0;
    float t2 = (-b - sqrtDiscriminant) / 2.0;

    float validT1 = step(0.0, t1) * t1;
    float validT2 = step(0.0, t2) * t2;

    float t = min(validT1, validT2);
    t = mix(t, max(validT1, validT2), step(0.0, t)); 
    
    return mix(-1.0, t, step(0.0, discriminant));
}

void main() {
    ivec2 texelCoord = ivec2(gl_GlobalInvocationID.xy);

    float rad_ = sphere[0].sphereRadius + 0.5*sin(t);

    float dist = calculateSphereIntersection(genLocalRayVector(), cameraPosition, sphere[0].spherePosition, rad_);

    vec4 value = vec4(dist/10, 0.0, 0.0, 1.0);

    imageStore(imgOutput, texelCoord, value);
}