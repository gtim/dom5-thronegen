<script>

	import { browser } from '$app/env';

	import Throne from '$lib/Throne.svelte';

	let promise;

	let num_thrones = 5;

	async function genNewThrones() {
		const response = await fetch( '/gen.pl?n=' + num_thrones );
		const json = await response.json();
		if ( response.ok ) {
			console.log(json.thrones);
			return json;
		} else {
			throw new Error(json);
		}
	}

	function clickButton() {
		promise = genNewThrones();
	}

	if (browser) {
		promise = genNewThrones();
	}

</script>


<h1>Throne Generator</h1>

<div id="buttondiv">
	<select bind:value={num_thrones} on:change={() => promise = genNewThrones()}>
		{#each [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15] as n}
			<option value={n}>{n} throne{#if n!=1}s{/if}</option>
		{/each}
	</select>
	<button on:click={clickButton}>generate</button>
</div>

{#if promise}
	{#await promise}
		<p style="text-align:center;">generating...</p>
	{:then generated}
		<div id="thrones">
		{#each generated.thrones as throne}
			<Throne name="{throne.name}" powers="{throne.powers}"/>
		{/each}
		</div>
		<div id="dm">
			<textarea>{generated.dm}</textarea>
		</div>
	{:catch error}
		<p style="color:red;">
			<span style="font-weight:bold;">Error: {error.message}</span>
		</p>
	{/await}
{/if}

<div id="github_footer">
	<a href="https://github.com/gtim/dom5-thronegen" rel="noopener noreferrer">
		<img src="/GitHub-Mark-32px.png" alt="Github" title="Feedback and pull requests are welcome on Github"/>
	</a>
</div>


<style>
	h1 {
		margin-top:0;
		margin-bottom:16px;
	}
	h1, #buttondiv {
		text-align:center;
	}
	#buttondiv {
		margin-bottom:40px;
	}
	#buttondiv select {
		padding:3px;
		margin-right:12px;
	}
	#buttondiv button {
		padding:3px 7px;
	}
	#thrones {
		margin:0 auto;
		width:fit-content;
	}
	#dm {
		margin-top:48px;
	}
	textarea {
		width:95%;
		height:480px;
		margin:0 auto;
		padding:4px;
		display:block;
	}
	#github_footer {
		position:fixed;
		bottom:16px;
		right:16px;
		width:32px;
		height:32px;
		padding:0;
	}
</style>
