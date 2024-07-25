#include <GPGPU/GPGPU.hpp>
#include <filesystem>
#include <cstddef>
#include <vector>

#include <numbers>

#include "raytracing/scene.hpp"

class App: public GPGPU {
	public:
		void init(){
			setRenderView({1000.f, 1000.f}, 2);

			initGPGPU();
			_cs.init("../src/shaders/raytracing.glsl");
		}

	private:
		virtual void beforeRun() override {
			_scene.init();
			float squareEdge = 10.f;
			float sphereRad = 1000.f;
			
			CameraData camData;
			camData.position = {0.f, 0.f, 0.f};
			camData.orientation = glm::quat({0.f, 0.f, 0.f});
			camData.resolution = {1000.f, 1000.f};
			camData.fov = 90.f;
			camData.iso = 50.f;
			_scene.initCamera(camData);

			MaterialData mat;
			mat.color = {1.f, 0.f, 0.f};
			mat.id = 0;
			mat.roughness = 0.1;
			mat.metalness = 1.f;
			_scene.add(mat);

			mat.metalness = 0.f;
			mat.roughness = 1.f;
			mat.id = 1;
			mat.color = {1.f, 1.f, 1.f};
			_scene.add(mat);

			LightData l1;
			l1.intensity = 50;
			l1.color = {1.f, 1.f, 1.f};
			l1.color = l1.color * l1.intensity;
			l1.position = {1.f, 0.f, 1.f};
			_scene.add(l1);

			SphereData sd;
			sd.materialId = 0;
			sd.radius = 1.f;
			sd.position = {5.0, 0.f, 0.f};
			_scene.add(sd);

			sd.materialId = 1;
			sd.radius = 5000.f;
			sd.position = {5.0, 0.f, -5001.f};
			_scene.add(sd);

			sd.materialId = 1;
			sd.radius = 5000.f;
			sd.position = {5.0, 0.f, 5001.5};
			_scene.add(sd);

			_scene.send();
		}

		virtual void renderFrame() override {
			// _cam.updateGPUData();

			_cs.use();
			_cs.setFloat("t", _window.getTime());
			glDispatchCompute((unsigned int)1000/8, (unsigned int)1000/8, 1);

			glMemoryBarrier(GL_SHADER_IMAGE_ACCESS_BARRIER_BIT);
		}

		ComputeShader _cs;
		Scene _scene;
};		


int main()
{
	App app;
	app.init();

	app.run();

	return EXIT_SUCCESS;
}