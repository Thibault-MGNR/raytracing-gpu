#pragma once

#include <GPGPU/SSBO.hpp>
#include <vector>

#include "raytracing/light.hpp"

class Lights {
    public:
        Lights();

        void add(const LightData data);
        void send();
    
    private:
        std::vector<LightData> _data;
        SSBO _ssbo;
};