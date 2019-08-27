package main

import (
	"database/sql"
	"log"
)

func loadLeaderboards(db *sql.DB) []Leaderboard {

	leaderboards := []Leaderboard{}

	rows, err := db.Query("select name, description, slug from leaderboards")
	if err != nil {
		log.Fatal(err)
	}
	defer rows.Close()
	for rows.Next() {
		leaderboard := Leaderboard{}
		err = rows.Scan(&leaderboard.Name, &leaderboard.Description, &leaderboard.Slug)
		if err != nil {
			log.Fatal(err)
		}
		leaderboards = append(leaderboards, leaderboard)
	}
	err = rows.Err()
	if err != nil {
		log.Fatal(err)
	}

	return leaderboards
}
