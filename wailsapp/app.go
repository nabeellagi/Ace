package main

import (
	"fmt"
	"net/http"
)

type App struct{}

func NewApp() *App {
	return &App{}
}

// Public method bound to frontend
func (a *App) ShutdownStreamlit() string {
	resp, err := http.Get("http://localhost:9999/shutdown")
	if err != nil {
		return fmt.Sprintf("Error: %v", err)
	}
	defer resp.Body.Close()
	return "Streamlit shutdown signal sent."
}
