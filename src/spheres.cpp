#include "raytracing/spheres.hpp"

#include <iostream>

Spheres::Spheres(){
    _ssbo.setUsage(GL_STATIC_COPY);
}

// ------------------------------------------------------------------------

void Spheres::add(const SphereData data){
    _data.push_back(data);
}

// ------------------------------------------------------------------------

void Spheres::send(){
    _ssbo.init<SphereData>(_data, 4);
}