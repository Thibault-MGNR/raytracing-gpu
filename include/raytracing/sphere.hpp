#pragma once

#include <glm/glm.hpp>
#include <GPGPU/UBO.hpp>

struct SphereData {
    float radius;
    glm::vec3 position;
    glm::vec3 color;
};

class Sphere {
    public:
        Sphere();

        void init(const SphereData& data);
    
    private:
        SphereData _data;
        UBO _ubo;
};