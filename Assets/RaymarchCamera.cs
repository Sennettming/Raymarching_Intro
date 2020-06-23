using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Serialization;

// #pragma warning disable 0649

[RequireComponent(typeof(Camera))]
[ExecuteInEditMode]
public class RaymarchCamera : SceneViewFilter
{
    [SerializeField]// see in inspector for private variables
    private Shader rayShader = default;
    
    public Material RayMarchMaterial
    {
        get
        { 
            if (!_raymarchMat && rayShader)
            {
                _raymarchMat = new Material(rayShader);
                _raymarchMat.hideFlags = HideFlags.HideAndDontSave; // not be disposed
            }
            return _raymarchMat;
        }
    }

    private Material _raymarchMat;

    public Camera _camera
    {
        get
        {
            if (!_cam)
            {
                _cam = GetComponent<Camera>();
            }
            return _cam;
        }
    }
    
    private Camera _cam;
 
    public float _maxDistance = 5;
    public Vector4 _sphere = new Vector4(0,0,0,2);
    public int sampleCount = 128;
    
    private void OnRenderImage(RenderTexture src, RenderTexture dest)// communicate with shader
    {
        if (!RayMarchMaterial)
        {
            Graphics.Blit(src, dest);
            return;
        }
        RayMarchMaterial.SetMatrix("_CamFrustum", CamFrustum(_camera));
        RayMarchMaterial.SetMatrix("_CamToWorld", _camera.cameraToWorldMatrix);
        RayMarchMaterial.SetFloat("_maxdistance", _maxDistance);
        RayMarchMaterial.SetVector("_sphere1", _sphere);
        RayMarchMaterial.SetInt("_sampleCount", sampleCount);
        
        RenderTexture.active = dest;
        RayMarchMaterial.SetTexture("_mainTex", src);
        GL.PushMatrix();
        GL.LoadOrtho();
        RayMarchMaterial.SetPass(0);
        GL.Begin(GL.QUADS);
        
        //BL
        GL.MultiTexCoord2(0, 0.0f, 0.0f);
        GL.Vertex3(0.0f, 0.0f, 3.0f);  
        //BR
        GL.MultiTexCoord2(0, 1.0f, 0.0f);
        GL.Vertex3(1.0f, 0.0f, 2.0f);  
        //TR
        GL.MultiTexCoord2(0, 1.0f, 1.0f);
        GL.Vertex3(1.0f, 1.0f, 1.0f);  
        //TL
        GL.MultiTexCoord2(0, 0.0f, 1.0f);
        GL.Vertex3(0.0f, 1.0f, 0.0f);
        
        GL.End();
        GL.PopMatrix();
    }

    private Matrix4x4 CamFrustum(Camera cam)
    {
        Matrix4x4 frustum = Matrix4x4.identity;
        float fov = Mathf.Tan((cam.fieldOfView * 0.5f) * Mathf.Deg2Rad);

        Vector3 goUp = Vector3.up * fov;
        Vector3 goRight = Vector3.right * fov * cam.aspect;

        Vector3 TL = (-Vector3.forward - goRight + goUp);
        Vector3 TR = (-Vector3.forward + goRight + goUp);
        Vector3 BR = (-Vector3.forward + goRight - goUp);
        Vector3 BL = (-Vector3.forward - goRight - goUp);
        
        frustum.SetRow(0, TL);
        frustum.SetRow(1, TR);
        frustum.SetRow(2, BR);
        frustum.SetRow(3, BL);

        return frustum;
    }
}
