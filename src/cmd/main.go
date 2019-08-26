package main

import (
	"fmt"
	"net/http"
)

func main() {

	fs := http.FileServer(http.Dir("assets/"))
	http.Handle("/", http.StripPrefix("/", fs))
	fmt.Println("Listening to localhost port 8080...")
	http.ListenAndServe(":8080", nil)

}
