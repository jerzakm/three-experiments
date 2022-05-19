<script lang="ts">
	import { initRenderer } from '$lib/three/renderer';
	import { onMount } from 'svelte';

	import * as THREE from 'three';

	import { EffectComposer } from 'three/examples/jsm/postprocessing/EffectComposer';
	import { RenderPass } from 'three/examples/jsm/postprocessing/RenderPass';
	import { ShaderPass } from 'three/examples/jsm/postprocessing/ShaderPass';
	import { PixelShader } from 'three/examples/jsm/shaders/PixelShader.js';

	import vertexShader from './_shaders/vertex.glsl';
	import fragmentShader from './_shaders/fragment.glsl';

	let canvas: HTMLElement;

	onMount(() => {
		const { renderer, scene } = initRenderer(canvas);

		// Camera
		const imageAspect = 1;
		let a1 = 1,
			a2 = 1;
		const width = window.innerWidth;
		const height = window.innerHeight;

		const PARAMS = {
			progress: 0
		};

		if (height / width > imageAspect) {
			a1 = (width / height) * imageAspect;
			a2 = 1;
		} else {
			a1 = 1;
			a2 = (height / width) * imageAspect;
		}

		const camera = new THREE.OrthographicCamera(1 / -2, 1 / 2, 1 / 2, 1 / -2, 1, 1000);
		camera.position.set(0, 0, 2);

		// Lights
		const ambientLight = new THREE.AmbientLight(0xffffff, 0.5);
		scene.add(ambientLight);

		const directionalLight = new THREE.DirectionalLight('#ffffff', 1);
		directionalLight.castShadow = true;
		directionalLight.shadow.mapSize.set(1024, 1024);
		directionalLight.shadow.camera.far = 15;
		directionalLight.shadow.normalBias = 0.05;
		directionalLight.position.set(0.25, 2, 2.25);

		scene.add(directionalLight);

		let mouse = new THREE.Vector2();

		const shaderMaterial = new THREE.ShaderMaterial({
			uniforms: {
				time: { value: 0 },
				resolution: {
					value: new THREE.Vector4(width, height, a1, a2)
				},
				mouse: { value: mouse },
				matcap: {
					value: new THREE.TextureLoader().load('070B0C_B2C7CE_728FA3_5B748B.png')
				},
				progress: {
					value: 0
				}
			},
			vertexShader,
			fragmentShader,
			side: THREE.DoubleSide,
			extensions: {
				//@ts-ignore
				derivatives: '#extension GL_OES_standard_derivatives : enable'
			}
		});

		const plane = new THREE.Mesh(new THREE.PlaneGeometry(1, 1, 1, 1), shaderMaterial);

		// plane.rotation.set(-Math.PI / 2, 0, 0)
		plane.receiveShadow = true;
		scene.add(plane);

		const clock = new THREE.Clock();

		document.addEventListener('mousemove', (e) => {
			mouse.x = e.pageX / width - 0.5;
			mouse.y = -e.pageY / height + 0.5;
		});

		const loop = () => {
			const elapsedTime = clock.getElapsedTime();

			shaderMaterial.uniforms.time.value = elapsedTime;
			shaderMaterial.uniforms.mouse.value = mouse;
			shaderMaterial.uniforms.progress.value = PARAMS.progress;

			renderer.render(scene, camera);

			requestAnimationFrame(loop);
		};
		loop();
	});
</script>

<h1>Raymarching button</h1>

<canvas bind:this={canvas} />

<style>
	canvas {
		width: 100vw;
		height: 100vh;
		position: fixed;
	}
</style>
