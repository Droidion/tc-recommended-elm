package main

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"log"
	"net/http"

	_ "github.com/mattn/go-sqlite3"
)

func main() {

	db, err := sql.Open("sqlite3", "../tc.db")
	if err != nil {
		log.Fatal(err)
	}
	defer db.Close()

	leaderboards := loadLeaderboards(db)

	fs := http.FileServer(http.Dir("assets/"))
	http.Handle("/", http.StripPrefix("/", fs))

	http.HandleFunc("/api/leaderboards", func(w http.ResponseWriter, r *http.Request) {
		json.NewEncoder(w).Encode(leaderboards)
	})

	fmt.Println("Listening to localhost port 8080...")
	http.ListenAndServe(":8080", nil)

}
