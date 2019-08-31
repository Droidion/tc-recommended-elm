package main

import (
	"database/sql"
	"log"
)

func loadComposersLeaderboard(db *sql.DB) []ComposerLeaderboardItem {

	composers := []ComposerLeaderboardItem{}

	rows, err := db.Query(`SELECT 
		works.composer_id, 
		composers.name, 
		(ROUND (SUM (1 / CAST(works.position AS float)) * 100000)) AS weight 
		FROM works 
		JOIN composers ON composers.id = works.composer_id 
		GROUP BY works.composer_id, composers.name 
		ORDER BY weight DESC`)
	if err != nil {
		log.Fatal(err)
	}
	defer rows.Close()

	for rows.Next() {
		composer := ComposerLeaderboardItem{}
		err = rows.Scan(&composer.ComposerID, &composer.ComposerName, &composer.Rating)
		if err != nil {
			log.Fatal(err)
		}
		composers = append(composers, composer)
	}
	err = rows.Err()
	if err != nil {
		log.Fatal(err)
	}

	return composers
}
