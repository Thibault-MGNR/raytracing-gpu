#pragma once

#include <glm/glm.hpp>
#include <GPGPU/UBO.hpp>

struct LightData {
    glm::vec3 position;
    float padding1;
    glm::vec3 color;
    float padding2;
    float intensity;
    glm::vec3 padding3;
};

class Light {
    public:
        Light();

        void init(const LightData& data);
    
    private:
        LightData _data;
        UBO _ubo;
};