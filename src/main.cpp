#include <GPGPU/GPGPU.hpp>
#include <filesystem>
#include <cstddef>

class App: public GPGPU {
	public:
		void init(){
			setRenderView({1000.f, 1000.f}, 2);

			initGPGPU();
			_cs.init("../src/shaders/raytracing.glsl");
		}

	private:
		struct CameraData {
			glm::vec2 position;
		};


		virtual void beforeRun() override {
			_camData.position = {500.f, 500.f};

			// offsetof(CameraData, position);

			_ubo.init<CameraData>(&_camData, 1);
		}

		virtual void renderFrame() override {
			_camData.position = _window.getCurrentCursorPos();
			_ubo.subData(offsetof(CameraData, position), sizeof(glm::vec2), &_camData.position);
			_cs.use();
			_cs.setFloat("t", _window.getTime());
			glDispatchCompute((unsigned int)1000/8, (unsigned int)1000/8, 1);

			glMemoryBarrier(GL_SHADER_IMAGE_ACCESS_BARRIER_BIT);
		}

		ComputeShader _cs;
		CameraData _camData;
};

int main()
{
	App app;
	app.init();

	app.run();

	return EXIT_SUCCESS;
}