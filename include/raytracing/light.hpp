#pragma once

#include <glm/glm.hpp>
#include <GPGPU/UBO.hpp>

struct LightData {
    glm::vec3 position;
    alignas(16) glm::vec3 color;
    alignas(16) glm::vec3 padding3;
    alignas(16) float intensity;
};

class Light {
    public:
        Light();

        void init(const LightData& data);
    
    private:
        LightData _data;
        UBO _ubo;
};