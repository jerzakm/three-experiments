<script lang="ts">
	import { calcShaderPosition, initRenderer } from '$lib/three/renderer';
	import { onMount } from 'svelte';

	import * as THREE from 'three';

	import matcap from './matcap.png';

	import vertexShader from './_shaders/vertex.glsl';
	import fragmentShader from './_shaders/fragment.glsl';

	let canvas: HTMLElement;
	let button: HTMLElement;

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

		// button - x,y,width,height - normalized to vector space!
		const btnVec = new THREE.Vector4();
		const btnRect = button.getBoundingClientRect();
		const btnShaderRect = calcShaderPosition(btnRect.x, btnRect.y, btnRect.width, btnRect.height);
		btnVec.set(btnShaderRect.x, btnShaderRect.y, btnShaderRect.width, btnShaderRect.height);

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
				},
				button: {
					value: btnVec
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
			shaderMaterial.uniforms.button.value = btnVec;

			renderer.render(scene, camera);

			requestAnimationFrame(loop);
		};
		loop();
	});
</script>

<h1>Raymarching button</h1>

<canvas bind:this={canvas} />

<container>
	<button bind:this={button}>Gooeybooey</button>
</container>

<style>
	:global(body) {
		overflow: hidden;
	}

	container {
		display: flex;
		height: 100vh;
		justify-content: center;
		align-items: center;
	}
	button {
		@apply border-black border-solid border-2 px-8 py-4 text-3xl font-bold;
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
