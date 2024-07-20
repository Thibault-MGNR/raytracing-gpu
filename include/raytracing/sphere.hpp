#pragma once

#include <glm/glm.hpp>
#include <GPGPU/UBO.hpp>

struct SphereData {
    glm::vec3 position;
    alignas(16) glm::vec3 color;
    float radius;
};

class Sphere {
    public:
        Sphere();

        void init(const SphereData& data);
    
    private:
        SphereData _data;
        UBO _ubo;
};