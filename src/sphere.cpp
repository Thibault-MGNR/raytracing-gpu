#include "raytracing/sphere.hpp"

Sphere::Sphere(){

}

// ------------------------------------------------------------------------

void Sphere::init(const SphereData& data){
    _data = data;
    _ubo.init<SphereData>(&_data, 4);
}