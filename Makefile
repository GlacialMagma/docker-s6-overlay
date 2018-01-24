default: docker_build

build: docker_build

release: docker_build

GIT_COMMIT = $(strip $(shell git rev-parse --short HEAD))

VERSION = $(strip $(shell cat VERSION))

DOCKER_IMAGE ?= glacialmagma/s6-overlay

PACKAGE ?= s6-overlay-x86

GIT_NOT_CLEAN_CHECK = $(shell git status --porcelain)
ifneq (x$(GIT_NOT_CLEAN_CHECK), x)
DOCKER_TAG_SUFFIX = "-dirty"
endif

# If we're releasing to Docker Hub, and we're going to mark it with the latest tag, it should exactly match a version release
ifeq ($(MAKECMDGOALS),release)
# Use the version number as the release tag.
DOCKER_TAG = $(VERSION)

ifndef VERSION
$(error You need to create a VERSION file to build a release)
endif

# See what commit is tagged to match the version
VERSION_COMMIT = $(strip $(shell git rev-list $(VERSION) -n 1 | cut -c1-7))
ifneq ($(VERSION_COMMIT), $(GIT_COMMIT))
$(error echo You are trying to push a build based on commit $(GIT_COMMIT) but the tagged release version is $(VERSION_COMMIT))
endif

# Don't push to Docker Hub if this isn't a clean repo
ifneq (x$(GIT_NOT_CLEAN_CHECK), x)
$(error echo You are trying to release a build based on a dirty repo)
endif

else
# Add the commit ref for development builds. Mark as dirty if the working directory isn't clean
DOCKER_TAG = $(VERSION)-$(GIT_COMMIT)$(DOCKER_TAG_SUFFIX)
endif

docker_build:
	echo VCS_REF=$(GIT_COMMIT) > .env
	echo BUILD_DATE=`date -u +"%Y-%m-%dT%H:%M:%SZ"` >> .env
	echo VERSION=$(VERSION) >> .env
	echo PACKAGE=$(PACKAGE) >> .env
	echo DOCKER_TAG=$(DOCKER_TAG) >> .env
	echo DOCKER_IMAGE=$(DOCKER_IMAGE) >> .env
	@docker-compose build