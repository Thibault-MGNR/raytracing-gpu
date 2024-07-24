#pragma once

#include <glm/glm.hpp>

struct SphereData {
    glm::vec3 position;
    int materialId;
    float radius;
    glm::vec3 padding;
};