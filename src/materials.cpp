#include "raytracing/materials.hpp"

Materials::Materials(){
    _ssbo.setUsage(GL_STATIC_COPY);
}

// ------------------------------------------------------------------------

// void Materials::init(){
//     _ssbo.setUsage(GL_STATIC_COPY);
// }

// ------------------------------------------------------------------------

void Materials::add(const MaterialData data){
    _MaterialsTabDatas.push_back(data);
}

// ------------------------------------------------------------------------

void Materials::send(){
    _ssbo.init<MaterialData>(_MaterialsTabDatas, 6);
}