<script lang="ts">
	import { initRenderer } from '$lib/three/renderer';
	import { onMount } from 'svelte';

	import * as THREE from 'three';

	import matcap from './matcap.png';

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

		if (height / width > imageAspect) {
			a1 = (width / height) * imageAspect;
			a2 = 1;
		} else {
			a1 = 1;
			a2 = (height / width) * imageAspect;
		}

		const camera = new THREE.OrthographicCamera(1 / -2, 1 / 2, 1 / 2, 1 / -2, 1, 1000);
		camera.position.set(0, 0, 2);

		let mouse = new THREE.Vector2();

		const shaderMaterial = new THREE.ShaderMaterial({
			uniforms: {
				time: { value: 0 },
				resolution: {
					value: new THREE.Vector4(width, height, a1, a2)
				},
				mouse: { value: mouse },
				matcap: {
					value: new THREE.TextureLoader().load(matcap)
				}
			},
			vertexShader,
			fragmentShader,
			side: THREE.DoubleSide
		});

		const plane = new THREE.Mesh(new THREE.PlaneGeometry(1, 1, 1, 1), shaderMaterial);
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
		top: 0;
		left: 0;
		z-index: -1;
	}
</style>
