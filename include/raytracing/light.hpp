#pragma once

#include <glm/glm.hpp>
#include <GPGPU/UBO.hpp>

struct LightData {
    float intensity;
    glm::vec3 position;
    glm::vec3 color;
};

class Light {
    public:
        Light();

        void init(const LightData& data);
    
    private:
        LightData _data;
        UBO _ubo;
};