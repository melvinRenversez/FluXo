const db = require("./database.js");
const axios = require("axios");
const cheerio = require("cheerio");
const express = require("express");

const pages = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]
// const pages = [1, 2]
const cardClass = "film-card";
const url = "https://pokmiv.com/a742801/c/pokmiv";

const app = express();

app.use(express.json());
app.use(express.static("public"));



app.get("/", (req, res) => {
    res.sendFile("index.html");
})

app.get("/getFilms", async (req, res) => {
    const allFilms = await db.pool.query("select id, title, image from search order by id desc");

    res.json(allFilms[0]);
})

app.listen(3000, () => console.log("Server started on http://localhost:3000"));



async function getDataPage(url, page, index) {

    const res = await axios.get(url, {
        headers: {
            "User-Agent": "Mozilla/5.0"
        }
    });

    const $ = cheerio.load(res.data);

    const cards = $(".film-card");

    if (cards.length == 0) {
        return false;
    }


    for (let i = 0; i < cards.length; i++) {
        const card = cards[i];
        // recuper la balise image
        const image = $(card).find(".film-card-img").attr("src");
        const title = $(card).find(".film-card-img").attr("alt");

        const existe = await db.pool.query("select id from search where title = ?", [title]);

        if (existe[0].length == 0) {
            console.log("insert : ", title);

            await db.pool.query("insert into search(title, image, page, idx) values(?, ?, ?, ?)", [title, image, page, index]);
        } else {
            console.log("exist : ", title);
        }

    }

    return true;

}



async function search() {
    for (let page in pages) {
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