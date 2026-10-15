// Ported from Kyant's Shaders.kt in NexioSchedule/backdrop.
// Copyright 2025 Kyant. SPDX-License-Identifier: Apache-2.0
#include <flutter/runtime_effect.glsl>
uniform vec2 size;
uniform vec2 origin;
uniform vec2 imageSize;
uniform float radius;
uniform float refractionHeight;
uniform float refractionAmount;
uniform float chromaticAberration;
uniform sampler2D content;
out vec4 fragColor;
float sdRoundedRect(vec2 coord, vec2 halfSize, float r) {
  vec2 cornerCoord = abs(coord) - (halfSize - vec2(r));
  return length(max(cornerCoord, 0.0)) - r + min(max(cornerCoord.x, cornerCoord.y), 0.0);
}
vec2 gradSdRoundedRect(vec2 coord, vec2 halfSize, float r) {
  vec2 cornerCoord = abs(coord) - (halfSize - vec2(r));
  if (cornerCoord.x >= 0.0 || cornerCoord.y >= 0.0) return sign(coord) * normalize(max(cornerCoord, vec2(0.00001)));
  float gradX = step(cornerCoord.y, cornerCoord.x);
  return sign(coord) * vec2(gradX, 1.0 - gradX);
}
vec4 sampleContent(vec2 coord) { return texture(content, clamp((origin + coord) / imageSize, 0.0, 1.0)); }
void main() {
  vec2 coord = FlutterFragCoord().xy;
  vec2 halfSize = size * 0.5;
  vec2 centeredCoord = coord - halfSize;
  float sd = sdRoundedRect(centeredCoord, halfSize, radius);
  if (-sd >= refractionHeight || refractionHeight <= 0.0) { fragColor = sampleContent(coord); return; }
  sd = min(sd, 0.0);
  float q = clamp(1.0 - -sd / refractionHeight, 0.0, 1.0);
  float d = (1.0 - sqrt(1.0 - q * q)) * -refractionAmount;
  float gradRadius = min(radius * 1.5, min(halfSize.x, halfSize.y));
  vec2 grad = normalize(gradSdRoundedRect(centeredCoord, halfSize, gradRadius));
  vec2 refractedCoord = coord + d * grad;
  vec2 dispersedCoord = d * grad * chromaticAberration * ((centeredCoord.x * centeredCoord.y) / (halfSize.x * halfSize.y));
  vec4 red = sampleContent(refractedCoord + dispersedCoord);
  vec4 orange = sampleContent(refractedCoord + dispersedCoord * (2.0 / 3.0));
  vec4 yellow = sampleContent(refractedCoord + dispersedCoord * (1.0 / 3.0));
  vec4 green = sampleContent(refractedCoord);
  vec4 cyan = sampleContent(refractedCoord - dispersedCoord * (1.0 / 3.0));
  vec4 blue = sampleContent(refractedCoord - dispersedCoord * (2.0 / 3.0));
  vec4 purple = sampleContent(refractedCoord - dispersedCoord);
  fragColor = vec4((red.r+orange.r+yellow.r)/3.5+purple.r/7.0,
    orange.g/7.0+(yellow.g+green.g+cyan.g)/3.5,
    (cyan.b+blue.b+purple.b)/3.0,
    (red.a+orange.a+yellow.a+green.a+cyan.a+blue.a+purple.a)/7.0);
}
