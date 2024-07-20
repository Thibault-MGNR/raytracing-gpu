#include "raytracing/camera.hpp"

#include <iostream>

Camera::Camera(){
    _newData = false;
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
    _GPUData.fov = _data.fov;
    _GPUData.position = _data.position;
    _GPUData.resolution = _data.resolution;

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