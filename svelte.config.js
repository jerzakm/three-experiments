// import adapter from '@sveltejs/adapter-auto';
import adapter from '@sveltejs/adapter-static';
import preprocess from 'svelte-preprocess';
import glsl from 'vite-plugin-glsl';
import { threeMinifier } from '@yushijinhun/three-minifier-rollup';

/** @type {import('@sveltejs/kit').Config} */
const config = {
	// Consult https://github.com/sveltejs/svelte-preprocess
	// for more information about preprocessors
	preprocess: preprocess(),

	kit: {
		adapter: adapter(),
		prerender: {
			enabled: false
		},
		vite: {
			plugins: [{ ...threeMinifier(), enforce: 'pre' }, glsl.default()],
			ssr: {
				noExternal: ['@theatre/studio']
			},
			optimizeDeps: {
				entries: ['node_modules/queue-microtask/*', 'queue-microtask', '@theatre/studio']
			}
		}
	}
};

export default config;
