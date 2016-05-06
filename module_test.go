package sigsci

import (
	"bytes"
	"crypto/tls"
	"net/http"
	"reflect"
	"testing"
)

func TestNewRPCMsgFromRequest(t *testing.T) {
	b := bytes.Buffer{}
	b.WriteString("test")
	r, err := http.NewRequest("GET", "http://localhost/", &b)
	if err != nil {
		t.Fatal(err)
	}
	r.RemoteAddr = "127.0.0.1"
	r.Header.Add("If-None-Match", `W/"wyzzy"`)
	r.RequestURI = "http://localhost/"
	r.TLS = &tls.ConnectionState{}

	want := RPCMsgIn{
		ServerName: "localhost",
		Method:     "GET",
		Scheme:     "https",
		URI:        "http://localhost/",
		Protocol:   "HTTP/1.1",
		RemoteAddr: "127.0.0.1",
		HeadersIn:  [][2]string{{"If-None-Match", `W/"wyzzy"`}},
	}
	eq := func(got, want RPCMsgIn) (ne string, equal bool) {
		switch {
		case got.ServerName != want.ServerName:
			return "ServerHostname", false
		case got.Method != want.Method:
			return "Method", false
		case got.Scheme != want.Scheme:
			return "Scheme", false
		case got.URI != want.URI:
			return "URI", false
		case got.Protocol != want.Protocol:
			return "Protocol", false
		case got.RemoteAddr != want.RemoteAddr:
			return "RemoteAddr", false
		case !reflect.DeepEqual(got.HeadersIn, want.HeadersIn):
			return "HeadersIn", false
		default:
			return "", true
		}
	}

	got := NewRPCMsgIn(r, false, -1, -1, -1)
	if ne, equal := eq(*got, want); !equal {
		t.Errorf("NewWafMsgFromRequest: incorrect %q", ne)
	}
}