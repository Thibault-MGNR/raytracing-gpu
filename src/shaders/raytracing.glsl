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

struct CollisionInfo {
    int idSphere;
    float dist;
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

#define PI 3.14159265359
#define MAX_BOUNCES 3
#define antiAliasedSamples 3

// ------------------------------------------------------------------------

float square(float x){
    return x * x;
}

// ------------------------------------------------------------------------

vec2 generateJitter(int sampleIndex){
    vec2 jitter;

    jitter.x = (float(sampleIndex % antiAliasedSamples) + 0.5) / float(antiAliasedSamples) - 0.5;
    jitter.y = (float(sampleIndex / antiAliasedSamples) + 0.5) / float(antiAliasedSamples) - 0.5;

    return jitter;
}

// ------------------------------------------------------------------------

vec3 genLocalRayVector(int n){
    vec3 rayVector;
    rayVector.yz = gl_GlobalInvocationID.xy;

    rayVector.x = camera.fov_x_dist;

    rayVector.yz = rayVector.yz - (camera.resolution / 2.f) + generateJitter(n);

    rayVector = normalize(rayVector);

    return rayVector;
}

// ------------------------------------------------------------------------

float calculateSphereIntersection(vec3 rayVector, vec3 rayOrigin, int sphereId){
    Sphere sphere = spheres[sphereId];
    vec3 L = rayOrigin - sphere.position;
    float b = 2.f * dot(rayVector, L);
    float c = dot(L, L) - (sphere.radius * sphere.radius);

    float discriminant = (b * b) - 4.f * c;
    float sqrtDiscriminant = sqrt(discriminant);

    float t1 = (-b + sqrtDiscriminant) / 2.f;
    float t2 = (-b - sqrtDiscriminant) / 2.f;

    float T = -1.f;
    T = (t1 > 0.f && t2 <= 0.f) ? t1 : T;
    T = (t1 <= 0.f && t2 > 0.f) ? t2 : T;
    T = ((t1 > 0.f && t2 > 0.f) && (t1 < t2)) ? t1 : T;
    T = ((t1 > 0.f && t2 > 0.f) && (t1 >= t2)) ? t2 : T;

    return T;
}

// ------------------------------------------------------------------------

CollisionInfo nextCollision(vec3 ray, vec3 rayInitPosition){
    CollisionInfo data;
    data.idSphere = -1;
    data.dist = -1.f;

    for (int i = 0; i < sceneInfo.nbSpheres; i++) {
        float distSpherei = calculateSphereIntersection(ray, rayInitPosition, i);
        
        bool update = (distSpherei >= 0.f) && (data.dist < 0.f || distSpherei < data.dist);
        
        data.dist = update ? distSpherei : data.dist;
        data.idSphere = update ? i : data.idSphere;
    }

    return data;
}

// ------------------------------------------------------------------------

float DistributionGGX(vec3 N, vec3 H, float roughness){
    float a = roughness*roughness;
    float a2 = a*a;
    float NdotH = max(dot(N, H), 0.f);
    float NdotH2 = NdotH*NdotH;

    float nom   = a2;
    float denom = (NdotH2 * (a2 - 1.f) + 1.f);
    denom = PI * denom * denom;

    return nom / denom;
}

// ------------------------------------------------------------------------

float GeometrySchlickGGX(float NdotV, float roughness){
    float r = (roughness + 1.f);
    float k = (r*r) / 8.f;

    float nom   = NdotV;
    float denom = NdotV * (1.f - k) + k;

    return nom / denom;
}

// ------------------------------------------------------------------------

float GeometrySmith(vec3 N, vec3 V, vec3 L, float roughness){
    float NdotV = max(dot(N, V), 0.f);
    float NdotL = max(dot(N, L), 0.f);
    float ggx2 = GeometrySchlickGGX(NdotV, roughness);
    float ggx1 = GeometrySchlickGGX(NdotL, roughness);

    return ggx1 * ggx2;
}

// ------------------------------------------------------------------------

vec3 fresnelSchlick(float cosTheta, vec3 F0){
    return F0 + (1.f - F0) * pow(clamp(1.f - cosTheta, 0.f, 1.f), 5.f);
}

// ------------------------------------------------------------------------

vec3 PBR(vec3 viewDirection, vec3 normalVec, vec3 lightVecN, vec3 radiance, Material currentMaterial){
    vec3 F0 = vec3(0.04); 
    F0 = mix(F0, currentMaterial.color, currentMaterial.metalness);

    vec3 H = normalize(viewDirection + lightVecN);

    float NDF = DistributionGGX(normalVec, H, currentMaterial.roughness);   
    float G   = GeometrySmith(normalVec, viewDirection, lightVecN, currentMaterial.roughness);      
    vec3 F    = fresnelSchlick(clamp(dot(H, viewDirection), 0.f, 1.f), F0);
    
    vec3 numerator    = NDF * G * F; 
    float denominator = 4.f * max(dot(normalVec, viewDirection), 0.f) * max(dot(normalVec, lightVecN), 0.f) + 0.0001;
    vec3 specular = numerator / denominator;

    vec3 kS = F;
    vec3 kD = vec3(1.f) - kS;
    kD *= 1.f - currentMaterial.metalness;	  

    float NdotL = max(dot(normalVec, lightVecN), 0.f);  

    return (kD * currentMaterial.color / PI + specular) * radiance * NdotL;
}

// ------------------------------------------------------------------------

vec3 calculateSurfaceNormal(int sphereId, vec3 intersectionPosition) {
    return normalize(intersectionPosition - spheres[sphereId].position);
}

// ------------------------------------------------------------------------

bool isShadowed(vec3 intersectionPosition, vec3 lightDirection, vec3 lightVector, int currentSphereId) {
    for (int otherSphereId = 0; otherSphereId < sceneInfo.nbSpheres; ++otherSphereId) {
        if (otherSphereId == currentSphereId) continue;

        float intersectionDistance = calculateSphereIntersection(lightDirection, intersectionPosition, otherSphereId);
        if (intersectionDistance > 0.001 && intersectionDistance < dot(lightDirection, lightVector) + 0.001) {
            return true;
        }
    }
    return false;
}

// ------------------------------------------------------------------------

float calculateAttenuation(vec3 lightVector) {
    float lightDistanceSquared = dot(lightVector, lightVector);
    return 1.f / lightDistanceSquared;
}

// ------------------------------------------------------------------------

vec3 calculateIllumination(int sphereId, vec3 intersectionPosition, vec3 viewDirection) {
    vec3 surfaceNormal = calculateSurfaceNormal(sphereId, intersectionPosition);
    Material currentMaterial = materials[spheres[sphereId].materialId];
    vec3 totalIllumination = vec3(0.f);

    for (int lightId = 0; lightId < sceneInfo.nbLights; ++lightId) {
        Light currentLight = lights[lightId];
        vec3 lightDirection = normalize(currentLight.position - intersectionPosition);
        vec3 lightVector = currentLight.position - intersectionPosition;

        if (!isShadowed(intersectionPosition, lightDirection, lightVector, sphereId)) {
            float attenuation = calculateAttenuation(lightVector);
            vec3 radiance = currentLight.color * attenuation;
            vec3 pbrColor = PBR(viewDirection, surfaceNormal, lightDirection, radiance, currentMaterial);
            totalIllumination += pbrColor;
        }
    }

    return totalIllumination + vec3(0.03) * currentMaterial.color;
}

// ------------------------------------------------------------------------

void updateLightPositions() {
    float r = 5.f;
    lights[0].position = vec3(4.f + r * cos(t), r * sin(t), 0.7 * cos(2.f * t));
    lights[1].position = vec3(4.f + r * cos(-0.7 * t), r * sin(-0.7 * t), 0.7 * cos(1.5 * t));
}

// ------------------------------------------------------------------------

vec3 calculateSampleIllumination(CollisionInfo collision, vec3 localRayCam, float coef) {
    if (collision.dist < 0.f) {
        return vec3(0.f);
    }

    vec3 positionIntersection = collision.dist * localRayCam + camera.position;
    vec3 normalVec = normalize(positionIntersection - spheres[collision.idSphere].position);
    positionIntersection += normalVec * coef;

    vec3 illumination = calculateIllumination(collision.idSphere, positionIntersection, -localRayCam);
    return illumination / (illumination + vec3(1.f));
}

// ------------------------------------------------------------------------

vec4 processIllumination(CollisionInfo collision, vec3 illumination) {
    return (collision.dist < 0.f) ? vec4(0.1, 0.1, 0.1, 1.f) : vec4(illumination, 1.f);
}

// ------------------------------------------------------------------------

void storeImageResult(writeonly image2D imgOutput, ivec2 texelCoord, vec4 accumulatedValue, int samples) {
    imageStore(imgOutput, texelCoord, accumulatedValue / float(samples * samples));
}

// ------------------------------------------------------------------------

void main() {
    vec4 accumulatedValue = vec4(0.f);
    float coef = 0.001f;
    ivec2 texelCoord = ivec2(gl_GlobalInvocationID.xy);

    updateLightPositions();

    for (int i = 0; i < antiAliasedSamples * antiAliasedSamples; i++) {
        vec3 localRayCam = genLocalRayVector(i);
        CollisionInfo collision = nextCollision(localRayCam, camera.position);

        vec3 illumination = calculateSampleIllumination(collision, localRayCam, coef);
        accumulatedValue += processIllumination(collision, illumination);
    }

    storeImageResult(imgOutput, texelCoord, accumulatedValue, antiAliasedSamples);
}

