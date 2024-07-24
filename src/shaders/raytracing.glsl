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

#define PI 3.14159265359

// ------------------------------------------------------------------------

float square(float x){
    return x * x;
}

// ------------------------------------------------------------------------

vec3 genLocalRayVector(){
    vec3 rayVector;
    rayVector.yz = gl_GlobalInvocationID.xy;

    rayVector.x = camera.fov_x_dist;

    rayVector.yz = rayVector.yz - (camera.resolution / 2.f);

    rayVector = normalize(rayVector);

    return rayVector;
}

// ------------------------------------------------------------------------

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

// ------------------------------------------------------------------------

float DistributionGGX(vec3 N, vec3 H, float roughness)
{
    float a = roughness*roughness;
    float a2 = a*a;
    float NdotH = max(dot(N, H), 0.0);
    float NdotH2 = NdotH*NdotH;

    float nom   = a2;
    float denom = (NdotH2 * (a2 - 1.0) + 1.0);
    denom = PI * denom * denom;

    return nom / denom;
}

float DistributionAnisotropic()

// ------------------------------------------------------------------------

float GeometrySchlickGGX(float NdotV, float roughness)
{
    float r = (roughness + 1.0);
    float k = (r*r) / 8.0;

    float nom   = NdotV;
    float denom = NdotV * (1.0 - k) + k;

    return nom / denom;
}

// ------------------------------------------------------------------------

float GeometrySmith(vec3 N, vec3 V, vec3 L, float roughness)
{
    float NdotV = max(dot(N, V), 0.0);
    float NdotL = max(dot(N, L), 0.0);
    float ggx2 = GeometrySchlickGGX(NdotV, roughness);
    float ggx1 = GeometrySchlickGGX(NdotL, roughness);

    return ggx1 * ggx2;
}

// ------------------------------------------------------------------------

vec3 fresnelSchlick(float cosTheta, vec3 F0)
{
    return F0 + (1.0 - F0) * pow(clamp(1.0 - cosTheta, 0.0, 1.0), 5.0);
}

// ------------------------------------------------------------------------

vec3 calculateIllumination(int sphereId, vec3 positionIntersection, vec3 V, float dist){
    vec3 normalVec = normalize(positionIntersection - spheres[sphereId].position);
    vec3 returnVal = vec3(0.f, 0.f, 0.f);
    Material currentMaterial = materials[spheres[sphereId].materialId];
    vec3 F0 = vec3(0.04); 
    F0 = mix(F0, currentMaterial.color, currentMaterial.metalness);
    vec3 Lo = vec3(0.0);

    for(int lightId_ = 0; lightId_ < sceneInfo.nbLights; lightId_++){
        bool hasIntersections = false;
        Light currentLight = lights[lightId_];
        vec3 lightVec = currentLight.position - positionIntersection;
        vec3 lightVecN = normalize(currentLight.position - positionIntersection);

        for(int sphereId_ = 0; sphereId_ < sceneInfo.nbSpheres; sphereId_++){
            Sphere currentSphere = spheres[sphereId_];
            vec3 contactPos = positionIntersection;
            float intersect = calculateSphereIntersection(lightVecN, contactPos, sphereId_);
            bool correctSphere = sphereId_ != sphereId;
            bool minIntersect = intersect > 0.001;
            bool maxIntersect = intersect < dot(lightVecN, lightVec);
            hasIntersections = ((correctSphere) && ((minIntersect) && (maxIntersect))) ? true : hasIntersections;
            
        }

        // -----------------------------------------------------------------
    
        vec3 H = normalize(V + lightVecN);
        vec3 lightDistance = currentLight.position - positionIntersection;
        float attenuation = 1.0 / dot(lightDistance, lightDistance);
        vec3 radiance = currentLight.color * attenuation;

        float NDF = DistributionGGX(normalVec, H, currentMaterial.roughness);   
        float G   = GeometrySmith(normalVec, V, lightVecN, currentMaterial.roughness);      
        vec3 F    = fresnelSchlick(clamp(dot(H, V), 0.0, 1.0), F0);
        
        vec3 numerator    = NDF * G * F; 
        float denominator = 4.0 * max(dot(normalVec, V), 0.0) * max(dot(normalVec, lightVecN), 0.0) + 0.0001;
        vec3 specular = numerator / denominator;

        vec3 kS = F;
        vec3 kD = vec3(1.0) - kS;
        kD *= 1.0 - currentMaterial.metalness;	  

        float NdotL = max(dot(normalVec, lightVecN), 0.0);       

        Lo = (!hasIntersections) ? Lo + (kD * currentMaterial.color / PI + specular) * radiance * NdotL : Lo;
        
        // vec3 ambient = vec3(0.03) * albedo * ao;
    }
    
    return Lo;
}

// ------------------------------------------------------------------------

void main() {
    ivec2 texelCoord = ivec2(gl_GlobalInvocationID.xy);

    int idSphere = -1;
    float dist = -1.0;

    float r = 3.f;
    lights[0].position = vec3(4.f + r * cos(t), r*sin(t), 0.f);

    vec3 localRayCam = genLocalRayVector();

    for (int i = 0; i < sceneInfo.nbSpheres; i++) {
        float distSpherei = calculateSphereIntersection(localRayCam, camera.position, i);
        
        bool update = (distSpherei >= 0.0) && (dist < 0.0 || distSpherei < dist);
        
        dist = update ? distSpherei : dist;
        idSphere = update ? i : idSphere;
    }
    vec3 illumination = (dist >= 0.f) ? calculateIllumination(idSphere, dist * localRayCam + camera.position, -localRayCam, dist) : vec3(0.f, 0.f, 0.f);

    Sphere currentSphere = spheres[idSphere];
    Material currentMat = materials[currentSphere.materialId];

    vec3 ambient = vec3(0.03) * currentMat.color * 1.0;
    vec3 color = ambient + illumination;

    color = color / (color + vec3(1.0));
    // color = pow(color, vec3(1.0/2.2)); 

    vec4 value = (dist < 0.0) ? vec4(0.1, 0.1, 0.1, 1.0) : vec4(color, 1.0);

    imageStore(imgOutput, texelCoord, value);
}

