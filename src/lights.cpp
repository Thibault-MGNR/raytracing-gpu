#include "raytracing/lights.hpp"

Lights::Lights(){
    _ssbo.setUsage(GL_STATIC_COPY);
}

// ------------------------------------------------------------------------

void Lights::add(const LightData data){
    _data.push_back(data);
}

// ------------------------------------------------------------------------

void Lights::send(){
    _ssbo.init<LightData>(_data, 5);
}