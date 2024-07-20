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
    float cameraFov_x_dist;
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

// struct SceneInfo {
//     int nbLights;
//     int nbSpheres;
// };

layout (local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(rgba32f, binding = 2) uniform image2D imgOutput;

layout(std140, binding = 3) uniform CameraBlock {
    vec3 cameraPosition;
    vec2 cameraResolution;
    float cameraFov_x_dist;
};

layout(std140, binding = 1) uniform SceneInfoBlock {
    int nbLights;
    int nbSpheres;
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

    rayVector.x = cameraFov_x_dist;

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

    float T = min(validT1, validT2);
    T = mix(T, max(validT1, validT2), step(0.0, T)); 
    
    return mix(-1.0, T, step(0.0, discriminant));
}

void main() {
    ivec2 texelCoord = ivec2(gl_GlobalInvocationID.xy);

    int idSphere = -1;
    float dist = -1.0;

    vec3 localRayCam = genLocalRayVector();

    for (int i = 0; i < nbSpheres; i++) {
        float distSpherei = calculateSphereIntersection(localRayCam, cameraPosition, sphere[i].spherePosition, sphere[i].sphereRadius);
        
        bool update = (distSpherei >= 0.0) && (dist < 0.0 || distSpherei < dist);
        
        dist = update ? distSpherei : dist;
        idSphere = update ? i : idSphere;
    }

    vec4 value = (dist < 0.0) ? vec4(0.0, 0.0, 1.0, 1.0) : vec4(sphere[idSphere].sphereColor, 1.0);

    imageStore(imgOutput, texelCoord, value);
}

