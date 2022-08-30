uniform float time;
uniform sampler2D matcap;
uniform sampler2D btn;
uniform vec4[8] radials;
uniform vec4 button;
uniform vec4 resolution;
uniform vec2 mouse;
// x - hover, y - click
uniform vec4 progress;
varying vec2 vUv;

mat4 rotationMatrix(vec3 axis, float angle) {
    axis = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float oc = 1.0 - c;
    
    return mat4(oc * axis.x * axis.x + c,           oc * axis.x * axis.y - axis.z * s,  oc * axis.z * axis.x + axis.y * s,  0.0,
                oc * axis.x * axis.y + axis.z * s,  oc * axis.y * axis.y + c,           oc * axis.y * axis.z - axis.x * s,  0.0,
                oc * axis.z * axis.x - axis.y * s,  oc * axis.y * axis.z + axis.x * s,  oc * axis.z * axis.z + c,           0.0,
                0.0,                                0.0,                                0.0,                                1.0);
}

vec3 rotate(vec3 v, vec3 axis, float angle) {
	mat4 m = rotationMatrix(axis, angle);
	return (m * vec4(v, 1.0)).xyz;
}

float smin( float a, float b, float k )
{
    float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}

vec2 getMatcap(vec3 eye, vec3 normal){
  vec3 reflected = reflect(eye, normal);
  float m = 2.824271247461903 * sqrt(reflected.z+1.0);
  return reflected.xy / m +0.5;
}

float PI = 3.14159265;

float sdSphere(vec3 p, float r){
  return length(p)-r;
}

float sdfSphere(vec3 c, float r, vec3 p)
{
    // return distance(p, c) - r + texture2D(btn, p.xy + vec2(0.5)).r / ((1.) * 80.);
    return distance (p,c)-r;
}

float textureStamp( vec3 p, vec3 b, float stampMod )
{
  vec3 q = abs(p) - b;
  vec2 size = normalize(vec2(246. ,64.));
  float tPoint = (texture2D(btn, (p.xy/(size*0.5) + vec2(0.5))).r);

  // return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0) - tPoint * stampMod;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

float sdRoundBox( vec3 p, vec3 b, float r )
{
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0) - r;
}

float sdBox( vec3 p, vec3 b )
{
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

float rand(vec2 co){
  return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453);
}


float opSmoothUnion( float d1, float d2, float k ) {
    float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) - k*h*(1.0-h); }

float opSmoothSubtraction( float d1, float d2, float k ) {
    float h = clamp( 0.5 - 0.5*(d2+d1)/k, 0.0, 1.0 );
    return mix( d2, -d1, h ) + k*h*(1.0-h); }

float opSmoothIntersection( float d1, float d2, float k ) {
    float h = clamp( 0.5 - 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) + k*h*(1.0-h); }

float sdf(vec3 p){    

  vec2 boxPos = vec2(button.xy*resolution.zw*2.) + button.zw;
  float d = -button.z*1.6+0.01;

  float mainSize = max(button.z, button.w)*0.9;

  float sphere = sdSphere(p - vec3(boxPos.x, -boxPos.y, d), mainSize);
  float box = sdRoundBox(p - vec3(boxPos.x, -boxPos.y, -mainSize), vec3(mainSize),0.01);

  float boxSub = sdRoundBox(p - vec3(boxPos.x, -boxPos.y, 0.2-0.125*progress.x-0.02*progress.y), vec3(mainSize*0.95-mainSize*0.3*progress.y),0.01);

  box = opSmoothSubtraction(boxSub, box, 0.01);

  float final = box;

  for(int i = 0; i < radials.length(); i++){
    vec4 r = radials[i];
    float d = min(distance(vec2(0), vec2(-r.x*2. - r.z, r.y + r.w))*8.,1.);    
    float depth = 0.2 - d* 0.2;    

    float mouseD = distance(mouse, vec2(-r.x*2. - r.z, r.y + r.w));

    if(d>0.01){
      float radialSphere = sdSphere(p + vec3(-r.x*2. - r.z, r.y + r.w, depth), r.z*1.5*d);
      float radialSphereSub = sdSphere(p + vec3(-r.x*2. - r.z, r.y + r.w, depth+r.z*d), r.z*1.5*d);
      float sub = opSmoothSubtraction(radialSphere, radialSphereSub, 0.01);
      final = smin(final, sub, 0.05);


      // vec3 p1 = rotate(p, vec3(0., 1.,1.), sin(time+100.*float(i))*0.3);
      // float radialSquare = sdBox(p1 + vec3(-r.x*2. - r.z, r.y + r.w, depth), vec3(r.z));
      // final = smin(final, radialSquare, 0.05);
    }        
  }


  
  // float boxHover = opSmoothSubtraction(boxSub, final, 0.01);
  // return boxHover;
  return final;
}



vec3 calcNormal( in vec3 p ) // for function f(p)
{
    const float eps = 0.0001; // or some other value
    const vec2 h = vec2(eps,0);
    return normalize( vec3(sdf(p+h.xyy) - sdf(p-h.xyy),
                          sdf(p+h.yxy) - sdf(p-h.yxy),
                          sdf(p+h.yyx) - sdf(p-h.yyx) ) );
}


void main() 
{ 
    float dist = length(vUv - vec2(0.5));
    vec3 bg = mix(vec3(.15, 0.15, 0.13), vec3(0.0), dist);

    vec2 newUV = (vUv - vec2(0.5)) * resolution.zw + vec2(0.5);
    vec3 camPos = vec3(0.,0.,2.);
    vec3 ray = normalize(vec3((vUv-vec2(0.5))  * resolution.zw , -1)) ;

    vec3 rayPos = camPos;

    float t=0.;
    float tMax = 5.;

    for(int i=0; i<128; ++i){
      vec3 pos = camPos + t*ray;
      float h = sdf(pos);
      if(h<0.0001 || t>tMax) break;
      t+=h;
    }

    vec3 color = bg;
    if(t<tMax){
      vec3 pos = camPos + t*ray;
      color = vec3(1.);
      vec3 normal = calcNormal(pos);
      color = normal;
      float diff = dot(vec3(1.), normal);
      vec2 matcapUV = getMatcap(ray, normal);
      color = vec3(diff);
      color = texture2D(matcap, matcapUV).rgb;

      float fresnel = pow(1. + dot(ray,normal), 3.);
      
      // color = vec3(fresnel);
      // color = mix(color,bg, 1.- fresnel);
      color = mix(color,bg, fresnel);

    }


    gl_FragColor = vec4(color, 1.0);
}