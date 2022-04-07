Shader "Hidden/BrushShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _PixelOffset ("Pixel Offset", int) = 1
    }
    SubShader
    {
        Cull Off ZWrite Off ZTest Always

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            sampler2D _MainTex;
            float4 _MainTex_TexelSize;
            uniform int _PixelOffset;

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);
                float2 offset = 1 / _ScreenParams.xy;
                
                float4 r = tex2D(_MainTex, i.uv + float2(offset.x, 0.0) * _PixelOffset);
                float4 l = tex2D(_MainTex, i.uv - float2(offset.x, 0.0) * _PixelOffset);
                float4 u = tex2D(_MainTex, i.uv + float2(0, offset.y) * _PixelOffset);
                float4 d = tex2D(_MainTex, i.uv + float2(0, offset.y) * _PixelOffset);
                
                col = min(r, col);
                col = min(l, col);
                col = min(u, col);
                col = min(d, col);
                
                return col;
            }
            ENDCG
        }
    }
}
