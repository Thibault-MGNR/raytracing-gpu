#include "raytracing/light.hpp"

Light::Light(){

}

// ------------------------------------------------------------------------

void Light::init(const LightData& data){
    _data = data;
    _ubo.init<LightData>(&_data, 5);
}