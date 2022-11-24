package main

import (
	"flag"
	"log"
	"net"
	"net/http"
	"os"

	"github.com/labstack/echo/v4"
)

func main() {
	var socketPath string
	flag.StringVar(&socketPath, "socket", "/tmp/volumes-service.sock", "Unix domain socket to listen on")
	flag.Parse()

	log.Println("Starting listening on", socketPath)
	os.RemoveAll(socketPath)
	ln, err := net.Listen("unix", socketPath)
	if err != nil {
		log.Fatal(err)
	}

	router := echo.New()
	router.Listener = ln
	router.HideBanner = true
	router.GET("/imageName", imageName)

	log.Fatal(router.Start(""))
}

func imageName(ctx echo.Context) error {
	profileImage := os.Getenv("DESKTOP_PLUGIN_IMAGE")
	if profileImage == "" {
		profileImage = "dgageot/flamegraph"
	}

	return ctx.String(http.StatusOK, profileImage)
}
