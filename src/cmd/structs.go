package main

// Leaderboard : Single leaderboard metadata. Slug is important, used for linking data between db tables
type Leaderboard struct {
	Name        string `json:"name"`
	Description string `json:"description"`
	Slug        string `json:"slug"`
}

// Work : Single work inside a leaderboard
type Work struct {
	ComposerID int    `json:"composer_id"`
	Composer   string `json:"composer"`
	Work       string `json:"work"`
}
