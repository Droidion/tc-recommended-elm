package main

import (
	"database/sql"
	"log"
)

func loadLeaderboardContent(db *sql.DB, slug string) []Work {

	works := []Work{}

	stmt, err := db.Prepare(`SELECT 
		composers.id AS composer_id, 
		composers.name AS composer, 
		works.work AS work 
		FROM works 
		JOIN composers ON composers.id = works.composer_id 
		WHERE slug=? 
		ORDER BY position`)
	if err != nil {
		log.Fatal(err)
	}
	defer stmt.Close()

	rows, err := stmt.Query(slug)
	defer rows.Close()
	for rows.Next() {
		work := Work{}
		err = rows.Scan(&work.ComposerID, &work.Composer, &work.Work)
		if err != nil {
			log.Fatal(err)
		}
		works = append(works, work)
	}
	err = rows.Err()
	if err != nil {
		log.Fatal(err)
	}

	return works
}
