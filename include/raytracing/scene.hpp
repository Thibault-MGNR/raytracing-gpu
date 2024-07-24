#pragma once

#include <GPGPU/UBO.hpp>
#include <glm/glm.hpp>

#include "raytracing/spheres.hpp"
#include "raytracing/lights.hpp"
#include "raytracing/camera.hpp"
#include "raytracing/materials.hpp"

class Scene{
    public:
        Scene();
        void init();
        void send();
        void add(const SphereData sphere);
        void add(const LightData light);
        void add(const MaterialData material);
        void initCamera(const CameraData camData);
    
    private:
        struct sceneInfo {
            int nbLights = 0;
            int nbSpheres = 0;
            int nbMaterials = 0;
            float padding;
        };

        UBO _ubo;
        sceneInfo _sceneInfo;
        Spheres _sphereManager;
        Lights _lightManager;
        Materials _materialsManager;
        Camera _camera;
        CameraData _camData;
};