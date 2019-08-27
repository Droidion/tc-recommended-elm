package main

// Single leaderboard metadata. Slug is important, used for linking data between db tables
type Leaderboard struct {
	Name        string `json:"name"`
	Description string `json:"description"`
	Slug        string `json:"slug"`
}

// Single work inside a leaderboard
type Work struct {
	Composer string `json:"composer"`
	Work     string `json:"work"`
	Position int    `json:"position"`
	Slug     string `json:"slug"`
}
