package main

import (
	"flag"
	"fmt"
	"net"
	"net/http"
	"os"
	"os/signal"
	"path"
	"strings"
	"syscall"
	"time"
)

var (
	rootDirectory = flag.String("path", ".", "Server root directory.")
	listenHost    = flag.String("host", "0.0.0.0", "Server listen address.")
	listenPort    = flag.Int("port", 8080, "Server listen port.")
)

type ResponseWriterWrapper struct {
	status int
	bytes  int
	http.ResponseWriter
}

func (rww *ResponseWriterWrapper) Write(bytes []byte) (int, error) {
	if rww.status == 0 {
		rww.status = http.StatusOK
	}

	n, err := rww.ResponseWriter.Write(bytes)
	rww.bytes += n

	return n, err
}

func (rww *ResponseWriterWrapper) WriteHeader(code int) {
	rww.status = code
	rww.ResponseWriter.WriteHeader(code)
}

type HandlerWrapper struct {
	http.Handler
}

func (hw *HandlerWrapper) RecordRequest(r *http.Request, w *ResponseWriterWrapper, duration time.Duration) {
	var host string
	user := "-"

	if i := strings.LastIndex(r.RemoteAddr, ":"); i != -1 {
		host = r.RemoteAddr[:i]
	}

	if r.URL.User != nil {
		if u := r.URL.User.Username(); u != "" {
			user = u
		}
	}

	fmt.Printf("%s - %s [%s] \"%s %s %s\" %d %d %f\n",
		host,
		user,
		time.Now().Format("02/Jan/2006:15:04:05 -0700"),
		r.Method,
		r.URL,
		r.Proto,
		w.status,
		w.bytes,
		duration.Seconds())
}

func (hw *HandlerWrapper) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	start := time.Now()
	rww := &ResponseWriterWrapper{0, 0, w}
	hw.Handler.ServeHTTP(rww, r)
	go hw.RecordRequest(r, rww, time.Since(start))
}

func expandPath(p string) string {
	if ok := strings.HasPrefix(p, "~"); ok {
		p = path.Join(os.Getenv("HOME"), strings.SplitAfter(p, "~")[1])
	}
	return path.Clean(p)
}

func main() {
	var l net.Listener
	var err error

	os.Stdout = os.Stderr

	flag.Parse()

	s := make(chan os.Signal)
	go func() {
		signal.Notify(s, syscall.SIGINT, syscall.SIGTERM, syscall.SIGQUIT)
		<-s
		l.Close()
		signal.Stop(s)
		os.Exit(0)
	}()

	mux := http.NewServeMux()
	handler := &HandlerWrapper{http.FileServer(http.Dir(expandPath(*rootDirectory)))}

	mux.Handle("/", handler)

	*listenHost = strings.TrimSpace(*listenHost)

	l, err = net.Listen("tcp4", fmt.Sprintf("%s:%d", *listenHost, *listenPort))
	if err != nil {
		fmt.Printf("An error occurred: %s\n", err.Error())
		os.Exit(1)
	}
	fmt.Printf("Serving HTTP on %s port %d...\n", *listenHost, *listenPort)

	err = http.Serve(l, mux)
	if !strings.Contains(err.Error(), "use of closed network connection") {
		fmt.Printf("An error occurred: %s\n", err.Error())
		os.Exit(1)
	}
}
