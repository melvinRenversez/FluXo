console.log("Popup chargé");

(async () => {

	const data = await chrome.storage.local.get(["FluxoLinks"]);

	const resetButton = document.getElementById("resetButton");

	const list = document.getElementById("list");

	const items = data.FluxoLinks || [];

	if (items.length === 0) {
		list.innerHTML = "Aucun flux détecté";
		return;
	}

	function renderLinks() {

		list.innerHTML = items.map(item => `
			<div class="element">
				<div class="title">eeeee</div>
				<div class="url" title="${item.url}">${item.url}</div>
				<div class="duration">${formatDuration(item.duration)}</div>

				<form class="bottom">
					<div class="custom-select">
						<input name="title" class="title-input" value="${item.title || ''}" placeholder="Titre ">

					</div>
					
					<input type="hidden" name="url" value="${item.url}">
					<input type="hidden" name="duration" value="${item.duration}">

					<button class="save-btn" type="submit" disabled>Envoyer</button>
				</form>
			</div>
		`).join("");


	}

	renderLinks();

	// verifier l etat du formulaire pour activer ou desactiver le bouton d envoie
	document.addEventListener("input", (event) => {

		if (event.target.classList.contains("title-input")) {
			const form = event.target.closest("form");
			const saveBtn = form.querySelector(".save-btn");

			console.log("Input détecté :", event.target.value);

			saveBtn.disabled = event.target.value.trim() === "";
		}
	});

	setInterval(() => {

		console.log("Vérification des mises à jour...");

		const newTry = chrome.storage.local.get(["FluxoLinks"]);

		const newItems = newTry.FluxoLinks || [];

		if (newItems.length > items.length) {


			items = newItems;

			renderLinks();
		}


	}, 5000);


	document.querySelectorAll(".bottom").forEach(form => {
		console.log("Formulaire trouvé");
		form.addEventListener("submit", handleSubmit);
	});


	function handleSubmit(event) {
		event.preventDefault();

		const form = event.target;

		try {

			fetch("http://192.168.0.225:3000/save", {
				method: "POST",
				headers: {
					"Content-Type": "application/json"
				},
				body: JSON.stringify({
					title: form.title.value,
					url: form.url.value,
					duration: form.duration.value
				})
			})
				.then(res => res.text())
				.then(data => console.log(data));

		} catch (error) {
			alert("Erreur lors de l'envoi des données :", error);
		}
	}

	function formatDuration(seconds) {

		seconds = Math.floor(seconds);

		const h = Math.floor(seconds / 3600).toString().padStart(2, '0');
		const m = Math.floor((seconds % 3600) / 60).toString().padStart(2, '0');
		const s = (seconds % 60).toString().padStart(2, '0');
		return `${h}:${m}:${s}`;
	}

	resetButton.addEventListener("click", reset);

	function reset() {
		chrome.storage.local.remove(["FluxoLinks"], () => {
			console.log("Données réinitialisées");
			location.reload();
		});
	}

})();
