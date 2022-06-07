using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace Postproccess
{
    internal sealed class CustomPostProcessPass : ScriptableRenderPass
    {
        private readonly UniversalRendererData rendererData;
        private RTHandle renderResult;
        private readonly string name;
        private readonly Material material;

        public CustomPostProcessPass(UniversalRendererData universalRendererData, Material postProcessMaterial, string passName = "Custom Post-Process")
        {
            material = postProcessMaterial;
            rendererData = universalRendererData;
            name = passName;
        }

        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {
            /*TODO: For some reason right now we can't get accesses for render target in Deferred rendering mode.
          Need update URP or wait when Unity open GBufferLights buffers for everyone (now it is internal)*/
            if(rendererData.renderingMode != RenderingMode.Forward)
                return;

            renderResult = renderingData.cameraData.renderer.cameraColorTargetHandle;
            renderingData.cameraData.cameraTargetDescriptor.depthBufferBits = 0;
        }


        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            var commandList = CommandBufferPool.Get(name);
            using var profiler = new ProfilingScope(commandList, new ProfilingSampler(name));
        
            commandList.Blit(renderResult.rt, renderResult.nameID, material);
        
            context.ExecuteCommandBuffer(commandList);
            CommandBufferPool.Release(commandList);
        }
    }
}