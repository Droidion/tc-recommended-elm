package main

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"log"
	"net/http"

	_ "github.com/mattn/go-sqlite3"
)

type Leaderboard struct {
	Name        string `json:"name"`
	Description string `json:"description"`
	Slug        string `json:"slug"`
}

type Work struct {
	Composer string `json:"composer"`
	Work     string `json:"work"`
	Position int    `json:"position"`
	Slug     string `json:"slug"`
}

func main() {

	db, err := sql.Open("sqlite3", "../tc.db")
	if err != nil {
		log.Fatal(err)
	}
	defer db.Close()

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

	fs := http.FileServer(http.Dir("assets/"))
	http.Handle("/", http.StripPrefix("/", fs))
	http.HandleFunc("/api/leaderboards", func(w http.ResponseWriter, r *http.Request) {
		json.NewEncoder(w).Encode(leaderboards)
	})
	fmt.Println("Listening to localhost port 8080...")
	http.ListenAndServe(":8080", nil)

}
