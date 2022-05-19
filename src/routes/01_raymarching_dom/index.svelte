<script lang="ts">
	import { calcShaderPosition, initRenderer } from '$lib/three/renderer';
	import { onMount } from 'svelte';
	import anime from 'animejs';

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
		let width = window.innerWidth;
		let height = window.innerHeight;

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

		const buttonProgress = {
			hovering: 0,
			pressing: 0,
			vector: new THREE.Vector4()
		};

		let animation: anime.AnimeInstance;

		const onHoverEnter = anime({
			targets: buttonProgress,
			hovering: [0, 1],
			round: 10000,
			easing: 'linear',
			autoPlay: false,
			duration: 150,
			change: () => {
				buttonProgress.vector.setX(buttonProgress.hovering);
			},
			update: () => {
				buttonProgress.vector.setX(buttonProgress.hovering);
			}
		});
		const onHoverLeave = anime({
			targets: buttonProgress,
			hovering: [1, 0],
			round: 10000,
			easing: 'linear',
			autoPlay: false,
			duration: 150,
			change: () => {
				buttonProgress.vector.setX(buttonProgress.hovering);
			},
			update: () => {
				buttonProgress.vector.setX(buttonProgress.hovering);
			}
		});

		const onButtonDown = anime({
			targets: buttonProgress,
			pressing: [0, 1],
			round: 10000,
			easing: 'linear',
			autoPlay: false,
			duration: 100,
			change: () => {
				buttonProgress.vector.setY(buttonProgress.pressing);
			}
		});
		const onButtonUp = anime({
			targets: buttonProgress,
			pressing: [1, 0],
			round: 10000,
			easing: 'linear',
			autoPlay: false,
			duration: 100,
			change: () => {
				buttonProgress.vector.setY(buttonProgress.pressing);
			}
		});

		button.addEventListener('mouseover', () => {
			console.log('enter');
			onHoverEnter.play();
		});

		button.addEventListener('mouseleave', () => {
			onHoverLeave.play();
		});

		button.addEventListener('mousedown', () => {
			onButtonDown.play();
		});

		button.addEventListener('mouseup', () => {
			onButtonUp.play();
		});

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
				progress: { value: buttonProgress.vector },
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
			const { x, y } = calcShaderPosition(e.pageX, e.pageY, 0, 0);
			mouse.x = -x;
			mouse.y = y;
		});

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

			shaderMaterial.uniforms.resolution.value = new THREE.Vector4(width, height, a1, a2);
			const btnRect = button.getBoundingClientRect();
			const btnShaderRect = calcShaderPosition(btnRect.x, btnRect.y, btnRect.width, btnRect.height);
			btnVec.set(btnShaderRect.x, btnShaderRect.y, btnShaderRect.width, btnShaderRect.height);
		});

		const loop = () => {
			const elapsedTime = clock.getElapsedTime();

			if (animation) {
				//@ts-ignore
				// animation.tick();
			}

			shaderMaterial.uniforms.time.value = elapsedTime;
			shaderMaterial.uniforms.mouse.value = mouse;
			shaderMaterial.uniforms.button.value = btnVec;
			shaderMaterial.uniforms.progress.value = buttonProgress.vector;

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
