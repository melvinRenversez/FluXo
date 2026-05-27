let FluxoLinks = [];
let tab = {};

chrome.webRequest.onBeforeRequest.addListener(
	async function (details) {

		console.log("details ");

		const url = details.url;

		if (!url.includes(".m3u8")) return;

		console.log("pre some :" + FluxoLinks.some(link => link.url === url));
		// console.log("tab title : ", tab.title);

		if (FluxoLinks.some(link => link.url === url) && !tab.title) return;
		console.log("some");

		const duration = await getM3U8Duration(url);

		if (duration === 0) return;
		console.log("duration ");

		let newPush = {
			url,
			duration
		};

		if (tab.title) {
			newPush.title = tab.title;
		}


		FluxoLinks.push(newPush);

		console.log("Tab title : ", tab.title);


		const uniqueMap = new Map();

		for (const item of FluxoLinks) {
			const existing = uniqueMap.get(item.url);

			if (!existing) {
				uniqueMap.set(item.url, item);
			} else {
				uniqueMap.set(item.url, {
					...existing,
					...item,
					title: item.title || existing.title
				});
			}
		}

		const unique = [...uniqueMap.values()];

		chrome.storage.local.set({ FluxoLinks: unique });

		// console.log("Unique : ", unique);

		tab = {};

	},
	{
		urls: ["<all_urls>"]
	}
);


async function getM3U8Duration(url) {
	try {
		const res = await fetch(url);
		const text = await res.text();

		let duration = 0;

		text.split("\n").forEach(line => {
			if (line.startsWith("#EXTINF:")) {
				duration += parseFloat(line.replace("#EXTINF:", ""));
			}
		});

		return duration;
	} catch (error) {

	}
}


try {
	chrome.webNavigation.onCompleted.addListener(async function (details) {

		if (details.frameId !== 0) return;


		let title = "";

		await chrome.tabs.query({}, (tabs) => {
			const target = tabs.find(t =>
				t.url && t.url.includes(details.url)
			);

			if (target) {
				title = target.title;
				console.log("title : ", title);
			}

			if (title.includes("Pokmiv - ")) title = title.replace("Pokmiv - ", "");

			tab = {
				id: details.tabId,
				url: details.url,
				title: title
			};
		});


	});

} catch (error) {
	console.error("Erreur dans le listener de navigation :", error);
}
