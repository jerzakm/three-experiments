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

	let radials: any[] = [];
	const NUMBER_OF_BUTTONS = 8;

	let opened = false;

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

		// button - x,y,width,height - normalized to vector space!
		const btnVec = new THREE.Vector4();
		const btnRect = button.getBoundingClientRect();
		const btnShaderRect = calcShaderPosition(btnRect.x, btnRect.y, btnRect.width, btnRect.height);
		btnVec.set(btnShaderRect.x, btnShaderRect.y, btnShaderRect.width, btnShaderRect.height);

		const buttonProgress = {
			hovering: 0,
			pressing: 0,
			vector: new THREE.Vector4(0)
		};

		const onHoverEnter = anime({
			targets: buttonProgress,
			hovering: [0, 1],
			round: 10000,
			easing: 'linear',
			autoPlay: false,
			duration: 150,
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
			duration: 80,
			update: () => {
				buttonProgress.vector.setY(buttonProgress.pressing);
			}
		});
		const onButtonUp = anime({
			targets: buttonProgress,
			pressing: [1, 0],
			round: 10000,
			easing: 'linear',
			autoPlay: false,
			duration: 300,
			update: () => {
				buttonProgress.vector.setY(buttonProgress.pressing);
			}
		});

		buttonProgress.vector.set(0, 0, 0, 0);

		button.addEventListener('mouseover', () => {
			if (buttonProgress.hovering < 0.1) onHoverEnter.play();
		});

		button.addEventListener('mouseleave', () => {
			onHoverLeave.play();
		});

		button.addEventListener('mousedown', () => {
			if (buttonProgress.pressing < 0.01) onButtonDown.play();
		});

		button.addEventListener('mouseup', () => {
			onButtonUp.play();
		});

		const camera = new THREE.OrthographicCamera(1 / -2, 1 / 2, 1 / 2, 1 / -2, 1, 1000);
		camera.position.set(0, 0, 2);

		let mouse = new THREE.Vector2();

		for (let i = 0; i < NUMBER_OF_BUTTONS; i++) {
			const angle = ((Math.PI * 2) / NUMBER_OF_BUTTONS) * i - Math.PI;

			const r: any = {
				x: btnRect.x + btnRect.width / 3,
				y: btnRect.y + btnRect.height / 2,
				transformX: 0,
				transformY: 0,
				active: false,
				text: i,
				opacity: 1,
				size: 1,
				revealProgress: 0,
				element: document.createElement('button')
			};

			r.element.innerText = i;

			r.element.style.position = 'fixed';

			r.element.className = 'px-8 py-4 text-3xl font-bold';

			document.body.appendChild(r.element);

			const bbox = r.element.getBoundingClientRect();

			r.element.style.left = `${btnRect.x - bbox.width / 2 + btnRect.width / 2}px`;
			r.element.style.top = `${btnRect.y - bbox.height / 2 + btnRect.height / 2}px`;
			r.element.style.pointerEvents = 'none';
			r.element.style.opacity = 0;

			const animation = anime({
				targets: r,
				revealProgress: [0, 1],
				round: 10000,
				easing: 'spring(2, 80, 12, 5)',
				// easing: 'linear',
				loop: false,
				autoplay: false,
				duration: 500,
				update: () => {
					const d = 185;
					r.transformX = r.revealProgress * Math.sin(angle) * d;
					r.transformY = r.revealProgress * Math.cos(angle) * d;
					r.element.style.transform = `translate(${r.transformX}px,${r.transformY}px)`;
				}
			});

			r.animation = animation;

			radials.push(r);
		}

		radials = radials;

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
				},
				radials: { value: Array(NUMBER_OF_BUTTONS).fill(new THREE.Vector4(0)) }
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

			shaderMaterial.uniforms.time.value = elapsedTime;
			shaderMaterial.uniforms.mouse.value = mouse;
			shaderMaterial.uniforms.button.value = btnVec;
			shaderMaterial.uniforms.progress.value = buttonProgress.vector;

			const nUni = [];
			for (let i = 0; i < NUMBER_OF_BUTTONS; i++) {
				const bbox = radials[i].element.getBoundingClientRect();
				const unis = calcShaderPosition(bbox.x, bbox.y, bbox.width, bbox.height);
				nUni.push(new THREE.Vector4(unis.x, unis.y, unis.width, unis.height));
				radials[i].element.style.opacity = radials[i].revealProgress - 0.1;
			}

			shaderMaterial.uniforms.radials.value = nUni;

			renderer.render(scene, camera);

			requestAnimationFrame(loop);
		};
		loop();
	});

	function openRadial() {
		for (let i = 0; i < radials.length; i++) {
			const delay = 70;
			setTimeout(() => {
				if (opened) {
					radials[i].animation.reverse();
					radials[i].animation.play();
				} else {
					radials[i].animation.play();
					radials[i].animation.reverse();
				}
			}, i * delay);
		}
		opened = !opened;
	}
</script>

<canvas bind:this={canvas} />

<container>
	<h1 class="mt-16 font-bold text-5xl ">Raymarch goo button</h1>
	<button bind:this={button} on:click={openRadial}>{!opened ? 'Button' : 'Button'}</button>

	<span>Raymarching GLSL shader + some hacky js stuff</span>
</container>

<!-- {#each radials as radial}
	<button
		class="fixed"
		style={`left: ${radial.x}px; top: ${radial.y}px; transform: translate(${radial.transformX}px,${radial.transformY}px);`}
	>
		k
	</button>
{/each} -->
<style>
	:global(body) {
		overflow: hidden;
	}

	container {
		@apply flex flex-col content-between justify-between;
		height: 100vh;
		/* justify-content: center; */
		align-items: center;
	}

	button {
		@apply px-8 py-4 text-3xl font-bold;
		/* opacity: 0; */
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
