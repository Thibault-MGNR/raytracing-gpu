#pragma once

#include <glm/glm.hpp>
#include <vector>
#include <GPGPU/SSBO.hpp>

struct MaterialData {
    glm::vec3 color;
    alignas(16) glm::vec3 baseReflectance;
    alignas(16) glm::vec3 albedoMesh;
    alignas(16) glm::vec3 emssitivityMesh;
    int id;
    float roughness;
    float metalness;
};

class Materials {
    public:
        Materials();
        void add(const MaterialData data);
        void send();
    
    private:
        SSBO _ssbo;
        std::vector<MaterialData> _MaterialsTabDatas;
};