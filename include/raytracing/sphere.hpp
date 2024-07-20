#pragma once

#include <glm/glm.hpp>

struct SphereData {
    glm::vec3 position;
    alignas(16) glm::vec3 color;
    float radius;
};