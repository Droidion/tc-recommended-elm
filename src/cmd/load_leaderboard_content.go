package main

import (
	"database/sql"
	"log"
)

func loadLeaderboardContent(db *sql.DB, slug string) []Work {

	works := []Work{}

	stmt, err := db.Prepare("SELECT composer, work FROM works WHERE slug=? ORDER BY position")
	if err != nil {
		log.Fatal(err)
	}
	defer stmt.Close()

	rows, err := stmt.Query(slug)
	defer rows.Close()
	for rows.Next() {
		work := Work{}
		err = rows.Scan(&work.Composer, &work.Work)
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
