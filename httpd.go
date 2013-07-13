package main

import (
	"flag"
	"fmt"
	"net/http"
	"os"
	"path"
	"strings"
)

var (
	rootDirectory = flag.String("path", ".", "Server root directory.")
	listenPort    = flag.Int("port", 8080, "Server listen port.")
)

func expandDirectory(s string) string {
	if ok := strings.HasPrefix(s, "~"); ok {
		s = path.Join(os.Getenv("HOME"), strings.SplitAfter(s, "~")[1])
	}
	return path.Clean(s)
}

func main() {
	flag.Parse()

	root := expandDirectory(*rootDirectory)
	fmt.Printf("Serving HTTP on 0.0.0.0 port %d ...\n", *listenPort)

	http.Handle("/", http.FileServer(http.Dir(root)))
	http.ListenAndServe(fmt.Sprintf(":%d", *listenPort), nil)
}
