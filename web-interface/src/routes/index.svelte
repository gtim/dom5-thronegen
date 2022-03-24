<script>

	let promise;

	async function genNewThrones() {
		const response = await fetch('/gen.pl');
		const json = await response.json();
		if ( response.ok ) {
			console.log(json.thrones);
			return json.thrones;
		} else {
			throw new Error(json);
		}
	}

	function clickButton() {
		promise = genNewThrones();
	}

</script>


<h1>thronegen</h1>

<button on:click={clickButton}>generate thrones</button>

{#if promise}
	{#await promise}
		<p>generating...</p>
	{:then thrones}
		{#each thrones as throne}
			<div>
				<p>Throne</p>
				<ul>
				{#each throne.powers as power}
					<li>{power.title} ({power.pts} pts)</li>
				{/each}
				</ul>
			</div>
		{/each}
	{:catch error}
		<p style="color:red;">
			<span style="font-weight:bold;">Error: {error.message}</span>
		</p>
	{/await}
{/if}
