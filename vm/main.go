package main

import (
	"archive/tar"
	"context"
	_ "embed"
	"flag"
	"io"
	"log"
	"net"
	"net/http"
	"os"
	"strings"

	"github.com/docker/docker/api/types"
	"github.com/docker/docker/api/types/container"
	"github.com/docker/docker/api/types/mount"
	"github.com/docker/docker/client"
	"github.com/labstack/echo/v4"
	"github.com/pkg/errors"
)

//go:embed profile.json
var profile []byte

func main() {
	var socketPath string
	flag.StringVar(&socketPath, "socket", "/tmp/volumes-service.sock", "Unix domain socket to listen on")
	flag.Parse()

	router := echo.New()
	router.HideBanner = true
	router.GET("/profileProcess", profileProcess)
	router.GET("/test", test)

	log.Println("Starting listening on", socketPath)
	address := ""
	if strings.Contains(socketPath, ":") {
		address = socketPath
	} else {
		os.RemoveAll(socketPath)
		ln, err := net.Listen("unix", socketPath)
		if err != nil {
			log.Fatal(err)
		}
		router.Listener = ln
	}

	log.Fatal(router.Start(address))
}

func test(ctx echo.Context) error {
	return ctx.Blob(http.StatusOK, "application/json", profile)
}

func profileProcess(ctx echo.Context) error {
	processName := ctx.QueryParam("processName")
	duration := ctx.QueryParam("duration")

	buf, err := run(ctx.Request().Context(), processName, duration)
	if err != nil {
		log.Println(err)
		return ctx.String(http.StatusInternalServerError, err.Error())
	}

	return ctx.Blob(http.StatusOK, "application/json", buf)
}

func run(ctx context.Context, processName, duration string) ([]byte, error) {
	cli, err := client.NewClientWithOpts(client.FromEnv, client.WithAPIVersionNegotiation())
	if err != nil {
		return nil, errors.Wrap(err, "connecting to docker")
	}
	defer cli.Close()

	resp, err := cli.ContainerCreate(ctx, &container.Config{
		Image: "dgageot/ebpf",
		Cmd:   []string{"/entrypoint.sh", processName, duration},
	}, &container.HostConfig{
		PidMode:    "host",
		Privileged: true,
		Mounts: []mount.Mount{{
			Type:     mount.TypeBind,
			Source:   "/lib/modules",
			Target:   "/lib/modules",
			ReadOnly: true,
		}},
	}, nil, nil, "")
	if err != nil {
		return nil, errors.Wrap(err, "creating container")
	}

	containerID := resp.ID
	if err := cli.ContainerStart(ctx, containerID, types.ContainerStartOptions{}); err != nil {
		return nil, errors.Wrap(err, "starting container")
	}

	statusCh, errCh := cli.ContainerWait(ctx, resp.ID, container.WaitConditionNotRunning)
	select {
	case err := <-errCh:
		if err != nil {
			return nil, errors.Wrap(err, "waiting for container")
		}
	case <-statusCh:
	}

	archive, _, err := cli.CopyFromContainer(ctx, containerID, "/out/profile.json")
	if err != nil {
		return nil, errors.Wrap(err, "copying result")
	}
	defer archive.Close()

	t := tar.NewReader(archive)
	if _, err := t.Next(); err != nil {
		return nil, errors.Wrap(err, "reading tar")
	}

	buf, err := io.ReadAll(t)
	if err != nil {
		return nil, errors.Wrap(err, "reading tar file")
	}

	// TODO: even if file not found
	if err := cli.ContainerRemove(ctx, containerID, types.ContainerRemoveOptions{}); err != nil {
		return nil, errors.Wrap(err, "removing container")
	}

	log.Println("Success")
	return buf, nil
}
