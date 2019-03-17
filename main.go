package main

import (
	"encoding/base64"
	"github.com/gin-gonic/gin"
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promhttp"
	"strconv"
	"time"
)

var HTTPReqTotal *prometheus.CounterVec

func init() {
	HTTPReqTotal = prometheus.NewCounterVec(prometheus.CounterOpts{
		Name: "http_requests_total",
		Help: "Total number of HTTP requests",
	}, []string{"method", "path", "status"})
	// sets up the method, path and status prometheus metric labels
	prometheus.MustRegister(HTTPReqTotal)
}

func instrumenter(h gin.HandlerFunc) gin.HandlerFunc {
	return func(c *gin.Context) {
		// call the wrapped function
		h(c)

		// increment the httpreqtotal counter
		HTTPReqTotal.With(prometheus.Labels{
			"method": c.Request.Method,
			"path": c.Request.URL.Path,
			"status": strconv.Itoa(c.Writer.Status()),
		}).Inc()
	}
}
func main() {
	r := gin.Default()
	r.GET("/covilha", instrumenter(portoTimeHandler))
	r.GET("/homersimpson", instrumenter(homerHandler))
	r.GET("/metrics", gin.WrapH(promhttp.Handler()))
	r.Run() // listen on :8080
}

func portoTimeHandler(c *gin.Context) {
	loc, err := time.LoadLocation("Europe/Lisbon") // for Covilha, Portugal
	if err != nil {
		panic(err)
	}
	now := time.Now().In(loc)
	c.JSON(200, gin.H{
		"Covilha/Portugal": now,
	})
}

func homerHandler(c *gin.Context) {
	body, _ := base64.StdEncoding.DecodeString(hSimpsonPng)
	c.Writer.WriteHeader(200)
	c.Writer.Header().Set("Content-Type", "image/png")
	c.Writer.Write(body)
}


/*
additional notes:
- logging: gin provides some defaults and logs to stdout/stderr
- testing: unit tests TBD
 */