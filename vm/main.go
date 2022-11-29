package main

import (
	"flag"
	"fmt"
	"log"
	"net"
	"net/http"
	"os"
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

	mux := http.NewServeMux()
	mux.HandleFunc("/imageName", imageName)
	server := &http.Server{
		Handler: mux,
	}
	if err := server.Serve(ln); err != nil {
		log.Fatal(err)
	}
}

func imageName(w http.ResponseWriter, req *http.Request) {
	profileImage := os.Getenv("DESKTOP_PLUGIN_IMAGE")
	if profileImage == "" {
		profileImage = "dgageot/flamegraph"
	}

	w.Header().Add("Content-Type", "text/plain")
	fmt.Fprint(w, profileImage)
}
