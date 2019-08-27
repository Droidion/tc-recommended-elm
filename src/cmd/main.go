package main

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"log"
	"net/http"

	"github.com/gorilla/mux"
	_ "github.com/mattn/go-sqlite3"
)

func main() {

	db, err := sql.Open("sqlite3", "../tc.db")
	if err != nil {
		log.Fatal(err)
	}
	defer db.Close()

	r := mux.NewRouter()

	r.HandleFunc("/api/leaderboards", func(w http.ResponseWriter, r *http.Request) {
		json.NewEncoder(w).Encode(loadLeaderboardsList(db))
	})

	r.HandleFunc("/api/leaderboard/{slug}", func(w http.ResponseWriter, r *http.Request) {
		json.NewEncoder(w).Encode(loadLeaderboardContent(db, mux.Vars(r)["slug"]))
	})

	r.PathPrefix("/").Handler(http.StripPrefix("", http.FileServer(http.Dir("assets/"))))

	fmt.Println("Listening to localhost port 8080...")
	http.ListenAndServe(":8080", r)

}
