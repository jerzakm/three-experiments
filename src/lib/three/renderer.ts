import {
	WebGLRenderer,
	Scene,
	sRGBEncoding,
	PCFShadowMap,
	ACESFilmicToneMapping,
	Color
} from 'three';

export const initRenderer = (canvas: HTMLElement) => {
	const scene = new Scene();

	// Renderer
	const renderer = new WebGLRenderer({
		canvas,
		antialias: true,
		alpha: true
	});

	function updateRenderer() {
		renderer.setSize(window.innerWidth, window.innerHeight);
		renderer.setPixelRatio(Math.min(window.devicePixelRatio, 1)); // To avoid performance problems on devices with higher pixel ratio
	}

	window.addEventListener('resize', () => {
		updateRenderer();
	});

	updateRenderer();

	return { scene, renderer };
};

export const calcShaderPosition = (x: number, y: number, width: number, height: number) => {
	return {
		x: x / window.innerWidth - 0.5,
		y: y / window.innerHeight - 0.5,
		width: width / window.innerWidth,
		height: height / window.innerWidth
	};
};

// 902
