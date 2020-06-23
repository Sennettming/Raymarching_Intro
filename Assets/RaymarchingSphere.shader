Shader "Raymarching/RaymarchingSphere"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        // No culling or depth
        Cull Off ZWrite Off ZTest Always

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0

            #include "UnityCG.cginc"

            sampler2D _MainTex;
            uniform float4x4 _CamFrustum;
            uniform float4x4 _CamToWorld;
            uniform float _maxdistance;
            uniform float4 _sphere1;
            uniform int _sampleCount;

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 ray : TEXCOORD1;
                float3 worldPos : TEXCOORD2;
            };

            v2f vert (appdata_full v)
            {
                v2f o;
                half index = v.vertex.z;
                v.vertex.z = 0;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.texcoord;

                float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.worldPos.xyz = worldPos;

                o.ray = _CamFrustum[int(index)].xyz;

                o.ray /= abs(o.ray.z);
                o.ray = mul(_CamToWorld, o.ray);
                return o;
            }

            float sdSphere(float3 currentPos, float radius)
            {
                return length(currentPos) - radius;
            }

            float disatanceField(float3 p)
            {
                float sphere = sdSphere(p - _sphere1.xyz, 2.0);
                return sphere;
            }

            float3 getNormal(float3 pos)// get normal in distance field is different from polygon
            {
                const float2 offset = float2(0.001, 0.0);
                float3 n = float3(disatanceField(pos + offset.xyy) - disatanceField(pos - offset.xyy),
                                  disatanceField(pos + offset.yxy) - disatanceField(pos - offset.yxy),
                                  disatanceField(pos + offset.yyx) - disatanceField(pos - offset.yyx));
                return normalize(n);
            }
            
            float4 raymarching(float3 ro, float3 rd, float3 lightDir)
            {
                float4 result = float4(1,1,1,1);
                const int sampleCount = _sampleCount;
                float t = 0; // distance travelled along ray dir

                for (int i=0; i<sampleCount; i++)
                {
                    if (t> _maxdistance)
                    {
                        //Environment
                        result = float4(rd, 0);
                        break;
                    }

                    float3 p = ro + rd * t;
                    //check hit in distancefield
                    float d = disatanceField(p);
                    if (d<0.01) // hit sphere
                    {
                        // draw sphere shading
                        float3 normal = getNormal(p);
                        float3 NdotL = dot(normal, lightDir);

                        result = float4(float3(1,1,1) * NdotL,1);
                        break;
                    }
                    t += d;
                }
                return result;
            }


            fixed4 frag (v2f i) : SV_Target
            {
                float3 col = tex2D(_MainTex, i.uv);
                float3 worldPos = i.worldPos;
                half3 worldLightDir = normalize(UnityWorldSpaceLightDir(worldPos));
                float3 rayDir = normalize(i.ray.xyz);
                float3 rayOrigin = _WorldSpaceCameraPos;
                float4 raymarchR =  raymarching(rayOrigin, rayDir, worldLightDir);
                return raymarchR;
                // return float4(col,1);
                // return float4(col * (1.0 - raymarchR.w) + raymarchR.xyz * raymarchR.w, 1.0);//if ray hit raymarchR will be one
            }
            ENDCG
        }
    }
}
