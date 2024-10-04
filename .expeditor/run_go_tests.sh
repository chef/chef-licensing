#!/bin/bash

go get .
go mod tidy

go test -v ./...