#pragma once

#include <glm/glm.hpp>
#include <GPGPU/UBO.hpp>

struct SphereData {
    glm::vec3 position;
    float padding0;
    glm::vec3 color;
    float padding1;
    float radius;
    glm::vec3 padding2;
};

class Sphere {
    public:
        Sphere();

        void init(const SphereData& data);
    
    private:
        SphereData _data;
        UBO _ubo;
};