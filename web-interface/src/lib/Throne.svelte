<script>
	import { page } from '$app/stores'

	export let name;
	export let powers;

	const show_pts = $page.url.searchParams.get('show_pts');

</script>

<div>
	<h2>{name}</h2>
	<ul>
	{#each powers as power}
		<li>
			{power.title}
			{#if show_pts}
				<span class="pts">({power.pts} pts)</span>
			{/if}
		</li>
	{/each}
	</ul>
</div>

<style>
	h2 {
		font-size:18px;
		font-weight:bold;
		margin:0;
	}
	ul {
		padding-left:20px;
		margin-top:6px;
		margin-bottom:20px;
		list-style:none;
	}
	li {
		margin-top:2px;
	}
	span.pts {
		color:#555;
	}
</style>
