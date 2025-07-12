package main

import (
	"context"
	"embed"

	"github.com/wailsapp/wails/v2"
	"github.com/wailsapp/wails/v2/pkg/options"
	"github.com/wailsapp/wails/v2/pkg/options/assetserver"
)

//go:embed frontend/*
var assets embed.FS

func main() {
	app := NewApp()

	err := wails.Run(&options.App{
		Title:  "Streamlit Desktop",
		Width:  1024,
		Height: 768,
		AssetServer: &assetserver.Options{
			Assets: assets,
		},
		Bind: []interface{}{app},

		// ✅ Automatically shut down Streamlit when app closes
		OnShutdown: func(ctx context.Context) {
			app.ShutdownStreamlit()
		},
	})

	if err != nil {
		println("Error:", err.Error())
	}
}