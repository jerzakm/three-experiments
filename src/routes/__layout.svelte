<script lang="ts">
	import '../styles/app.css';
</script>

<nav>
	<a href="/01_raymarching_button">Raymarching button</a>
	<a href="/02_brutal_dither">Brutal dither</a>
	<a href="/03_raymarching_radio">Raymarching radio menu</a>
</nav>
<container>
	<slot />
</container>

<style>
	nav {
		@apply fixed top-0 flex flex-col z-50 py-4 px-2;
		background-color: rgba(255, 255, 255, 0.226);
	}
	container {
		min-height: 90vh;
	}
</style>
