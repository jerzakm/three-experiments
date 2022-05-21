<script lang="ts">
	import { calcShaderPosition, initRenderer } from '$lib/three/renderer';
	import { onMount } from 'svelte';

	import * as THREE from 'three';
	import { OrbitControls } from 'three/examples/jsm/controls/OrbitControls.js';

	import { EffectComposer } from 'three/examples/jsm/postprocessing/EffectComposer.js';
	import { RenderPass } from 'three/examples/jsm/postprocessing/RenderPass.js';
	import { ShaderPass } from 'three/examples/jsm/postprocessing/ShaderPass.js';

	import { LuminosityShader } from 'three/examples/jsm/shaders/LuminosityShader.js';
	import { SobelOperatorShader } from 'three/examples/jsm/shaders/SobelOperatorShader.js';

	import vertexShader from './_shaders/ditherVert.glsl';
	import fragmentShader from './_shaders/ditherFrag.glsl';
	import { ACESFilmicToneMapping, PCFShadowMap, sRGBEncoding } from 'three';

	let canvas: HTMLElement;
	let button: HTMLElement;

	onMount(async () => {
		const { renderer, scene } = initRenderer(canvas);

		const { getProject } = await import('@theatre/core');
		const studio = await import('@theatre/studio');
		studio.default.initialize();

		const objValues = { foo: 0, bar: true, baz: 'A string' };

		// Camera
		const imageAspect = 1;
		let a1 = 1,
			a2 = 1;
		let width = window.innerWidth;
		let height = window.innerHeight;

		if (height / width > imageAspect) {
			a1 = (width / height) * imageAspect;
			a2 = 1;
		} else {
			a1 = 1;
			a2 = (height / width) * imageAspect;
		}

		// camera
		const camera = new THREE.PerspectiveCamera(40, window.innerWidth / window.innerHeight, 1, 1000);
		camera.position.set(0, 0, 30);

		const controls = new OrbitControls(camera, renderer.domElement);
		controls.listenToKeyEvents(window); // optional
		controls.enableDamping = true; // an animation loop is required when either damping or auto-rotation are enabled
		controls.dampingFactor = 0.05;

		controls.screenSpacePanning = false;

		controls.minDistance = 10;
		controls.maxDistance = 500;

		controls.maxPolarAngle = Math.PI / 2;

		let mouse = new THREE.Vector2();

		const clock = new THREE.Clock();

		document.addEventListener('mousemove', (e) => {
			const { x, y } = calcShaderPosition(e.pageX, e.pageY, 0, 0);
			mouse.x = -x;
			mouse.y = y;
		});

		const API = {
			lightProbeIntensity: 1.0,
			directionalLightIntensity: 0.2,
			envMapIntensity: 1
		};

		const material = new THREE.MeshStandardMaterial({
			color: 0xff0000,
			metalness: 0.0,
			roughness: 0.85
			// envMap: cubeTexture,
			// envMapIntensity: API.envMapIntensity,
		});

		const matBg = new THREE.MeshStandardMaterial({
			color: 0x121212,
			metalness: 0.0,
			roughness: 0.85
			// envMap: cubeTexture,
			// envMapIntensity: API.envMapIntensity,
		});

		const geometry = new THREE.BoxGeometry(20, 5, 1);

		const box = new THREE.Mesh(geometry, material);
		// box.castShadow = true;
		// box.receiveShadow = true;
		scene.add(box);

		const background = new THREE.Mesh(new THREE.PlaneGeometry(50, 50), matBg);
		background.position.set(0, 0, -10);
		scene.add(background);

		//const geometry = new THREE.TorusKnotGeometry( 4, 1.5, 256, 32, 2, 3 );

		// mesh

		// light
		const directionalLight = new THREE.DirectionalLight(0xffffff, 2);
		directionalLight.position.set(18, 0, 15);
		directionalLight.castShadow = true;
		scene.add(directionalLight);

		const point = new THREE.PointLight(0xffffff, 1, 20);
		point.position.set(5, 0, 5);
		scene.add(point);

		const ambient = new THREE.AmbientLight(0xffffff, 1);
		scene.add(ambient);

		renderer.shadowMap.enabled = true;
		renderer.shadowMap.type = PCFShadowMap;
		renderer.physicallyCorrectLights = true;
		renderer.outputEncoding = sRGBEncoding;
		renderer.toneMapping = ACESFilmicToneMapping;
		renderer.toneMappingExposure = 1;

		window.addEventListener('resize', () => {
			width = window.innerWidth;
			height = window.innerHeight;

			if (height / width > imageAspect) {
				a1 = (width / height) * imageAspect;
				a2 = 1;
			} else {
				a1 = 1;
				a2 = (height / width) * imageAspect;
			}
		});

		const composer = new EffectComposer(renderer);
		const renderPass = new RenderPass(scene, camera);
		composer.addPass(renderPass);

		// color to grayscale conversion

		const effectGrayScale = new ShaderPass(LuminosityShader);
		// composer.addPass(effectGrayScale);

		// you might want to use a gaussian blur filter before
		// the next pass to improve the result of the Sobel operator

		// Sobel operator

		const effectSobel = new ShaderPass(SobelOperatorShader);
		effectSobel.uniforms['resolution'].value.x = window.innerWidth * window.devicePixelRatio;
		effectSobel.uniforms['resolution'].value.y = window.innerHeight * window.devicePixelRatio;
		// composer.addPass(effectSobel);

		const ditherShader = {
			uniforms: {
				tDiffuse: { value: null },
				opacity: { value: 1.0 },
				resolution: {
					value: new THREE.Vector4(width, height, a1, a2)
				}
			},
			vertexShader,
			fragmentShader
		};

		const ditherPass = new ShaderPass(ditherShader);
		composer.addPass(ditherPass);

		const loop = () => {
			const elapsedTime = clock.getElapsedTime();
			controls.update();
			// renderer.render(scene, camera);
			composer.render();

			requestAnimationFrame(loop);
		};
		loop();
	});
</script>

<canvas bind:this={canvas} />

<style>
	:global(body) {
		overflow: hidden;
	}

	canvas {
		width: 100vw;
		height: 100vh;
		position: fixed;
		top: 0;
		left: 0;
		z-index: -1;
	}
</style>
