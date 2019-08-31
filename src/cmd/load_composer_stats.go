package main

import (
	"database/sql"
	"log"
	"strconv"
)

func loadComposerStats(db *sql.DB, composerID string) []ComposerStats {

	compID, err := strconv.Atoi(composerID)
	if err != nil {
		compID = 0
	}

	stats := []ComposerStats{}

	stmt, err := db.Prepare(`SELECT 
		works.work, 
		works.position, 
		works.slug 
		FROM composers 
		JOIN works ON works.composer_id = composers.id 
		WHERE composers.id = ? 
		ORDER BY slug, position`)
	if err != nil {
		log.Fatal(err)
	}
	defer stmt.Close()

	rows, err := stmt.Query(compID)
	defer rows.Close()
	for rows.Next() {
		stat := ComposerStats{}
		err = rows.Scan(&stat.Work, &stat.Position, &stat.Slug)
		if err != nil {
			log.Fatal(err)
		}
		stats = append(stats, stat)
	}
	err = rows.Err()
	if err != nil {
		log.Fatal(err)
	}

	return stats
}
