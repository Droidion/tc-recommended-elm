package main

// Leaderboard : Single leaderboard metadata. Slug is important, used for linking data between db tables
type Leaderboard struct {
	Name        string `json:"name"`
	Description string `json:"description"`
	Slug        string `json:"slug"`
}

// Work : Single work inside a leaderboard
type Work struct {
	ComposerID int    `json:"composerId"`
	Composer   string `json:"composer"`
	Work       string `json:"work"`
}

// ComposerStats : Work from any list by a single composer
type ComposerStats struct {
	Composer string `json:"composer"`
	Work     string `json:"composerName"`
	Position int    `json:"position"`
	Slug     string `json:"slug"`
}
