uniform float time;
uniform float progress;
uniform sampler2D matcap;
uniform vec4 resolution;
uniform vec2 mouse;
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

float sdBox( vec3 p, vec3 b )
{
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

float rand(vec2 co){
  return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

float sdf(vec3 p){

  vec3 p1 = rotate(vec3(p), vec3(1.), time / 2.);
  float box = smin(sdBox(p1, vec3(0.2)), sdSphere(p, 0.2), 0.2);
  float realsphere = sdSphere(p1, (0.2));
  float final = mix(box,realsphere, progress);

  
  for(float i=0.; i < 10.; i++){
    float randOffset = rand(vec2(i,0.));
    float progr = 1. - fract(time / 2. + randOffset*3.);
    vec3 pos = vec3(sin(randOffset*2.*PI), cos(randOffset*2.*PI), 0.);
    float gotoCenter = sdSphere(p - pos*progr, 0.08);

    final = smin(final, gotoCenter, 0.3);
  }

  

  float mouseSphere = sdSphere((p - vec3(mouse*resolution.zw*2., 0.)), .1);


  return smin(final,mouseSphere, .2);
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
    vec3 bg = mix(vec3(0.75, 0.65, 0.62), vec3(0.0), dist);

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