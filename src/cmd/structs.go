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

// ComposerInfo : All composer info
type ComposerInfo struct {
	Name  string          `json:"name"`
	Works []ComposerStats `json:"works"`
}

// ComposerStats : Work from any list by a single composer
type ComposerStats struct {
	Name     string `json:"name"`
	Work     string `json:"work"`
	Position int    `json:"position"`
	Slug     string `json:"slug"`
}

// ComposerLeaderboardItem : Composer rated by their works
type ComposerLeaderboardItem struct {
	ComposerID   int    `json:"composerId"`
	ComposerName string `json:"composerName"`
	Rating       int    `json:"rating"`
}

// SpaHandler : For handling SPA
type SpaHandler struct {
	staticPath string
	indexPath  string
}
