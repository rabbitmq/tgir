SHELL := bash# we want bash behaviour in all shell invocations
PLATFORM := $(shell uname)
#
# https://stackoverflow.com/questions/4842424/list-of-ansi-color-escape-sequences
RED := \033[1;31m
GREEN := \033[1;32m
YELLOW := \033[1;33m
BOLD := \033[1m
NORMAL := \033[0m



### DEPS ###
#
ifeq ($(PLATFORM),Darwin)
DOCKER ?= /usr/local/bin/docker
COMPOSE ?= $(DOCKER)-compose
$(DOCKER) $(COMPOSE):
	brew cask install docker
else
DOCKER ?= /usr/bin/docker
$(DOCKER):
	$(error Please install docker: https://docs.docker.com/install/linux/docker-ce/ubuntu/)
COMPOSE ?= $(DOCKER)-compose
$(COMPOSE):
	$(error Please install docker-compose: https://docs.docker.com/compose/install/)
endif

ifeq ($(PLATFORM),Darwin)
FFMPEG := /usr/local/bin/ffmpeg
$(FFMPEG):
	brew install ffmpeg
else
FFMPEG ?= /usr/bin/ffmpeg
$(FFMPEG):
	$(error Please install ffmpeg)
endif

CURL ?= /usr/bin/curl
ifneq ($(PLATFORM),Darwin)
$(CURL):
	$(error Please install curl)
endif

ifeq ($(PLATFORM),Darwin)
OPEN := open
else
OPEN := xdg-open
endif

ifeq ($(PLATFORM),Darwin)
GCLOUD := /usr/local/bin/gcloud
$(GCLOUD):
	brew cask install google-cloud-sdk
else
GCLOUD ?= /usr/bin/gcloud
$(GCLOUD):
	$(error Please install gcloud: https://cloud.google.com/sdk/docs/downloads-apt-get)
endif




### TARGETS ###
#

.DEFAULT_GOAL = help

.PHONY: help
help:
	@awk -F": |##" '/^[^\.][0-9a-zA-Z\._\-\%]+:+.+##.+$$/ { printf "\033[36m%-26s\033[0m %s\n", $$1, $$3 }' $(MAKEFILE_LIST) \
	| sort

define MAKE_TARGETS
  awk -F: '/^[^\.%\t\_][0-9a-zA-Z\._\-\%]*:+.*$$/ { printf "%s\n", $$1 }' $(MAKEFILE_LIST)
endef
define BASH_AUTOCOMPLETE
  complete -W \"$$($(MAKE_TARGETS) | sort | uniq)\" make gmake m
endef
.PHONY: bash-autocomplete
bash-autocomplete:
	@echo "$(BASH_AUTOCOMPLETE)"
.PHONY: bac
bac: bash-autocomplete

ifneq ($(GITHUB_USER),)
GRIP_USER := --user $(GITHUB_USER)
endif
ifneq ($(GITHUB_PERSONAL_ACCESS_TOKEN),)
GRIP_PASS := --pass $(GITHUB_PERSONAL_ACCESS_TOKEN)
endif
.PHONY: readme
readme: $(DOCKER)
	$(DOCKER) run --interactive --tty --rm \
	  --volume $(CURDIR):/data \
	  --volume $(HOME)/.grip:/.grip \
	  --expose 5000 --publish 5000:5000 \
	  --name readme \
	  mbentley/grip --context=. 0.0.0.0:5000 $(GRIP_USER) $(GRIP_PASS)

# https://www.bugcodemaster.com/article/convert-video-animated-gif-using-ffmpeg
# https://trac.ffmpeg.org/wiki/Scaling
.PHONY: gif
gif: $(FFMPEG)
ifndef MP4
	$(error MP4 variable must reference a valid mov file path)
endif
	$(FFMPEG) -i $(MP4) \
	  -hide_banner \
	  -vf "fps=1" \
	  $(subst .mp4,-1fps.gif,$(MP4))

.env:
	ln -sf ../../.env .env

FPS ?= 24
FFMPEG_VF = -vf "fps=$(FPS)
MP4_APPEND = -$(FPS)fps
# Scale for videos, use in SCALE=
1080p = scale='min(1920,iw)':'min(1080,ih)'
720p = scale='min(1280,iw)':'min(720,ih)'
ifneq ($($(SCALE)),)
FFMPEG_VF := $(FFMPEG_VF),$($(SCALE))
MP4_APPEND := -$(SCALE)$(MP4_APPEND)
endif
FFMPEG_VF := $(FFMPEG_VF)"

.PHONY: mp4
mp4: $(FFMPEG)
ifndef MOV
	$(error MOV variable must reference a valid mov file path)
endif
	$(FFMPEG) -i $(MOV) \
	  -vcodec h264 $(FFMPEG_VF) \
	  $(subst .mov,$(MP4_APPEND).mp4,$(MOV))

.PHONY: mp4-concat
mp4-concat: $(FFMPEG)
ifndef DIR
	$(error DIR variable must reference the dir where multiple mp4 files are stored)
endif
	$(FFMPEG) -f concat \
	-safe 0 \
	-i <(for f in $(DIR)/*.mp4; do echo "file '$$f'"; done) \
	-c copy \
	$(DIR)/concat.mp4
