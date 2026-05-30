const db = require("./database.js");
const axios = require("axios");
const cheerio = require("cheerio");
const express = require("express");
const path = require("path");

const pages = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13];
const cardClass = "film-card";
const url = "https://pokmiv.com/a742801/c/pokmiv";
const app = express();


let ScrapIndex = 0;



app.use(express.json());
app.use(express.static("public"));


app.post("/search", async (req, res) => {

    const { search } = req.body;
    let titles = [];

    console.log(search);

    if (search == "") {
        titles = await db.pool.query("select id, title, image, type, date from search order by id desc limit 10");
        titles = titles[0];
    } else {
        titles = await db.pool.query("select id, title, image, type, date from search where title like ? order by id desc limit 10", ["%" + search + "%"]);
        titles = titles[0];
    }


    res.json({ titles });
})

app.get("/getFilm/:id", async (req, res) => {
    const { id } = req.params;
    const film = await db.pool.query("select * from search where id = ?", [id]);
    res.json({ film: film[0][0] });
})

app.get("/getTotal", async (req, res) => {
    const total = await db.pool.query("select count(*) as total from search");
    res.json({ total: total[0][0].total });
})

app.get("/", (req, res) => {
    res.sendFile("index.html");
})

app.get("/film", (req, res) => {
    res.sendFile(path.join(__dirname, "public", "film.html"));
})

app.listen(5000, () => console.log("Server started on http://localhost:5000"));



async function getDataPage(url, page, index) {

    let totalDB = await db.pool.query("select count(*) as total from search");
    totalDB = totalDB[0][0].total;

    const res = await axios.get(url, {
        headers: {
            "User-Agent": "Mozilla/5.0"
        }
    });
    let $ = cheerio.load(res.data);
    const cards = $(".film-card");

    if (cards.length == 0) {
        return false;
    }

    for (let i = 0; i < cards.length; i++) {
        ScrapIndex++;
        const card = cards[i];
        const title = $(card).find(".film-card-img").attr("alt");
        const image = $(card).find(".film-card-img").attr("src");

        const type = $(".section-header-sticky h2").text() || "Unknown";

        const date = $(card).find(".trend-card-date").text() || "0000";
        const existe = await db.pool.query("select id from search where title = ?", [title]);


        console.log('--------------------');
        console.log("Scraping : ", ScrapIndex, "/", totalDB, " => on page : ", page, "index : ", index);
        console.log('base : ', url);
        console.log('name found : ', title,);
        console.log('image found : ', image);
        console.log('type found : ', type);
        console.log('date found : ', date);

        if (existe[0].length == 0) {

            const url = "https://pokmiv.com" + $(card).attr("href");

            const res = await axios.get(url, {
                headers: {
                    "User-Agent": "Mozilla/5.0"
                }
            });

            $ = cheerio.load(res.data);

            const video = await getVideoUrl($);

            const description = $(".film-detail-synopsis").text();

            console.log('url found : ', url);
            console.log('video found : ', video);
            console.log('description found : ', description);

            console.log("INSERT");
            try {
                await db.pool.query("insert into search(title, image, type, video, date, description, page, idx) values(?, ?, ?, ?, ?, ?, ?, ?)", [title, image, type, video, date, description, page, index]);
            } catch (e) {
                console.log(e);
            }

            await sleep(1000);

        } else {
            console.log("ALREADY EXIST");
        }
    }
    return true;
}


async function getVideoUrl(data) {


    // Exemple : récupérer une iframe vidéo
    const iframe = data("iframe").attr("src");

    return iframe;
}

async function sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}


async function search() {
    for (let page in pages) {
        console.log("Scraping page : ", page);
        let finshed = false;
        let index = 0;
        while (!finshed) {

            testURl = url + "/" + page + "/" + index;

            const state = await getDataPage(testURl, page, index);

            if (!state) {
                finshed = true;
            }
            index++;
        }
    }
}


search();