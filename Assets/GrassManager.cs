using System.Collections;
using System.Collections.Generic;
using UnityEngine;
[ExecuteInEditMode]
public class GrassManager : MonoBehaviour
{
    public float ambientIntensity;
    public Light directionalLight;
    public Material grassShader;

    [Header("Additional Lights")]
    public List<Light> lights = new List<Light>();

    [Header("Control")]
    [Tooltip("This is expensive.")]
    public bool runOnUpdate;

    public void UpdateLight()
    {
        grassShader.SetFloat("_AmbientIntensity", ambientIntensity);
        grassShader.SetFloat("_DirectionalLightIntensity", directionalLight.intensity);
        grassShader.SetVector("_DirectionalLightDirection", directionalLight.transform.forward);
        grassShader.SetColor("_DirectionalLightColor", directionalLight.color);
    }

    #if UNITY_EDITOR

    
    private void Update()
    {
        if (runOnUpdate)
        UpdateLight();
    }
    #endif

}
