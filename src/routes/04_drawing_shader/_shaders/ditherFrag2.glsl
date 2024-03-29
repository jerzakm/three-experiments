//https://www.shadertoy.com/view/4dS3D1

uniform vec4 resolution;
uniform sampler2D tDiffuse;
uniform sampler2D bayer;
varying vec2 vUv;



const mat4 bayertl = mat4( 
 0.0/64.0, 32.0/64.0,  8.0/64.0, 40.0/64.0,
48.0/64.0, 16.0/64.0, 56.0/64.0, 24.0/64.0,
12.0/64.0, 44.0/64.0,  4.0/64.0, 36.0/64.0,
60.0/64.0, 28.0/64.0, 52.0/64.0, 20.0/64.0
);

const mat4 bayertr = mat4( 
 2.0/64.0, 34.0/64.0, 10.0/64.0, 42.0/64.0,
50.0/64.0, 18.0/64.0, 58.0/64.0, 26.0/64.0,
14.0/64.0, 46.0/64.0,  6.0/64.0, 38.0/64.0,
62.0/64.0, 30.0/64.0, 54.0/64.0, 22.0/64.0
);

const mat4 bayerbl = mat4( 
 3.0/64.0, 35.0/64.0, 11.0/64.0, 43.0/64.0,
51.0/64.0, 19.0/64.0, 59.0/64.0, 27.0/64.0,
15.0/64.0, 47.0/64.0,  7.0/64.0, 39.0/64.0,
63.0/64.0, 31.0/64.0, 55.0/64.0, 23.0/64.0
);
	
const mat4 bayerbr = mat4( 
 1.0/64.0, 33.0/64.0,  9.0/64.0, 41.0/64.0,
49.0/64.0, 17.0/64.0, 57.0/64.0, 25.0/64.0,
13.0/64.0, 45.0/64.0,  5.0/64.0, 37.0/64.0,
61.0/64.0, 29.0/64.0, 53.0/64.0, 21.0/64.0
);

float dither( mat4 m, ivec2 p )
{
	if( p.y == 0 ) 
	{
		if( p.x == 0 ) return m[0][0];
		else if( p.x == 1 ) return m[1][0];
		else if( p.x == 2 ) return m[2][0];
		else return m[3][0];	
	}	
	else if( p.y == 1 ) 
	{
		if( p.x == 0 ) return m[0][1];
		else if( p.x == 1 ) return m[1][1];
		else if( p.x == 2 ) return m[2][1];
		else return m[3][1];	
	}	
	else if( p.y == 2 ) 
	{
		if( p.x == 0 ) return m[0][1];
		else if( p.x == 1 ) return m[1][2];
		else if( p.x == 2 ) return m[2][2];
		else return m[3][2];	
	}	
	else 
	{
		if( p.x == 0 ) return m[0][3];
		else if( p.x == 1 ) return m[1][3];
		else if( p.x == 2 ) return m[2][3];
		else return m[3][3];	
	}	
}


void main() {

  vec4 o = texture2D(tDiffuse, vUv);

  
  // o = step(texture(iChannel0, i/8.).r, texture(iChannel1,i/resolution.xy));

  ivec2 p = ivec2(mod( gl_FragCoord.xy, 2.0 ));
	vec3 c = texture2D( tDiffuse, vUv ).xyz;
	c = pow( c, vec3(1.5) );	
	c -= 0.0/255.0;
	
  vec3 d = vec3(0.0);
	if( p.x <= 3 && p.y <= 3 )
	{
		d.r = float( c.r > dither( bayertl, p ) );
		d.g = float( c.g > dither( bayertl, p ) );
		d.b = float( c.b > dither( bayertl, p ) );
	}
	else if ( p.x > 3 && p.y <= 3 )
	{
		d.r = float( c.r > dither( bayertr, p -ivec2(4,0) ) );
		d.g = float( c.g > dither( bayertr, p -ivec2(4,0) ) );
		d.b = float( c.b > dither( bayertr, p -ivec2(4,0) ) );
	}
	else if( p.x <= 3 && p.y > 3 )
	{
		d.r = float( c.r > dither( bayerbl, p-ivec2(0,4)  ) );
		d.g = float( c.g > dither( bayerbl, p-ivec2(0,4)  ) );
		d.b = float( c.b > dither( bayerbl, p-ivec2(0,4)  ) );
	}
	else if ( p.x > 3 && p.y > 3 )
	{
		d.r = float( c.r > dither( bayerbr, p -ivec2(4,4) ) );
		d.g = float( c.g > dither( bayerbr, p -ivec2(4,4) ) );
		d.b = float( c.b > dither( bayerbr, p -ivec2(4,4) ) );
	}


    vec3 TL = texture2D(tDiffuse, vUv + vec2(-1, 1)/ resolution.xy).rgb;
    vec3 TM = texture2D(tDiffuse, vUv + vec2(0, 1)/ resolution.xy).rgb;
    vec3 TR = texture2D(tDiffuse, vUv + vec2(1, 1)/ resolution.xy).rgb;
    
    vec3 ML = texture2D(tDiffuse, vUv + vec2(-1, 0)/ resolution.xy).rgb;
    vec3 MR = texture2D(tDiffuse, vUv + vec2(1, 0)/ resolution.xy).rgb;
    
    vec3 BL = texture2D(tDiffuse, vUv + vec2(-1, -1)/ resolution.xy).rgb;
    vec3 BM = texture2D(tDiffuse, vUv + vec2(0, -1)/ resolution.xy).rgb;
    vec3 BR = texture2D(tDiffuse, vUv + vec2(1, -1)/ resolution.xy).rgb;
                         
    vec3 GradX = -TL + TR - 2.0 * ML + 2.0 * MR - BL + BR;
    vec3 GradY = TL + 2.0 * TM + TR - BL - 2.0 * BM - BR;

  

    float r = length(vec2(GradX.r, GradY.r));
    float g = length(vec2(GradX.g, GradY.g));
    float b = length(vec2(GradX.b, GradY.b));


  // gl_FragColor = vec4(d.r,d.r,d.r, o.a);
  // gl_FragColor = vec4(r,g,b, o.a);

  vec3 final = vec3(d.r, d.g, d.b);

  if(r>0.1){
    float col = 1.-(r+g+b)/3.;

    col = 0.0;
    
    gl_FragColor = vec4(col,col,col, o.a);
  } else {

    gl_FragColor = vec4(final, o.a);
  }

	
	
	// //c=texture( iChannel0, uv ).xyz;
	// fragColor = vec4(d, 1.0);
			
}
	