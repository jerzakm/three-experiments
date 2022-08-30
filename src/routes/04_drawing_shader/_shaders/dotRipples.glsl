//https://www.shadertoy.com/view/4dS3D1

uniform vec4 resolution;
uniform sampler2D tDiffuse;
uniform sampler2D bayer;
uniform float time;
varying vec2 vUv;

#define SEED1 -0.5775604999999985
#define SEED2 6.440483302499992

vec2 stepnoise(vec2 p, float size) {
    p += 10.0;
    float x = floor(p.x/size)*size;
    float y = floor(p.y/size)*size;
    
    x = fract(x*0.1) + 1.0 + x*0.0002;
    y = fract(y*0.1) + 1.0 + y*0.0003;
    
    float a = fract(1.0 / (0.000001*x*y + 0.00001));
    a = fract(1.0 / (0.000001234*a + 0.00001));
    
    float b = fract(1.0 / (0.000002*(x*y+x) + 0.00001));
    b = fract(1.0 / (0.0000235*b + 0.00001));
    
    return vec2(a, b);   
}
float tent(float f) {
    return 1.0 - abs(fract(f)-0.5)*2.0;
}

float mask(vec2 p) {
    vec2 r = stepnoise(p, 0.8);
    p[0] += r[0];
    p[1] += r[1];
    
    float f1 = tent(p[0]*SEED1 + p[1]/(SEED1+0.5));
    float f2 = tent(p[1]*SEED2 + p[0]/(SEED2+0.5));
    float f = f1*f2;
    
    //f = pow(f, 4.0)*1.4 + f*0.2;
    f = sqrt(f);
    return f;
}


void main() {

  // vec4 o = texture2D(tDiffuse, vUv);

	// gl_FragColor = o;

  vec2 uv = gl_FragCoord.xy;
  vec2 uv2 = gl_FragCoord.xy / resolution.xy;
  
  
  float f = texture2D(tDiffuse, gl_FragCoord.xy / resolution.xy)[0];
  float slide = tent(-0.0*time+uv2[0]*0.5);
  
  float c = mask(uv);
  
  if (uv2[1] < 0.1) {
      f = slide;
  }
  
  c = float(f > c);


  vec3 TL = texture2D(tDiffuse, uv2 + vec2(-1, 1)/ resolution.xy).rgb;
  vec3 TM = texture2D(tDiffuse, uv2 + vec2(0, 1)/ resolution.xy).rgb;
  vec3 TR = texture2D(tDiffuse, uv2 + vec2(1, 1)/ resolution.xy).rgb;
  
  vec3 ML = texture2D(tDiffuse, uv2 + vec2(-1, 0)/ resolution.xy).rgb;
  vec3 MR = texture2D(tDiffuse, uv2 + vec2(1, 0)/ resolution.xy).rgb;
  
  vec3 BL = texture2D(tDiffuse, uv2 + vec2(-1, -1)/ resolution.xy).rgb;
  vec3 BM = texture2D(tDiffuse, uv2 + vec2(0, -1)/ resolution.xy).rgb;
  vec3 BR = texture2D(tDiffuse, uv2 + vec2(1, -1)/ resolution.xy).rgb;
                        
  vec3 GradX = -TL + TR - 2.0 * ML + 2.0 * MR - BL + BR;
  vec3 GradY = TL + 2.0 * TM + TR - BL - 2.0 * BM - BR;



  float r = length(vec2(GradX.r, GradY.r));
  float g = length(vec2(GradX.g, GradY.g));
  float b = length(vec2(GradX.b, GradY.b));


  // gl_FragColor = vec4(d.r,d.r,d.r, o.a);
  // gl_FragColor = vec4(r,g,b, o.a);


  //   //c = f;

  if(r > 0.2){

	gl_FragColor = vec4(vec3(1.-r), 1.0);
  } else {
    gl_FragColor = vec4(c, c, c, 1.0);
  }
    

	
	
			
}
	