Shader "Custom/RayMarchShader"
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
            #include "DistanceFunctions.cginc"

            uniform sampler2D _CameraDepthTexture;
            uniform float4x4 _CamFrustum, _CamToWorld;
            uniform int _MaxIterations;
            uniform float _Accuracy;
            uniform float _MaxDistance;

            uniform float4 _Cylinder;
            uniform float3 _ModInterval;
            
            uniform float3 _LightDir;
            uniform float3 _LightCol;
            uniform float _LightIntensity;

            uniform float2 _ShadowDistance;
            uniform float _ShadowIntensity, _ShadowPenumbra;

            uniform float _AoStepSize, _AoIntensity;
            uniform int _AoIterations;
            
            uniform fixed4 _MainColor;
            uniform fixed4 _FogColor;

            uniform float _RMSValueMic;

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

                o.ray = _CamFrustum[(int)index].xyz;
                o.ray /= abs(o.ray.z);
                o.ray = mul(_CamToWorld, o.ray);

                return o;
            }

            float4 mod289(float4 x)
            {
                return x - floor(x * (1.0 / 289.0)) * 289.0;
            }

            float4 perm(float4 x)
            {
                return mod289(((x * 34.0) + 1.0) * x);
            }

            float noise(float3 p)
            {
                float3 a = floor(p);
                float3 d = p - a;
                d = d * d * (3.0 - 2.0 * d);
                float4 b = a.xxyy + float4(0.0, 1.0, 0.0, 1.0);
                float4 k1 = perm(b.xyxy);
                float4 k2 = perm(k1.xyxy + b.zzww);
                float4 c = k2 + a.zzzz;
                float4 k3 = perm(c);
                float4 k4 = perm(c + 1.0);
                float4 o1 = frac(k3 * (1.0 / 41.0));
                float4 o2 = frac(k4 * (1.0 / 41.0));
                float4 o3 = o2 * d.z + o1 * (1.0 - d.z);
                float2 o4 = o3.yw * d.x + o3.xz * (1.0 - d.x);
                return o4.y * d.y + o4.x * (1.0 - d.y);
            }

            float distanceField(float3 p)
            {
                p.xz = mul(p.xz, opRot(p.y * .1 + _Time));
                
                const float octaves = 6;
                
                const float scale = 2;
                const float persistence = 0.3;
                const float lacunarity = 2;
                
                float amplitude = 2;
                float frequency = 1;
                float result = 0;
                for (int i = 0; i < octaves; i++)
                {
                    float3 sample = p / scale * frequency + _Time * _RMSValueMic;
                    float perlin = noise(sample) - 0.5;
                    result += perlin * amplitude;
                
                    amplitude *= persistence;
                    frequency *= lacunarity;
                }
                
                result += 1 - sdCylinder(p - _Cylinder.xyz, 5) * 0.2;
                
                return result;
            }

            float3 getNormal(float3 p)
            {
                const float2 offset = float2(0.001, 0);
                float3 n = float3(
                    distanceField(p + offset.xyy) - distanceField(p - offset.xyy),
                    distanceField(p + offset.yxy) - distanceField(p - offset.yxy),
                    distanceField(p + offset.yyx) - distanceField(p - offset.yyx)
                );
                return normalize(n);
            }

            float hardShadow(float3 ro, float3 rd, float mint, float maxt)
            {
                for(float t = mint; t < maxt;)
                {
                    float h = distanceField(ro + rd * t);
                    if (h < 0.001)
                    {
                        return 0;
                    }
                    t += h;
                }
                return 1;
            }

            float softShadow(float3 ro, float3 rd, float mint, float maxt, float k)
            {
                float result = 1;
                
                for(float t = mint; t < maxt;)
                {
                    float h = distanceField(ro + rd * t);
                    if (h < 0.001)
                    {
                        return 0;
                    }
                    result = min(result, k * h / t);
                    t += h;
                }
                return result;
            }

            float ambientOcclusion(float3 p, float3 n)
            {
                float step = _AoStepSize;
                float ao = 0;
                float dist;

                for (int i = 1; i <= _AoIterations; i++)
                {
                    dist = step * i;
                    ao += max(0, (dist - distanceField(p + n * dist)) / dist);
                }

                return (1 - ao * _AoIntensity);
            }

            float3 shading(float3 p, float3 n)
            {
                // Diffuse Color
                float3 color = _MainColor.rgb;
                
                // Directional Light
                float3 light = (_LightCol * dot(-_LightDir, n) * 0.5 + 0.5) * _LightIntensity;

                // Shadows
                float shadow = softShadow(p, -_LightDir, _ShadowDistance.x, _ShadowDistance.y, _ShadowPenumbra) * 0.5 + 0.5;
                shadow = max(0, pow(shadow, _ShadowIntensity));

                // Ambient Occlusion
                //float ao = ambientOcclusion(p, n);

                float lDot = dot(-_LightDir, n);
                float3 result = lerp(color, _LightCol * _LightIntensity, lDot * 0.5 + 0.5 < 0.55 ? 1 : 0);

                return result;
            }

            fixed4 raymarching(float3 ro, float3 rd, float depth)
            {
                fixed4 result = fixed4(1, 1, 1, 1);
                const int max_iterations = _MaxIterations;
                float t = 0; // Distance travelled along ray direction
                
                for (int i = 0; i < max_iterations; i++)
                {
                    if (t > _MaxDistance || t >= depth)
                    {
                        // Environment
                        result = _FogColor;

                        break;
                    }

                    float3 p = ro + rd * t;
                    // check for hit in distanceField
                    float d = distanceField(p);
                    if (d < _Accuracy) // we got a hit!!1!
                    {
                        // Shading
                        float3 n = getNormal(p);
                        float3 s = shading(p, n);

                        // Fog
                        float fs = length(ro - p) / _MaxDistance;

                        fixed3 col = lerp(_MainColor.rgb * s, _FogColor, fs);                      
                        result = fixed4(col, 1);
                        break;
                    }
                    t += d;
                }
                
                return result;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float depth = LinearEyeDepth(tex2D(_CameraDepthTexture, i.uv).r);
                depth *= length(i.ray);
                float3 rayDirection = normalize(i.ray.xyz);
                float3 rayOrigin = _WorldSpaceCameraPos;
                fixed4 result = raymarching(rayOrigin, rayDirection, depth);
                fixed4 col = fixed4(1 - result.w + result.xyz * result.w, result.w);
                
                return col;
            }
            ENDCG
        }
    }
}
