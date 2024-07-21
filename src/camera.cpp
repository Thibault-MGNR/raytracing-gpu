#include "raytracing/camera.hpp"

#include <numbers>

static float radians(float x){
    return (x * std::numbers::pi_v<float>) / 180.f;
}

Camera::Camera(){
    _newData = false;
    _ubo.setUsage(GL_STATIC_COPY);
}

// ------------------------------------------------------------------------

void Camera::init(const CameraData data){
    _data = data;
    transformDataForGPU();
    _ubo.init<GPUCamData>(&_GPUData, 3);
}

// ------------------------------------------------------------------------

void Camera::rotation(glm::vec3& rotation){
    _data.orientation = glm::quat(rotation) * _data.orientation;
    _newData = true;
}

// ------------------------------------------------------------------------

void Camera::turnAroundPoint(glm::vec3& rotation, glm::vec3& pointPosition){
    _newData = true;
    return;
}

// ------------------------------------------------------------------------

void Camera::translation(glm::vec3& translation){
    _newData = true;
    _data.position += translation;
}

// ------------------------------------------------------------------------

void Camera::transformDataForGPU(){
    _GPUData.fovDist = (_data.resolution[0] / 2.f) / tan(radians(_data.fov/2.f));
    _GPUData.position = _data.position;
    _GPUData.resolution = _data.resolution;
    _GPUData.iso = _data.iso;

    // _GPUData.rotationMatrix = glm::toMat4(_data.orientation);
}

// ------------------------------------------------------------------------

void Camera::updateGPUData(){
    if(_newData){
        transformDataForGPU();
        _ubo.subData(0, sizeof(GPUCamData), &_GPUData);
        _newData = false;
    }
}