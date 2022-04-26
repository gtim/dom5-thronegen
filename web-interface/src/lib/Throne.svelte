<script>
	export let name;
	export let powers;
</script>

<div>
	<h2>{name}</h2>
	<ul>
	{#each powers as power}
		<li>{power.title}
			<span class="pts">({power.pts} pts)</span>
		</li>
	{/each}
	</ul>
</div>

<style>
	h2 {
		font-size:16px;
		font-weight:bold;
		margin:0;
	}
	ul {
		padding-left:20px;
		margin-top:6px;
		list-style:none;
	}
	li {
		margin-top:2px;
	}
	span.pts {
		color:#555;
	}
</style>
