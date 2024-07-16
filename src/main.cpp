#include <GPGPU/GPGPU.hpp>
#include <filesystem>
#include <cstddef>
#include <vector>

#include "raytracing/camera.hpp"
#include "raytracing/light.hpp"
#include "raytracing/sphere.hpp"

class App: public GPGPU {
	public:
		void init(){
			setRenderView({1000.f, 1000.f}, 2);

			initGPGPU();
			_cs.init("../src/shaders/raytracing.glsl");
		}

	private:
		virtual void beforeRun() override {
			_camData.position = {0.f, 0.f, 0.f};
			_camData.orientation = glm::quat({0.f, 0.f, 0.f});
			_camData.resolution = {1000.f, 1000.f};
			_camData.fov = 90.f;
			_cam.init(_camData);

			LightData l1;
			l1.color = {255.f, 255.f, 255.f};
			l1.intensity = 200.f;
			l1.position = {5.f, 5.f, 5.f};
			_light.init(l1);

			SphereData sd;
			sd.color = {255.f, 0.f, 0.f};
			sd.radius = 1.f;
			sd.position = {5.f, 0.f, 0.f};

		}

		virtual void renderFrame() override {
			_cam.updateGPUData();

			_cs.use();
			_cs.setFloat("t", _window.getTime());
			glDispatchCompute((unsigned int)1000/8, (unsigned int)1000/8, 1);

			glMemoryBarrier(GL_SHADER_IMAGE_ACCESS_BARRIER_BIT);
		}

		ComputeShader _cs;
		CameraData _camData;
		Camera _cam;
		Light _light;
		Sphere _sphere;
};		


int main()
{
	App app;
	app.init();

	app.run();

	return EXIT_SUCCESS;
}