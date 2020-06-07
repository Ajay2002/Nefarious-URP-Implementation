Shader "Unlit/GrassPoints"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Height("Grass Height",Float) = 0.0
        _BaseHeight("Grass Width", Float) = 0.0
        _BaseTint("Base Grass Tint", Color) = (0,0,0,1)
        _Tint("Grass Tint", Color) = (0,0,0,1)
        _RandomFactor("Randomness Factor", Float) = 0
        _XWindSpeed("SpeedX", Float) = 0
        _YWindSpeed("SpeedX", Float) = 0
        _Density ("Density", Int) = 1
        _AmbientIntensity("Ambient Intensity", Float) = 0
        _DirectionalLightDirection ("Directional Light Direction", Vector) = (0,0,0)
        _DirectionalLightIntensity ("Directional Light Intensity", Float) = 0
        _DirectionalLightColor ("Directional Light Color", Color) = (0,0,0,1)
        _AmbientOcclusionIntensity ("Ambient Occlusion Intensity", Float) = 0
        _AmbientOcclusionColor ("Ambient Occlusion Color", Color) = (0,0,0,1)
        _DuplicateEdges ("Duplicate Rotation", Int) = 0
        _MuchMoreDensity ("Density Extra", Int) = 0
        _SpreadFactor ("Spread Factor", Float) = 0.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "LightMode"="UniversalForward" }
        LOD 100
        
        //Double sided (culling is off, lower performance)
        Cull Off

       

        Pass
        {
            //By putting this above the pass you can have multplie!!
       HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma geometry geom
            #pragma multi_compile_fog
       // Required to compile gles 2.0 with standard SRP library
       // All shaders must be compiled with HLSLcc and currently only gles is not using HLSLcc by default
       #pragma prefer_hlslcc gles
       #pragma exclude_renderers d3d11_9x
       #pragma target 2.0

       // -------------------------------------
       // Material Keywords
       // unused shader_feature variants are stripped from build automatically
       #pragma shader_feature _NORMALMAP
       #pragma shader_feature _ALPHATEST_ON
       #pragma shader_feature _ALPHAPREMULTIPLY_ON
       #pragma shader_feature _EMISSION
       #pragma shader_feature _METALLICSPECGLOSSMAP
       #pragma shader_feature _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
       #pragma shader_feature _OCCLUSIONMAP

       #pragma shader_feature _SPECULARHIGHLIGHTS_OFF
       #pragma shader_feature _GLOSSYREFLECTIONS_OFF
       #pragma shader_feature _SPECULAR_SETUP
       #pragma shader_feature _RECEIVE_SHADOWS_OFF

       // -------------------------------------
       // Universal Render Pipeline keywords
       // When doing custom shaders you most often want to copy and past these #pragmas
       // These multi_compile variants are stripped from the build depending on:
       // 1) Settings in the LWRP Asset assigned in the GraphicsSettings at build time
       // e.g If you disable AdditionalLights in the asset then all _ADDITIONA_LIGHTS variants
       // will be stripped from build
       // 2) Invalid combinations are stripped. e.g variants with _MAIN_LIGHT_SHADOWS_CASCADE
       // but not _MAIN_LIGHT_SHADOWS are invalid and therefore stripped.
       #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
       #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
       #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
       #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
       #pragma multi_compile _ _SHADOWS_SOFT
       #pragma multi_compile _ _MIXED_LIGHTING_SUBTRACTIVE

       // -------------------------------------
       // Unity defined keywords
       #pragma multi_compile _ DIRLIGHTMAP_COMBINED
       #pragma multi_compile _ LIGHTMAP_ON
       #pragma multi_compile_fog

       //--------------------------------------
       // GPU Instancing
       #pragma multi_compile_instancing

            //TODO: Can't have UnityCG.cginc w/ the URP Includes or else it has redefinition errors, need a custom version
            #include "UnityCG.cginc"
          
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float4 color: COLOR;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float3 normal : NORMAL;
                float4 color: COLOR;
                float4 tangent : TANGENT;
            };

            struct geomOutput
            {
                //This is what is needed to render for the fragment shader (this is why v2f has it!!)
                //https://www.gamedev.net/forums/topic/579610-hlsl-semantics-position-vs-sv_position/
                //CONATINS THE FINAL POSITION TO BE TRANSFORMED IF YOU USE POSITION THEN THAT MEANS IT IS STILL THE WORLD SPACE VERTEX
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
        
            };

            // Simple noise function, sourced from http://answers.unity.com/answers/624136/view.html
            // Extended discussion on this function can be found at the following link:
            // https://forum.unity.com/threads/am-i-over-complicating-this-random-function.454887/#post-2949326
            // Returns a number in the 0...1 range.
            float rand(float3 co)
            {
                return frac(sin(dot(co.xyz, float3(12.9898, 78.233, 53.539))) * 43758.5453);
            }

            // Construct a rotation matrix that rotates around the provided axis, sourced from:
            // https://gist.github.com/keijiro/ee439d5e7388f3aafc5296005c8c3f33
            float3x3 AngleAxis3x3(float angle, float3 axis)
            {
                float c, s;
                sincos(angle, s, c);

                float t = 1 - c;
                float x = axis.x;
                float y = axis.y;
                float z = axis.z;

                return float3x3(
                    t * x * x + c, t * x * y - s * z, t * x * z + s * y,
                    t * x * y + s * z, t * y * y + c, t * y * z - s * x,
                    t * x * z - s * y, t * y * z + s * x, t * z * z + c
                    );
            }


            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _Height;
            float _BaseHeight;
            
            float4 _AmbientOcclusionColor;
            float _AmbientOcclusionIntensity;

            float4 _Tint;
            float _RandomFactor;
            float _YWindSpeed;
            float _XWindSpeed;
            float _AmbientIntensity;
            int _Density;
            int _DuplicateEdges;
            int _MuchMoreDensity;
            float _SpreadFactor;
            //AFTER THE VERTEX SHADER YOU NONCE!

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex =(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.tangent = v.tangent;
                o.color = v.color;
                o.normal = v.normal;
                UNITY_TRANSFER_FOG(o, o.vertex);
                return o;
            }

            /*Semantics with the SV prefix are "system value" semantics. This means that they have a specific meaning to the pipeline. 
            In the case of SV_Position, if it's attached to a vertex shader output that means that the output will contain he final 
            transformed vertex position used for rasterization. Or if you use it for a pixel shader input, it will contain the screenspace
            position of the pixel.
            All of these SV semantics are described in the SDK documentation, in the HLSL section. Just search for "semantics".*/

            [maxvertexcount(24)]
            void geom(triangle v2f input[3], inout TriangleStream<geomOutput> output)
            {
                //Middle
                float dV = length(ObjSpaceViewDir(input[0].vertex));
                int _LocalDensity = 0;

                //This is an easier solution to tesselation, while also having the LOD effect, might do an alpha blend for distance as well
                if (dV < 7)
                {
                    _LocalDensity = 4;
                }

                if (dV >= 7)
                {
                    _LocalDensity = 3;
                }
                
                if (dV > 10)
                {
                    _LocalDensity = 2;
                }
                
                if (dV > 20)
                {
                    _LocalDensity = 1;
                }
                
                if (dV > 30)
                {
                    _LocalDensity = 0;
                }

                for (int d = 0; d < clamp(_LocalDensity,0,4); d++) {

                    int c = 0;
                    
                    c = d;

                    if (d == 3) c = 2;

                    float3 mid = (input[c].vertex.xyz);
                    if (input[c].color.y < 0.1)
                        continue;

                    if (d == 3) {
                     
                        mid = (input[0].vertex.xyz+input[1].vertex.xyz+input[2].vertex.xyz)/3;
                    }

                    float heightMult = input[c].color.y;

                    float rotAA = 0;
                    float rotBB = 0;
                    float rotCC = 0;

                    for (int i = 0; i < 3; i++)
                    {
                        geomOutput o;

                        float rotA = rand(mid) * UNITY_TWO_PI;
                        float3x3 facingRotationMatrix = AngleAxis3x3(rotA, float3(0, 0, 1));
                        float3x3 bendRotationMatrix = AngleAxis3x3(rand(mid.zzx) * 0.3 * UNITY_PI * 0.5, float3(1, 0, 0));

                        float3 vNormal = normalize(input[0].normal);
                        float4 vTangent = normalize(input[0].tangent);
                        float3 vBinormal = normalize(cross(vNormal, vTangent) * vTangent.w);

                        //Imagine the tangent plane ([]), now if you go up on the tangent plane float3(0,1,0); that's straight up (normal).. Now you need
                        //to convert this to local -- which is what this matrix is for
                        float3x3 tangentToLocal1 = float3x3(
                            vTangent.x, vBinormal.x, vNormal.x,
                            vTangent.y, vBinormal.y, vNormal.y,
                            vTangent.z, vBinormal.z, vNormal.z
                            );

                        float3x3 tangentToLocal = mul(mul(tangentToLocal1, facingRotationMatrix), bendRotationMatrix);

                        float randomi = clamp(rand(input[c].vertex.xyz) * _RandomFactor, 0.9, 10)*heightMult;
                        if (i == 0)
                        {
                            rotAA = rotA * UNITY_TWO_PI/2;
                            o.vertex = UnityObjectToClipPos(mid + (mul(tangentToLocal, float3(-0.5 * _BaseHeight * randomi, 0, 0))));
                            o.uv = float2(0, 0);
                        }
                        else if (i == 1)
                        {
                            rotBB = rotA * UNITY_TWO_PI / 2;
                            o.vertex = UnityObjectToClipPos(mid + (mul(tangentToLocal, float3(_SinTime.x * _XWindSpeed * rand(input[c].vertex.xxz), _SinTime.y * _YWindSpeed * rand(input[c].vertex.yyz), 1 * _Height * randomi*1.5))));
                            o.uv = float2(0, 1);
                        }
                        else 
                        {
                            rotCC = rotA * UNITY_TWO_PI / 2;
                            o.vertex = UnityObjectToClipPos(mid + (mul(tangentToLocal, float3(0.5 * _BaseHeight * randomi, 0, 0))));
                            o.uv = float2(1, 0);
                        }

                        //The outward facing..

                        //Imagine y- on tangent plane
                        float3 tangentNormal = float3(0, -1, 0);

                        //tangent -> out
                        float3 localNormal = mul(tangentToLocal, tangentNormal);

                        o.normal = normalize(UnityObjectToWorldNormal(localNormal));
              
                        output.Append(o);
                    }

                    output.RestartStrip();

                    if (_DuplicateEdges == 1) {
                        for (int v = 0; v < _MuchMoreDensity; v++) {
                            
                            for (int i = 0; i < 3; i++)
                            {
                                geomOutput o;

                                float rotA = rand(mid) * UNITY_TWO_PI;

                                if (i == 0) rotA = rotAA * rand(v*input[i].vertex);
                                if (i == 1) rotA = rotBB * rand(v * input[i].vertex);
                                if (i == 2) rotA = rotCC * rand(v * input[i].vertex);

                                

                                float3x3 facingRotationMatrix = AngleAxis3x3(rotA, float3(0, 0, 1));
                                float3x3 bendRotationMatrix = AngleAxis3x3(rand(mid.zzx*v) * 0.3 * UNITY_PI * 0.5, float3(1, 0, 0));

                                float3 vNormal = normalize(input[0].normal);
                                float4 vTangent = normalize(input[0].tangent);
                                float3 vBinormal = normalize(cross(vNormal, vTangent) * vTangent.w);

                                //Imagine the tangent plane ([]), now if you go up on the tangent plane float3(0,1,0); that's straight up (normal).. Now you need
                                //to convert this to local -- which is what this matrix is for
                                float3x3 tangentToLocal1 = float3x3(
                                    vTangent.x, vBinormal.x, vNormal.x,
                                    vTangent.y, vBinormal.y, vNormal.y,
                                    vTangent.z, vBinormal.z, vNormal.z
                                    );

                                float3x3 tangentToLocal = mul(mul(tangentToLocal1, facingRotationMatrix), bendRotationMatrix);

                            
                                float randomi = clamp(rand(input[c].vertex.xyz * v) * _RandomFactor, 0.9, 10) * heightMult;
                                if (i == 0)
                                {

                                    o.vertex = UnityObjectToClipPos( mid + (mul(tangentToLocal, float3(-0.5 * _BaseHeight * randomi , 0, 0))));
                                   

                                    o.uv = float2(0, 0);
                                }
                                else if (i == 1)
                                {

                                    o.vertex = UnityObjectToClipPos( mid + (mul(tangentToLocal,float3(_SinTime.x * _XWindSpeed * rand(input[c].vertex.xxz * v) , _SinTime.y * _YWindSpeed * rand(input[c].vertex.yyz * v), 1 * _Height * randomi * 1.5))));
                                    o.uv = float2(0, 1);
                                }
                                else
                                {

                                    o.vertex = UnityObjectToClipPos( mid + (mul(tangentToLocal, float3(0.5 * _BaseHeight * randomi , 0, 0))));
                                    o.uv = float2(1, 0);
                                }

                                //The outward facing..

                                //Imagine y- on tangent plane
                                float3 tangentNormal = float3(0, -1, 0);

                                //tangent -> out
                                float3 localNormal = mul(tangentToLocal, tangentNormal);

                                o.normal = normalize(UnityObjectToWorldNormal(localNormal));

                                output.Append(o);
                            }

                            output.RestartStrip();
                        }
                    }
                }
            }
            
            float4 _BaseTint;

            float4 _DirectionalLightColor;
            float _DirectionalLightIntensity;
            float3 _DirectionalLightDirection;
            
            //expects input in screenposition (UnityObject (local space) -> Clip Pos (camera space))
            fixed4 frag(geomOutput i, fixed facing : VFACE) : SV_Target
            {
                float3 normal = facing > 0 ? i.normal : -i.normal;

                fixed4 col = lerp(_BaseTint,_Tint, i.uv.y)*_DirectionalLightColor* clamp(_DirectionalLightIntensity*dot(_DirectionalLightDirection,-normal),_AmbientIntensity,1000);
                
                if (_AmbientOcclusionIntensity != 0)
                col = lerp(_AmbientOcclusionColor,col,clamp((-i.uv.y*i.uv.x)*_AmbientOcclusionIntensity,0,1));

                return col;

            }
                ENDHLSL
        }

       
    }
}
