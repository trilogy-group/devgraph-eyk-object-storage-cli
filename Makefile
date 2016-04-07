SHORT_NAME := object-storage-cli
REPO_PATH := github.com/deis/${SHORT_NAME}

HOST_OS := $(shell uname)
ifeq ($(HOST_OS),Darwin)
	GOOS=darwin
else
	GOOS=linux
endif

DEV_ENV_IMAGE := quay.io/deis/go-dev:0.9.1
DEV_ENV_WORK_DIR := /go/src/${REPO_PATH}
DEV_ENV_PREFIX := docker run --rm -e GO15VENDOREXPERIMENT=1 -v ${CURDIR}:${DEV_ENV_WORK_DIR} -w ${DEV_ENV_WORK_DIR}
DEV_ENV_CMD := ${DEV_ENV_PREFIX} ${DEV_ENV_IMAGE}
DIST_DIR := _dist
BINARY_NAME := objstorage


GO_LDFLAGS = -ldflags "-s -X ${REPO_PATH}/version.BuildVersion=${VERSION}"

VERSION ?= $(shell git rev-parse --short HEAD)

prep-bintray-json:
# TRAVIS_TAG is set to the tag name if the build is a tag
ifdef TRAVIS_TAG
	@jq '.version.name |= "$(VERSION)"' _scripts/ci/bintray-template.json | \
		jq '.package.repo |= "deis"' > _scripts/ci/bintray-ci.json
else
	@jq '.version.name |= "$(VERSION)"' _scripts/ci/bintray-template.json \
		> _scripts/ci/bintray-ci.json
endif

bootstrap:
	${DEV_ENV_CMD} glide install

build: binary-build

build-all:
	${DEV_ENV_CMD} gox -verbose \
	${GO_LDFLAGS} \
	-os="linux darwin " \
	-arch="amd64 386" \
	-output="$(DIST_DIR)/${BINARY_NAME}-${VERSION}-{{.OS}}-{{.Arch}}" .

binary-build:
	${DEV_ENV_PREFIX} -e GOOS=${GOOS} ${DEV_ENV_IMAGE} go build -a ${GO_LDFLAGS} -o ${BINARY_NAME} .

dist: build-all

test:
	${DEV_ENV_CMD} go test $$(glide nv)
