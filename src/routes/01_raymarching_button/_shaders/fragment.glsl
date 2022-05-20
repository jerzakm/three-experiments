uniform float time;
uniform sampler2D matcap;
uniform sampler2D btn;
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
    return distance(p, c) - r + texture2D(btn, p.xy + vec2(0.5)).r / ((1.) * 80.);
}

float textureStamp( vec3 p, vec3 b, float stampMod )
{
  vec3 q = abs(p) - b;
  vec2 size = normalize(vec2(246. ,64.));
  float tPoint = (texture2D(btn, (p.xy/(size*0.5) + vec2(0.5))).r);
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0) - tPoint * stampMod;
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
  vec3 p1 = rotate(p, vec3(1.,1.,0.), 0.4*progress.x);
  // p = p1;

  vec3 boxSize = vec3(button.zw*resolution.zw, 0.02) ;
  vec2 boxPos = vec2(button.xy*resolution.zw*2.) + boxSize.xy;
  float d = -boxSize.z*1.6+0.01;

  float box = sdRoundBox(p1 - vec3(boxPos.x, -boxPos.y, d), boxSize*0.9, .03);

  

  float final = box;

  

  if(progress.x>0.01){
    
    for(float i=0.; i < 8.; i++){
      float randOffset = rand(vec2(i,0.));
      float progr =  fract(time / 3. + randOffset*3.);
      vec2 pos = vec2(sin(randOffset*2.*PI*progr), cos(randOffset*2.*PI))*0.25 * progress.x;
      float bDist = distance(pos, boxPos);
      float gotoCenter = sdSphere(p1 - vec3(pos*progr, -0.1*bDist), 0.01*progress.x * (1.-progr));

      final = smin(final, gotoCenter, 0.08 );
    }
  }

  // float bgBox = sdBox(p+vec3(0.,0.,0.03), vec3(1., 1., 0.05));
  // final = smin(bgBox, final, 0.01);


  float commonH = 0.025;

  vec3 stampPos = p1+vec3(0., boxSize.y+0.01, 0.045*progress.y-0.019);
  vec3 stampSize =vec3(button.zw*resolution.zw * 0.9, 0.01);
  float stampMod = -0.012;
  
  float text = textureStamp(stampPos, stampSize, stampMod);
  float pressSub = sdRoundBox(p1 - vec3(boxPos.x, -boxPos.y, 0.085*-progress.y+0.09+commonH), boxSize*0.85, .03);

  float postSub = opSmoothSubtraction(pressSub, final, 0.01);

  return smin(postSub, text, 0.01);
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
    vec3 bg = mix(vec3(0.15, 0.15, 0.242), vec3(0.0), dist);

    vec2 newUV = (vUv - vec2(0.5)) * resolution.zw + vec2(0.5);
    vec3 camPos = vec3(0.,0.,2.);
    vec3 ray = normalize(vec3((vUv-vec2(0.5))  * resolution.zw , -1)) ;

    vec3 rayPos = camPos;

    float t=0.;
    float tMax = 5.;

    for(int i=0; i<256; ++i){
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