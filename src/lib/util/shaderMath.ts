/**
 * @description Takes in screen coordinates and returns glsl position,
 * for example a position of x: 500, y: 600, on a 1000x1000 pixel screen would be vec2(0.0, 0.1)
 */
export const calcShaderPosition = (x: number, y: number, width: number, height: number) => {
	return {
		x: x / window.innerWidth - 0.5,
		y: y / window.innerHeight - 0.5,
		width: width / window.innerWidth,
		height: height / window.innerHeight
	};
};
