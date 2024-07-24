#version 460 core

/*
    Binding n°      associated block
        0                 time
        1             SceneInfoBlock
        2               imgOutput
        3              CameraBlock
        4              SpheresBlock
        5              LightsBlock
        6             MaterialsBlock          
*/

struct Material {
    vec3 color;
    vec3 baseReflectance;
    vec3 albedoMesh;
    vec3 emssitivityMesh;
    int id;
    float roughness;
    float metalness;
};

struct Camera {
    vec3 position;
    vec2 resolution;
    float fov_x_dist;
    float iso;
};

struct Light {
    vec3 position;
    vec3 color;
    float intensity;
};

struct Sphere {
    vec3 position;
    int materialId;
    float radius;
};

struct SceneInfo {
    int nbLights;
    int nbSpheres;
    int nbMaterials;
};

layout (local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(rgba32f, binding = 2) uniform image2D imgOutput;

layout(std140, binding = 3) uniform CameraBlock {
    Camera camera;
};

layout(std140, binding = 1) uniform SceneInfoBlock {
    SceneInfo sceneInfo;
};

layout(std430, binding = 4) buffer SpheresBlock {
    Sphere spheres[];
};

layout(std430, binding = 5) buffer LightsBlock {
    Light lights[];
};

layout(std430, binding = 6) buffer MaterialsBlock {
    Material materials[];
};

layout (location = 0) uniform float t;                 /** Time */

float square(float x){
    return x * x;
}

vec3 genLocalRayVector(){
    vec3 rayVector;
    rayVector.yz = gl_GlobalInvocationID.xy;

    rayVector.x = camera.fov_x_dist;

    rayVector.yz = rayVector.yz - (camera.resolution / 2.f);

    rayVector = normalize(rayVector);

    return rayVector;
}

float calculateSphereIntersection(vec3 rayVector, vec3 rayOrigin, int sphereId){
    Sphere sphere = spheres[sphereId];
    vec3 L = rayOrigin - sphere.position;
    float b = 2.0 * dot(rayVector, L);
    float c = dot(L, L) - (sphere.radius * sphere.radius);

    float discriminant = (b * b) - 4.0 * c;
    float sqrtDiscriminant = sqrt(discriminant);

    float t1 = (-b + sqrtDiscriminant) / 2.0;
    float t2 = (-b - sqrtDiscriminant) / 2.0;

    float T = -1.f;
    T = (t1 > 0.f && t2 <= 0.f) ? t1 : T;
    T = (t1 <= 0.f && t2 > 0.f) ? t2 : T;
    T = ((t1 > 0.f && t2 > 0.f) && (t1 < t2)) ? t1 : T;
    T = ((t1 > 0.f && t2 > 0.f) && (t1 >= t2)) ? t2 : T;

    return T;
}

vec3 calculateIllumination(int sphereId, vec3 positionIntersection){
    vec3 normalVec = normalize(positionIntersection - spheres[sphereId].position);
    vec3 returnVal = vec3(0.f, 0.f, 0.f);

    for(int lightId_ = 0; lightId_ < sceneInfo.nbLights; lightId_++){
        bool hasIntersections = false;
        Light currentLight = lights[lightId_];
        vec3 lightVec = currentLight.position - positionIntersection;
        vec3 lightVecN = normalize(currentLight.position - positionIntersection);

        for(int sphereId_ = 0; sphereId_ < sceneInfo.nbSpheres; sphereId_++){
            Sphere currentSphere = spheres[sphereId_];
            vec3 contactPos = positionIntersection;
            float intersect = calculateSphereIntersection(lightVecN, contactPos, sphereId_);
            // hasIntersections = ((true) && ((intersect <= 0.f) || (intersect >= dot(lightVecN, lightVec)))) ? hasIntersections : true;
            hasIntersections = ((sphereId_ != sphereId) && ((intersect > 0.001) && (intersect < dot(lightVecN, lightVec)))) ? true : hasIntersections;
            
        }
        returnVal = (!hasIntersections) ? returnVal + (dot(lightVecN, normalVec) * currentLight.color * currentLight.intensity * camera.iso / dot(lightVec, lightVec)): returnVal;
    }
    return returnVal;
}

void main() {
    ivec2 texelCoord = ivec2(gl_GlobalInvocationID.xy);

    int idSphere = -1;
    float dist = -1.0;

    float r = 3.f;
    lights[0].position = vec3(4.f + r * cos(t), r*sin(t), 0.f);

    vec3 position = camera.position;

    vec3 localRayCam = genLocalRayVector();

    for (int i = 0; i < sceneInfo.nbSpheres; i++) {
        float distSpherei = calculateSphereIntersection(localRayCam, position, i);
        
        bool update = (distSpherei >= 0.0) && (dist < 0.0 || distSpherei < dist);
        
        dist = update ? distSpherei : dist;
        idSphere = update ? i : idSphere;
    }

    vec3 illumination = (dist >= 0.f) ? calculateIllumination(idSphere, dist * localRayCam + position) : vec3(0.f, 0.f, 0.f);
    // vec3 illumination = vec3(1.f, 1.f, 1.f);

    Sphere currentSphere = spheres[idSphere];
    Material currentMat = materials[currentSphere.materialId];

    vec4 value = (dist < 0.0) ? vec4(0.1, 0.1, 0.1, 1.0) : vec4(currentMat.color * illumination, 1.0);
    // value = vec4(dist / 15, 0.f, 0.f, 0.f);

    imageStore(imgOutput, texelCoord, value);
}

