import mysql from "mysql2/promise";

export const pool = mysql.createPool({
	host: '88.189.251.90',
	port: 21336,      // ou IP du serveur MySQL
	user: 'fluxo_user',
	password: 'FluxoMDP123!',
	database: 'fluxo'
});

pool.getConnection((err, connection) => {
	if (err) {
		console.error('Erreur de connexion :', err);
		return;
	}
	console.log('Connecté à MySQL !');
});