<script>

	import { browser } from '$app/env';

	let promise;

	async function genNewThrones() {
		const response = await fetch('/gen.pl');
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


<h1>thronegen</h1>

<button on:click={clickButton}>generate thrones</button>

<div id="container">
{#if promise}
	{#await promise}
		<p>generating...</p>
	{:then generated}
		<div id="thrones">
		{#each generated.thrones as throne}
			<div>
				<p>{throne.name}</p>
				<ul>
				{#each throne.powers as power}
					<li>{power.title} ({power.pts} pts)</li>
				{/each}
				</ul>
			</div>
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
</div>

<div id="github_footer">
	<a href="https://github.com/gtim/dom5-thronegen" rel="noopener noreferrer">
		<img src="/GitHub-Mark-32px.png" alt="Github" title="Feedback and pull requests are welcome on Github"/>
	</a>
</div>


<style>
	#thrones {
		float:left;
		padding:16px;
	}
	#dm {
		overflow:hidden;
		max-width:480px;
		height:480px;
		margin-left:64px;
	}
	textarea {
		width:100%;
		height:100%;
	}
	#github_footer {
		position:absolute;
		bottom:16px;
		right:16px;
		width:32px;
		height:32px;
		padding:0;
	}
</style>
