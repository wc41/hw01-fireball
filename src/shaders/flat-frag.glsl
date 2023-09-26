#version 300 es
precision highp float;

uniform vec3 u_Eye, u_Ref, u_Up;
uniform vec2 u_Dimensions;
uniform highp int u_Time;

in vec2 fs_Pos;
out vec4 out_Col;

float noise2D(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) *
                 42255.5453);
}

void main() {
  float timeFunc = cos(0.01f * float(u_Time));
  float timeFunc5 = sin(0.008f * float(u_Time));

  float timeFunc2 = cos(0.004f * float(u_Time) + 0.2);
  float timeFunc3 = sin(0.013f * float(u_Time) + 0.2);
  float timeFunc4 = sin(0.007f * float(u_Time) + 0.2);

  float xPos = fs_Pos.x / 2. + 1.;
  float yPos = fs_Pos.y / 2. + 1.;
  vec3 vColor = mix(vec3(0.05, 0.05, 0.05), vec3( 0.12, 0.0, 0.02), yPos);

  if (noise2D(vec2(xPos, yPos)) > 0.32f && noise2D(vec2(xPos, yPos)) < 0.3202f) {
    float brightness = noise2D(vec2(yPos, xPos)) + (timeFunc);
    vColor += vec3(brightness * 1., brightness * 1., brightness * 1.);
  }
  
  if (noise2D(vec2(xPos, yPos)) > 0.42f && noise2D(vec2(xPos, yPos)) < 0.4202f) {
    float brightness = noise2D(vec2(yPos, xPos)) + (timeFunc2);
    vColor += vec3(brightness * 1., brightness * 1., brightness * 1.);
  }
  if (noise2D(vec2(xPos, yPos)) > 0.52f && noise2D(vec2(xPos, yPos)) < 0.5202f) {
    float brightness = noise2D(vec2(yPos, xPos)) + (timeFunc);
    vColor += vec3(brightness * 1., brightness * 1., brightness * 1.);
  }
  if (noise2D(vec2(xPos, yPos)) > 0.62f && noise2D(vec2(xPos, yPos)) < 0.6202f) {
    float brightness = noise2D(vec2(yPos, xPos)) + (timeFunc3);
    vColor += vec3(brightness * 1., brightness * 1., brightness * 1.);
  }
    if (noise2D(vec2(xPos, yPos)) > 0.72f && noise2D(vec2(xPos, yPos)) < 0.7202f) {
    float brightness = noise2D(vec2(yPos, xPos)) + (timeFunc4);
    vColor += vec3(brightness * 1., brightness * 1., brightness * 1.);
  }

    if (noise2D(vec2(xPos, yPos)) > 0.14f && noise2D(vec2(xPos, yPos)) < 0.1402f) {
    float brightness = noise2D(vec2(yPos, xPos)) + (timeFunc5);
    vColor += vec3(brightness * 1., brightness * 1., brightness * 1.);
  }
  out_Col = vec4(vColor, 1.0);
}