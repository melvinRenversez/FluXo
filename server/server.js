import * as db from "./database.js";
import express from "express";
import { spawn } from "child_process";
import fs from "fs";

const app = express();
const PORT = 3000;

//const downloadDirectory = "./downloads";
const downloadDirectory = "/mnt/jellyfin/download/autodl";
const downloadTimeout = 10000;

let downloadInProgress = false;
let currentDownload = {};
let canDownload = true;

app.use(express.json());
app.use(express.static("public"));


app.get("/", async (req, res) => {
	res.sendFile("index.html");
});

app.get("/getDownloadStatus", async (req, res) => {
	res.json({ canDownload: canDownload });
});

app.post("/setDownloadStatus", async (req, res) => {
	canDownload = req.body.status;
});

app.post("/updateTitle", async (req, res) => {
	const { id, title } = req.body;

	console.log("ID:", id);
	console.log("Title:", title);

	let previousTitle = await db.pool.query("select title from links where id = ?", [id]);

	previousTitle = previousTitle[0][0].title;

	console.log("Previous Title:", previousTitle);

	if (title != "" && title != previousTitle) {

		// modifier le nom ausse dans le dossier de téléchargement
		const oldPath = `${downloadDirectory}/${previousTitle}.mp4`;
		const newPath = `${downloadDirectory}/${title}.mp4`;

		try {
			await fs.promises.rename(oldPath, newPath);
			console.log(`Fichier renommé de ${oldPath} à ${newPath}`);
		} catch (err) {
			console.error("Erreur lors du renommage du fichier:", err);
			res.status(500).json({ statut: "error", message: "Erreur lors du renommage du fichier" });
			return;
		}

		await db.pool.query("update links set title = ? where id = ?", [title, id]);

		res.json({ statut: "success", message: "Titre mis à jour avec succès" });

	}

	res.json({ statut: "error", message: "Erreur lors de la mise à jour du titre" });

})

app.get("/getLinks", async (req, res) => {

	const links = await db.pool.query("select l.id, url, title, duration, libelle as status, startDownload_at, endDownload_at from links l join status s on l.status_id = s.id");

	res.json(links[0]);
});

app.get("/getCurrentDownload", async (req, res) => {

	res.json({
		id: currentDownload.id,
		progress: currentDownload.progress
	});
});


app.post("/save", async (req, res) => {

	console.log("Données reçues :", req.body);

	const { title, url, duration } = req.body;

	console.log("Titre :", title);
	console.log("URL :", url);
	console.log("Durée :", duration);

	if (title == "" || url == "") {
		res.status(400).json({ statut: "error", message: "Titre et URL sont requis" });
		return;
	}

	if (!duration) duration = 0;

	const allUrls = await db.pool.query("select url from links");

	console.log("URLs existantes :", allUrls);

	console.log("URL new :", allUrls[0].map(link => link.url));

	if (allUrls[0].map(link => link.url).includes(url)) {
		console.log("Ce lien existe déjà");
		res.status(400).json({ statut: "error", message: "Ce lien existe déjà" });
		return;
	}

	await db.pool.query("insert into links (url, title, duration) values (?, ?, ?)", [url, title, duration]);

	res.json({ statut: "success", message: "Lien enregistré avec succès" });

});

async function download() {

	if (!canDownload) {
		console.log("Téléchargement désactivé,  veuillez activer le téléchargement pour commencer.");
		setTimeout(download, downloadTimeout);
		return;
	}

	if (downloadInProgress) {
		console.log("Téléchargement déjà en cours.");
		return;
	}
	downloadInProgress = true;

	const links = await db.pool.query("select id, title, url from links where status_id = 1 or status_id = 2 or status_id = 4 order by created_at asc");


	if (links[0].length == 0) {
		console.log("Aucun lien à télécharger.");
		downloadInProgress = false;
		setTimeout(download, downloadTimeout);
		return;
	}

	currentDownload = links[0][0];
	currentDownload.progress = 0;

	console.log("Current")
	console.log(currentDownload);


	const ytdlp = spawn("yt-dlp", [
		"-N", "32",
		"-o", `${downloadDirectory}/${currentDownload.title}.mp4`,
		currentDownload.url
	]);

	// stdout
	ytdlp.stdout.on("data", (data) => {
		// console.log("STDOUT:", data.toString());
		const line = data.toString();

		const match = line.match(/\[download\]\s+(\d+(?:\.\d+)?)%/);;

		if (match) {
			currentDownload.progress = parseFloat(match[1]);
		}

		db.pool.query("update links set status_id = 2, startDownload_at = now() where id = ?", [currentDownload.id]);

		console.log(currentDownload);

	});

	ytdlp.stderr.on("data", (data) => {
		console.error("STDERR:", data.toString());

		db.pool.query("update links set status_id = 4 where id = ?", [currentDownload.id]);

		currentDownload.progress = null;
	});


	ytdlp.on("close", (code) => {

		if (currentDownload.progress !== 100) {
			db.pool.query("update links set status_id = 4, endDownload_at = now() where id = ?", [currentDownload.id]);
		} else {
			db.pool.query("update links set status_id = 3, endDownload_at = now() where id = ?", [currentDownload.id]);
		}

		currentDownload.progress = null;
		downloadInProgress = false;
		console.log("Process terminé avec le code", code);

		console.log("Attente de", downloadTimeout / 1000, "secondes avant de lancer le prochain téléchargement...");
		setTimeout(download, downloadTimeout);
	});


}


download();


app.listen(PORT, () => {
	console.log(`Server is listening on port ${PORT}`);
});


