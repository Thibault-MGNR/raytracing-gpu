#pragma once
#include <glm/glm.hpp>
#include <glm/gtc/quaternion.hpp>

#include <GPGPU/UBO.hpp>

struct CameraData {
    glm::vec3 position;
    glm::quat orientation;
    glm::vec2 resolution;
    float fov = 90.f;
    float iso = 200.f;
};

struct GPUCamData {
    glm::vec3 position;
    alignas(16) glm::vec2 resolution;
    float fovDist;
    float iso;
};

class Camera {
    public:
        Camera();
        void init(const CameraData data);
        void rotation(glm::vec3& rotation);
        void turnAroundPoint(glm::vec3& rotation, glm::vec3& pointPosition);
        void translation(glm::vec3& translation);
        void updateGPUData();
    
    private:
        void transformDataForGPU();
        CameraData _data;
        GPUCamData _GPUData;
        UBO _ubo;
        bool _newData;
};