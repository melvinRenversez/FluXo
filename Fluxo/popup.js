console.log("Popup chargé");

(async () => {

	const data = await chrome.storage.local.get(["FluxoLinks"]);
	const resetButton = document.getElementById("resetButton");
	const list = document.getElementById("list");

	const switchElement = document.getElementById("switch");
	const ball = document.querySelector(".ball");

	let interval = null;
	let items = data.FluxoLinks || [];

	let switchStatus = false;

	if (items.length === 0) {
		list.innerHTML = "Aucun flux détecté";
		return;
	}

	function renderLinks() {

		list.innerHTML = items.map(item => `
			<div class="element">
				<div class="title">${item.title}</div>

				<div class="bottomForm">
					<div class="duration">${formatDuration(item.duration)}</div>

					<form class="bottom">
						<input type="hidden" name="title" value="${item.title}">

						<input type="hidden" name="url" value="${item.url}">
						<input type="hidden" name="duration" value="${item.duration}">

						<button class="save-btn" type="submit" ${item.title ? "" : "disabled"}}>Envoyer</button>
					</form>
				</div>

				<div class="message" id="message"></div>
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

	function initInterval() {

		if (interval) {
			console.log("Interval deja initialisé");
			return;
		};

		console.log("Initialisation de l'intervalle...");

		interval = setInterval(async () => {

			console.log("Vérification des mises à jour...");

			const newFluxoLinks = await chrome.storage.local.get(["FluxoLinks"]);

			console.log("newFluxoLinks : ", newFluxoLinks);

			const newItems = newFluxoLinks.FluxoLinks || [];

			if (newItems.length > items.length) {


				items = newItems;

				renderLinks();
			}


		}, 1000);
	}


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
				.then(res => res.json())
				.then(data => {
					const statut = data.statut;

					console.log("returned data:", data);

					const message = form.parentElement.parentElement.querySelector(".message");

					console.log('statut', statut);

					console.log("Message :", message);

					message.classList.add("actif")
					if (statut == "error") {
						message.innerHTML = `<span class="error">${data.message}</span>`;
					}
					if (statut == "success") {
						message.innerHTML = `<span class="success">${data.message}</span>`;
					}

				});

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
			items = [];
			renderLinks();
			initInterval();
		});
	}



})();
