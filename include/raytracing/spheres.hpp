#pragma once

#include <GPGPU/SSBO.hpp>
#include <vector>

#include "raytracing/sphere.hpp"

class Spheres {
    public:
        Spheres();
        void add(const SphereData data);
        void send();
    
    private:
        std::vector<SphereData> _data;
        SSBO _ssbo;
};