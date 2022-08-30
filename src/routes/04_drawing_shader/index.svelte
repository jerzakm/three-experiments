<script lang="ts">
	import { calcShaderPosition, initRenderer } from '$lib/three/renderer';
	import { onMount } from 'svelte';

	import * as THREE from 'three';
	import { OrbitControls } from 'three/examples/jsm/controls/OrbitControls.js';

	import { EffectComposer } from 'three/examples/jsm/postprocessing/EffectComposer.js';
	import { RenderPass } from 'three/examples/jsm/postprocessing/RenderPass.js';
	import { ShaderPass } from 'three/examples/jsm/postprocessing/ShaderPass.js';
	import { FontLoader } from 'three/examples/jsm/loaders/FontLoader.js';
	import { TextGeometry } from 'three/examples/jsm/geometries/TextGeometry.js';

	import vertexShader from './_shaders/ditherVert.glsl';
	import ditherFrag2 from './_shaders/ditherFrag2.glsl';
	import dotRipples from './_shaders/dotRipples.glsl';
	import { ACESFilmicToneMapping, PCFShadowMap, sRGBEncoding } from 'three';

	import bayer from './bayer.png';

	let canvas: HTMLElement;

	onMount(async () => {
		const { renderer, scene } = initRenderer(canvas);

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

		const controls = new OrbitControls(camera, renderer.domElement);
		controls.listenToKeyEvents(window); // optional
		controls.enableDamping = true; // an animation loop is required when either damping or auto-rotation are enabled
		controls.dampingFactor = 0.05;

		controls.screenSpacePanning = false;

		controls.minDistance = 10;
		controls.maxDistance = 500;

		controls.maxPolarAngle = Math.PI / 2;

		controls.keys = {
			LEFT: 'ArrowLeft', //left arrow
			UP: 'ArrowUp', // up arrow
			RIGHT: 'ArrowRight', // right arrow
			BOTTOM: 'ArrowDown' // down arrow
		};

		let mouse = new THREE.Vector2();

		const clock = new THREE.Clock();

		const loader = new FontLoader();

		loader.load('/nimbus.json', function (font) {
			const geometry1 = new TextGeometry('BRUTALISM', {
				font: font,
				size: 1.25,
				height: 0.355,
				curveSegments: 15,
				bevelEnabled: false,
				bevelThickness: 0.15,
				bevelSize: 0.05,
				bevelOffset: 0,
				bevelSegments: 2
			});

			// geometry.computeBoundingBox();

			const material1 = new THREE.MeshPhongMaterial({ color: 0xffff12, flatShading: true });

			const text1 = new THREE.Mesh(geometry1, material1);
			scene.add(text1);

			const geometry2 = new TextGeometry(
				`aka happy little coding mistakes\naka tfw something gets so ugly \n       it's starting to look good again`,
				{
					font: font,
					size: 0.35,
					height: 0.05,
					curveSegments: 15,
					bevelEnabled: false,
					bevelThickness: 0.15,
					bevelSize: 0.05,
					bevelOffset: 0,
					bevelSegments: 2
				}
			);

			// geometry.computeBoundingBox();

			const material2 = new THREE.MeshPhongMaterial({ color: 0x00ff3f, flatShading: true });

			const text2 = new THREE.Mesh(geometry2, material1);
			scene.add(text2);

			text1.rotateY(1.2);
			text1.rotateX(0.45);
			text1.position.set(-18, 1, 5);
			text2.rotateY(1.2);
			text2.rotateX(0.2);
			text2.position.set(-15, 0, 4);
		});

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

		// const geometry = new THREE.BoxGeometry(4, 4, 1);
		// const box = new THREE.Mesh(geometry, material);
		// scene.add(box);
		// box.position.set(0.5, 1, -2);

		const boxes: THREE.Mesh[] = [];

		const boxCount = 256;
		const boxSize = 0.5;
		const layerGap = 0.1;

		camera.position.set(boxCount * layerGap + 3, 0, 0);
		// camera.position.set(0.1, 0, 0);

		for (let i = 0; i < boxCount; i++) {
			const material = new THREE.MeshStandardMaterial({
				color: 0xffffff,
				metalness: Math.random(),
				roughness: 1
				// envMap: cubeTexture,
				// envMapIntensity: API.envMapIntensity,
			});
			const geometry = new THREE.BoxGeometry(boxSize, boxSize, boxSize);
			const box = new THREE.Mesh(geometry, material);
			scene.add(box);
			box.position.set(i * layerGap, Math.sin(i), Math.cos(i));

			boxes.push(box);
		}

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

		const composer = new EffectComposer(renderer);
		const renderPass = new RenderPass(scene, camera);
		composer.addPass(renderPass);

		// you might want to use a gaussian blur filter before
		// the next pass to improve the result of the Sobel operator

		const dotRipplesShader = {
			uniforms: {
				tDiffuse: { value: null },
				opacity: { value: 1.0 },
				resolution: {
					value: new THREE.Vector4(width, height, a1, a2)
				},
				bayer: {
					value: new THREE.TextureLoader().load(bayer)
				},
				time: { value: 0.0 }
			},
			vertexShader,
			fragmentShader: dotRipples
		};

		const ditherShader2 = {
			uniforms: {
				tDiffuse: { value: null },
				opacity: { value: 1.0 },
				resolution: {
					value: new THREE.Vector4(width, height, a1, a2)
				}
			},
			vertexShader,
			fragmentShader: ditherFrag2
		};

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

			camera.aspect = width / height;

			camera.updateProjectionMatrix();

			ditherShader2.uniforms.resolution.value.set(width, height, a1, a2);
		});

		const dotRipplesPass = new ShaderPass(dotRipplesShader);
		composer.addPass(dotRipplesPass);

		const ditherOutlined2 = new ShaderPass(ditherShader2);
		// composer.addPass(ditherOutlined2);

		const loop = () => {
			try {
				const elapsedTime = clock.getElapsedTime();
				controls.update();
				composer.render();

				for (let i = 0; i < boxes.length; i++) {
					// boxes[i].rotateX(Math.sin((elapsedTime * i * 2) / 1000000));
					boxes[i].position.x = i * layerGap + Math.sin(elapsedTime + 100 * i) * 0.1;
					boxes[i].rotation.x += Math.max(0, Math.sin(elapsedTime + 1000 * i) / 100);
					// boxes[i].rotation.x += Math.sin(i) * clock.getDelta() * 1000000;
				}

				dotRipplesShader.uniforms.time.value = elapsedTime;

				requestAnimationFrame(loop);
			} catch (e) {
				console.log(e);
			}
		};
		loop();
	});
</script>

<canvas bind:this={canvas} />

<style>
	:global(body) {
		overflow: hidden;
		/* background: #ff0000; */
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
