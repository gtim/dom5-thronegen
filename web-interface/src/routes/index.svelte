<script>

	let promise;
	let thrones_text;

	async function genNewThrones() {
		const response = await fetch('/gen.pl');
		const text = await response.text();
		if ( response.ok ) {
			thrones_text = text;
		} else {
			throw new Error(text);
		}
	}

	function clickButton() {
		promise = genNewThrones();
	}

</script>


<h1>thronegen</h1>

<button on:click={clickButton}>generate thrones</button>

{#if thrones_text}
	<p style="white-space:pre;">{thrones_text}</p>
{/if}
