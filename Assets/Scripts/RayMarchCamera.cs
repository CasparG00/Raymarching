using UnityEngine;

[RequireComponent(typeof(Camera))]
[ExecuteInEditMode]
public class RayMarchCamera : SceneViewFilter
{
    [SerializeField] private Shader shader;

    private Material RayMarchMaterial
    {
        get
        {
            if (!rayMarchMaterial && shader)
            {
                rayMarchMaterial = new Material(shader) {hideFlags = HideFlags.HideAndDontSave};
            }
            return rayMarchMaterial;
        }
    }
    private Material rayMarchMaterial;

    private Camera Cam
    {
        get
        {
            if (!cam)
            {
                cam = GetComponent<Camera>();
            }
            return cam;
        }
    }
    private Camera cam;
    
    [Header("Setup")]
    public float maxDistance;
    [Min(1)] public int maxIterations;
    [Min(0.0001f)] public float accuracy;
    
    [Header("Directional Light")]
    public Light directionalLight;

    [Header("Shadow")]
    [Min(0)]
    public float shadowIntensity;
    public Vector2 shadowDistance;
    [Min(1)]
    public float shadowPenumbra;

    [Header("Ambient Occlusion")]
    [Min(0.01f)]
    public float aoStepSize;
    [Range(1, 10)]
    public int aoIterations;
    [Range(0, 1)]
    public float aoIntensity;
    
    [Header("Signed Distance Field")]
    public Color mainColor;
    public Vector3 modInterval;

    public Vector4 cylinder;

    [SerializeField] private MicInput micInput;

    private void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        if (!RayMarchMaterial)
        {
            Graphics.Blit(src, dest);
        }
        
        RayMarchMaterial.SetMatrix("_CamFrustum", CamFrustum(Cam));
        RayMarchMaterial.SetMatrix("_CamToWorld", Cam.cameraToWorldMatrix);
        RayMarchMaterial.SetFloat("_MaxDistance", maxDistance);
        RayMarchMaterial.SetVector("_ModInterval", modInterval);
        RayMarchMaterial.SetVector("_Cylinder", cylinder);
        RayMarchMaterial.SetVector("_LightDir", directionalLight ? directionalLight.transform.forward : Vector3.down);
        RayMarchMaterial.SetColor("_MainColor", mainColor);
        RayMarchMaterial.SetColor("_LightCol", directionalLight.color);
        RayMarchMaterial.SetFloat("_LightIntensity", directionalLight.intensity);
        RayMarchMaterial.SetFloat("_ShadowIntensity", shadowIntensity);
        RayMarchMaterial.SetFloat("_ShadowPenumbra", shadowPenumbra);
        RayMarchMaterial.SetVector("_ShadowDistance", shadowDistance);
        RayMarchMaterial.SetInt("_MaxIterations", maxIterations);
        RayMarchMaterial.SetFloat("_Accuracy", accuracy);
        RayMarchMaterial.SetFloat("_AoStepSize", aoStepSize);
        RayMarchMaterial.SetFloat("_AoIntensity", aoIntensity);
        RayMarchMaterial.SetInt("_AoIterations", aoIterations);
        RayMarchMaterial.SetColor("_FogColor", RenderSettings.fogColor);
        RayMarchMaterial.SetFloat("_RMSValueMic", micInput.rmsValueMic);

        RenderTexture.active = dest;
        RayMarchMaterial.SetTexture("_MainTex", src);
        
        GL.PushMatrix();
        GL.LoadOrtho();
        RayMarchMaterial.SetPass(0);
        GL.Begin(GL.QUADS);
        
        //Bottom Left
        GL.MultiTexCoord2(0, 0, 0);
        GL.Vertex3(0, 0, 3);
        
        //Bottom Right
        GL.MultiTexCoord2(0, 1, 0);
        GL.Vertex3(1, 0, 2);
        
        //Top Right
        GL.MultiTexCoord2(0, 1, 1);
        GL.Vertex3(1, 1, 1);
        
        //Top Left
        GL.MultiTexCoord2(0, 0, 1);
        GL.Vertex3(0, 1, 0);
        GL.End();
        GL.PopMatrix();

        RenderSettings.fogColor = Cam.backgroundColor;
    }

    private Matrix4x4 CamFrustum(Camera cam)
    {
        var frustum = Matrix4x4.identity;
        var fov = Mathf.Tan((cam.fieldOfView * 0.5f) * Mathf.Deg2Rad);

        var goUp = Vector3.up * fov;
        var goRight = Vector3.right * fov * cam.aspect;
        
        var tl = -Vector3.forward - goRight + goUp;
        var tr = -Vector3.forward + goRight + goUp;
        var br = -Vector3.forward + goRight - goUp;
        var bl = -Vector3.forward - goRight - goUp;
        
        frustum.SetRow(0, tl);
        frustum.SetRow(1, tr);
        frustum.SetRow(2, br);
        frustum.SetRow(3, bl);

        return frustum;
    }
}
