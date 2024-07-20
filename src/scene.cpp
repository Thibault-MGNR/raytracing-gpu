#include "raytracing/scene.hpp"

Scene::Scene(){
    _ubo.setUsage(GL_STATIC_COPY);
}

void Scene::init(){
    _ubo.init<sceneInfo>(&_sceneInfo, 1);
}

// ------------------------------------------------------------------------

void Scene::send(){
    std::cout << GL_UNIFORM_BUFFER_OFFSET_ALIGNMENT << std::endl;
    _ubo.subData(0, sizeof(sceneInfo), &_sceneInfo);
    _sphereManager.send();
    _lightManager.send();
}

// ------------------------------------------------------------------------

void Scene::add(const SphereData sphereData){
    _sceneInfo.nbSpheres++;
    _sphereManager.add(sphereData);
}

// ------------------------------------------------------------------------

void Scene::add(const LightData light){
    _sceneInfo.nbLights++;
    _lightManager.add(light);
}

// ------------------------------------------------------------------------

void Scene::initCamera(const CameraData camData){
    _camData = camData;
    _camera.init(_camData);
}