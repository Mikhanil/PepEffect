using UnityEngine;
using UnityEngine.Rendering.Universal;

namespace Postproccess
{
    public class CustomPostProcess : ScriptableRendererFeature
    {
        [SerializeField] private UniversalRendererData rendererData;
        [SerializeField] private RenderPassEvent renderStage = RenderPassEvent.AfterRenderingTransparents;
        [SerializeField] private Material material;
    
        private CustomPostProcessPass pass;

        public override void Create()
        {
            pass = new CustomPostProcessPass(rendererData, material, material.name);
        }

        public override void SetupRenderPasses(ScriptableRenderer renderer, in RenderingData renderingData)
        {
            pass.renderPassEvent = renderStage;
        }

#if UNITY_EDITOR
        public override void OnCameraPreCull(ScriptableRenderer renderer, in CameraData cameraData)
        {
            pass.renderPassEvent = renderStage;
        }
#endif

        public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
        {
            renderer.EnqueuePass(pass);
        }
    }
}