#version 300 es

// This is a fragment shader. If you've opened this file first, please
// open and read lambert.vert.glsl before reading on.
// Unlike the vertex shader, the fragment shader actually does compute
// the shading of geometry. For every pixel in your program's output
// screen, the fragment shader is run for every bit of geometry that
// particular pixel overlaps. By implicitly interpolating the position
// data passed into the fragment shader by the vertex shader, the fragment shader
// can compute what color to apply to its pixel based on things like vertex
// position, light position, and vertex color.
precision highp float;

uniform vec4 u_Color; // The color with which to render this instance of geometry.
uniform highp int u_Time;
// These are the interpolated values out of the rasterizer, so you can't know
// their specific values without knowing the vertices that contributed to them
in vec4 fs_Nor;
in vec4 fs_LightVec;
in vec4 fs_Col;
in vec4 fs_Pos;
in float fs_Displacement;
uniform float u_Speed;
out vec4 out_Col; // This is the final output color that you will see on your
                  // screen for the pixel that is currently being processed.



vec4 permute(vec4 x){return mod(((x*34.0)+1.0)*x, 289.0);}
vec4 taylorInvSqrt(vec4 r){return 1.79284291400159 - 0.85373472095314 * r;}
vec3 fade(vec3 t) {return t*t*t*(t*(t*6.0-15.0)+10.0);}

float perlin3d(vec3 P){
  vec3 Pi0 = floor(P); // Integer part for indexing
  vec3 Pi1 = Pi0 + vec3(1.0); // Integer part + 1
  Pi0 = mod(Pi0, 289.0);
  Pi1 = mod(Pi1, 289.0);
  vec3 Pf0 = fract(P); // Fractional part for interpolation
  vec3 Pf1 = Pf0 - vec3(1.0); // Fractional part - 1.0
  vec4 ix = vec4(Pi0.x, Pi1.x, Pi0.x, Pi1.x);
  vec4 iy = vec4(Pi0.yy, Pi1.yy);
  vec4 iz0 = Pi0.zzzz;
  vec4 iz1 = Pi1.zzzz;

  vec4 ixy = permute(permute(ix) + iy);
  vec4 ixy0 = permute(ixy + iz0);
  vec4 ixy1 = permute(ixy + iz1);

  vec4 gx0 = ixy0 / 7.0;
  vec4 gy0 = fract(floor(gx0) / 7.0) - 0.5;
  gx0 = fract(gx0);
  vec4 gz0 = vec4(0.5) - abs(gx0) - abs(gy0);
  vec4 sz0 = step(gz0, vec4(0.0));
  gx0 -= sz0 * (step(0.0, gx0) - 0.5);
  gy0 -= sz0 * (step(0.0, gy0) - 0.5);

  vec4 gx1 = ixy1 / 7.0;
  vec4 gy1 = fract(floor(gx1) / 7.0) - 0.5;
  gx1 = fract(gx1);
  vec4 gz1 = vec4(0.5) - abs(gx1) - abs(gy1);
  vec4 sz1 = step(gz1, vec4(0.0));
  gx1 -= sz1 * (step(0.0, gx1) - 0.5);
  gy1 -= sz1 * (step(0.0, gy1) - 0.5);

  vec3 g000 = vec3(gx0.x,gy0.x,gz0.x);
  vec3 g100 = vec3(gx0.y,gy0.y,gz0.y);
  vec3 g010 = vec3(gx0.z,gy0.z,gz0.z);
  vec3 g110 = vec3(gx0.w,gy0.w,gz0.w);
  vec3 g001 = vec3(gx1.x,gy1.x,gz1.x);
  vec3 g101 = vec3(gx1.y,gy1.y,gz1.y);
  vec3 g011 = vec3(gx1.z,gy1.z,gz1.z);
  vec3 g111 = vec3(gx1.w,gy1.w,gz1.w);

  vec4 norm0 = taylorInvSqrt(vec4(dot(g000, g000), dot(g010, g010), dot(g100, g100), dot(g110, g110)));
  g000 *= norm0.x;
  g010 *= norm0.y;
  g100 *= norm0.z;
  g110 *= norm0.w;
  vec4 norm1 = taylorInvSqrt(vec4(dot(g001, g001), dot(g011, g011), dot(g101, g101), dot(g111, g111)));
  g001 *= norm1.x;
  g011 *= norm1.y;
  g101 *= norm1.z;
  g111 *= norm1.w;

  float n000 = dot(g000, Pf0);
  float n100 = dot(g100, vec3(Pf1.x, Pf0.yz));
  float n010 = dot(g010, vec3(Pf0.x, Pf1.y, Pf0.z));
  float n110 = dot(g110, vec3(Pf1.xy, Pf0.z));
  float n001 = dot(g001, vec3(Pf0.xy, Pf1.z));
  float n101 = dot(g101, vec3(Pf1.x, Pf0.y, Pf1.z));
  float n011 = dot(g011, vec3(Pf0.x, Pf1.yz));
  float n111 = dot(g111, Pf1);

  vec3 fade_xyz = fade(Pf0);
  vec4 n_z = mix(vec4(n000, n100, n010, n110), vec4(n001, n101, n011, n111), fade_xyz.z);
  vec2 n_yz = mix(n_z.xy, n_z.zw, fade_xyz.y);
  float n_xyz = mix(n_yz.x, n_yz.y, fade_xyz.x);
  return 2.2 * n_xyz;
}

const float[9] thresholds = float[] (
    0.33, 0.36, 0.38, 0.41, 0.43, 0.45, 0.5, 0.55, 0.65
);


vec3 colorArray(float displacement) {


    /*vec3[7] colors = vec3[] (
        vec3(1.0, 1.0, 1.0),
        vec3(1.0, 1.0, 0.8),
        vec3(1.0, 0.9, 0.5),
        vec3(1.0, 0.8, 0.2),
        vec3(1.0, 0.6, 0.0),
        vec3(0.8, 0.25, 0.0),
        vec3(0.5, 0.0, 0.0)
    );*/

    vec3[8] colors = vec3[] (
        vec3(u_Color.x + 1.0 * (1.0 - u_Color.x), u_Color.y + 1.0 * (1.0 - u_Color.y), u_Color.z + 1.0 * (1.0 - u_Color.z)),
        vec3(u_Color.x + 1.0 * (1.0 - u_Color.x), u_Color.y + 1.0 * (1.0 - u_Color.y), u_Color.z + 0.8 * (1.0 - u_Color.z)),
        vec3(u_Color.x + 1.0 * (1.0 - u_Color.x), u_Color.y + 0.9 * (1.0 - u_Color.y), u_Color.z + 0.8 * (1.0 - u_Color.z)),
        vec3(u_Color.x + 1.0 * (1.0 - u_Color.x), u_Color.y + 0.9 * (1.0 - u_Color.y), u_Color.z + 0.5 * (1.0 - u_Color.z)),

// red
        vec3(u_Color.x + 1.0 * (1.0 - u_Color.x), u_Color.y + 0.8 * (1.0 - u_Color.y), u_Color.z + 0.3 * (1.0 - u_Color.z)),
        vec3(u_Color.x + 0.7 * (1.0 - u_Color.x), u_Color.y + 0.3 * (1.0 - u_Color.y), u_Color.z),
        vec3(u_Color.x + 0.6 * (1.0 - u_Color.x), u_Color.y + 0.25 * (1.0 - u_Color.y), u_Color.z),
        vec3(u_Color)
    );

    float interp = smoothstep(0.42, 1.7, displacement);

    for (int i = 0; i <= 7; ++i) {
        if (interp < thresholds[i] && i == 0) {
            return colors[i];
        } else if (interp < thresholds[i] && i != 5) {
            return mix(colors[i - 1], colors[i], smoothstep(thresholds[i - 1], thresholds[i], interp));
        } else if (interp < thresholds [i] && i == 5) {
            // hard cutoff to dark color
            return colors[i];
        }
    }
    return colors[7];
}

float triangle(float x, float freq, float amplitude) {
    return abs(mod((x * freq), amplitude) - (0.5 * amplitude));
}

void main()
{
    float PerlinDisplacement = 0.f;
    
    vec3 pos = vec3(fs_Pos[0], fs_Pos[1], fs_Pos[2]);
    float f = 0.35f;


    // Material base color (before shading)
    vec4 diffuseColor = u_Color;

    // Calculate the diffuse term for Lambert shading
    float diffuseTerm = dot(normalize(fs_Nor), normalize(fs_LightVec));
    // Avoid negative lighting values
    // diffuseTerm = clamp(diffuseTerm, 0, 1);

    float ambientTerm = 0.2;

    float lightIntensity = diffuseTerm + ambientTerm;   //Add a small float value to the color multiplier
                                                        //to simulate ambient lighting. This ensures that faces that are not
                                                        //lit by our point light are not completely black.


    //vec3 whiteMix = mix(vec3(1.f, 1.f, 1.f), diffuseColor.rgb, 0.01);

    //vec3 finalColor = mix(whiteMix, diffuseColor.rgb, fs_Displacement);

    if (fs_Displacement < 0.28) {
        PerlinDisplacement = abs(perlin3d(vec3(pos[0] / f, pos[1] / f, pos[2] / f)));
    }

    vec3 base = colorArray(fs_Displacement + 0.7f) + PerlinDisplacement;

    base = mix(vec3(1.f, 1.f, 1.f), base, fs_Displacement * 3.3f-0.15f);

    float brightness = triangle(float(u_Time) / 5000., 3., 0.3);

    base += mix(0., brightness, fs_Displacement * 3. - 0.3);
    

    out_Col = vec4(base, diffuseColor.a);
}
