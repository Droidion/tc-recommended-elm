package main

import (
	"database/sql"
	"encoding/json"
	"log"
	"net/http"
	"time"

	"github.com/gorilla/mux"
	_ "github.com/mattn/go-sqlite3"
)

func main() {

	db, err := sql.Open("sqlite3", "../tc.db")
	if err != nil {
		log.Fatal(err)
	}
	defer db.Close()

	router := mux.NewRouter()

	router.HandleFunc("/api/leaderboards", func(writer http.ResponseWriter, request *http.Request) {
		json.NewEncoder(writer).Encode(loadLeaderboardsList(db))
	})

	router.HandleFunc("/api/leaderboard/{slug}", func(writer http.ResponseWriter, request *http.Request) {
		json.NewEncoder(writer).Encode(loadLeaderboardContent(db, mux.Vars(request)["slug"]))
	})

	router.HandleFunc("/api/composer/{composerID}", func(writer http.ResponseWriter, request *http.Request) {
		json.NewEncoder(writer).Encode(loadComposerStats(db, mux.Vars(request)["composerID"]))
	})

	router.HandleFunc("/api/best-composers", func(writer http.ResponseWriter, request *http.Request) {
		json.NewEncoder(writer).Encode(loadComposersLeaderboard(db))
	})

	spa := SpaHandler{staticPath: "assets", indexPath: "index.html"}
	router.PathPrefix("/").Handler(spa)

	srv := &http.Server{
		Handler: router,
		Addr:    "127.0.0.1:8000",
		// Good practice: enforce timeouts for servers you create!
		WriteTimeout: 15 * time.Second,
		ReadTimeout:  15 * time.Second,
	}

	log.Fatal(srv.ListenAndServe())

}
