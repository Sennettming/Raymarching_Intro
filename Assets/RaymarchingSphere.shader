Shader "PeerPlay/RaymarchingSphere"
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

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 ray : TEXCOORD1;
            };

            v2f vert (appdata v)
            {
                v2f o;
                half index = v.vertex.z;
                v.vertex.z = 0;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;

                o.ray = _CamFrustum[int(index)].xyz;

                o.ray /= abs(o.ray.z);
                o.ray = mul(_CamToWorld, o.ray);
                return o;
            }

            float sdSphere(float3 p, float s)
            {
                return length(p) - s;
            }

            float3 disatanceField(float3 p)
            {
                float sphere1 = sdSphere(p-_sphere1.xyz, _sphere1.z);
                return sphere1;
            }
            
            float4 raymarching(float3 ro, float3 rd)
            {
                float4 result = float4(1,1,1,1);
                const int max_interation = 64;
                float t = 0; // distance travelled along ray dir

                for (int i=0; i<max_interation; i++)
                {
                    if (t> _maxdistance)
                    {
                        //Envisonment
                        result = float4(rd, 1);
                        break;
                    }

                    float3 p = ro + rd * t;
                    //check hit in distancefield
                    float d = disatanceField(p);
                    if (d<0.01)
                    {
                        result = float4(1,1,1,1);
                        break;
                    }
                    t += d;
                }
                return result;
            }


            fixed4 frag (v2f i) : SV_Target
            {
                // return float4(1,1,1,1);
                float3 rayDir = normalize(i.ray.xyz);
                float3 rayOrigin = _WorldSpaceCameraPos;
                float4 result = raymarching(rayOrigin, rayDir);
                // return fixed4(rayDir, 1);
                return result;
            }
            ENDCG
        }
    }
}
