SHELL := bash# we want bash behaviour in all shell invocations
PLATFORM := $(shell uname)
platform = $(shell echo $(PLATFORM) | tr A-Z a-z)
#
# https://stackoverflow.com/questions/4842424/list-of-ansi-color-escape-sequences
RED := \033[1;31m
GREEN := \033[1;32m
YELLOW := \033[1;33m
BOLD := \033[1m
NORMAL := \033[0m

XDG_CONFIG_HOME := $(CURDIR)/.config
export XDG_CONFIG_HOME

THISFILE := $(word $(words $(MAKEFILE_LIST)),$(MAKEFILE_LIST))
THISDIR := $(dir $(THISFILE))
BASEDIR := $(abspath $(THISDIR))
LOCAL_BIN := $(BASEDIR)/bin
$(LOCAL_BIN):
	mkdir -p $@



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

ifeq ($(PLATFORM),Darwin)
BAT ?= /usr/local/bin/bat
$(BAT):
	brew install bat
else
BAT ?= /usr/bin/bat
$(BAT):
	$(error Please install bat: https://github.com/sharkdp/bat)
endif
.PHONY: bat
bat: $(BAT)

K9S_RELEASES := https://github.com/derailed/k9s/releases
K9S_VERSION := 0.22.1
K9S_BIN_DIR := k9s-$(K9S_VERSION)-$(platform)-x86_64
K9S_URL := $(K9S_RELEASES)/download/v$(K9S_VERSION)/k9s_$(PLATFORM)_x86_64.tar.gz
K9S := $(LOCAL_BIN)/$(K9S_BIN_DIR)/k9s
$(K9S): | $(CURL) $(LOCAL_BIN)
	$(CURL) --progress-bar --fail --location --output $(LOCAL_BIN)/$(K9S_BIN_DIR).tar.gz "$(K9S_URL)" \
	&& mkdir -p $(K9S_BIN_DIR) && tar zxf $(K9S_BIN_DIR).tar.gz -C $(K9S_BIN_DIR) \
	&& touch $(K9S) \
	&& chmod +x $(K9S) \
	&& $(K9S) version \
	   | grep $(K9S_VERSION) \
	&& ln -sf $(K9S) $(LOCAL_BIN)/k9s
.PHONY: releases-k9s
releases-k9s:
	$(OPEN) $(K9S_RELEASES)

KUBECTL_RELEASES := https://github.com/kubernetes/kubernetes/releases
# K8S v1.18 is considered stable in October 2020, using latest version available
KUBECTL_VERSION := 1.18.10
KUBECTL_BIN := kubectl-$(KUBECTL_VERSION)-$(platform)-amd64
KUBECTL_URL := https://storage.googleapis.com/kubernetes-release/release/v$(KUBECTL_VERSION)/bin/$(platform)/amd64/kubectl
KUBECTL := $(LOCAL_BIN)/$(KUBECTL_BIN)
$(KUBECTL): | $(CURL) $(LOCAL_BIN)
	$(CURL) --progress-bar --fail --location --output $(KUBECTL) "$(KUBECTL_URL)"
	touch $(KUBECTL)
	chmod +x $(KUBECTL)
	$(KUBECTL) version | grep $(KUBECTL_VERSION)
	ln -sf $(KUBECTL) $(LOCAL_BIN)/kubectl
.PHONY: kubectl
kubectl: $(KUBECTL)

JQ_RELEASES := https://github.com/stedolan/jq/releases
JQ_VERSION := 1.6
JQ_BIN := jq-$(JQ_VERSION)-$(platform)-x86_64
JQ_URL := $(JQ_RELEASES)/download/jq-$(JQ_VERSION)/jq-$(platform)64
ifeq ($(platform),darwin)
JQ_URL := $(JQ_RELEASES)/download/jq-$(JQ_VERSION)/jq-osx-amd64
endif
JQ := $(LOCAL_BIN)/$(JQ_BIN)
$(JQ): | $(CURL) $(LOCAL_BIN)
	$(CURL) --progress-bar --fail --location --output $(JQ) "$(JQ_URL)" \
	&& touch $(JQ) \
	&& chmod +x $(JQ) \
	&& $(JQ) --version \
	   | grep $(JQ_VERSION) \
	&& ln -sf $(JQ) $(LOCAL_BIN)/jq
.PHONY: jq
jq: $(JQ)
.PHONY: releases-jq
releases-jq:
	$(OPEN) $(JQ_RELEASES)

YQ_RELEASES := https://github.com/mikefarah/yq/releases
YQ_VERSION := 3.4.1
YQ_BIN := yq-$(YQ_VERSION)-$(platform)-amd64
YQ_URL := $(YQ_RELEASES)/download/$(YQ_VERSION)/yq_$(platform)_amd64
YQ := $(LOCAL_BIN)/$(YQ_BIN)
$(YQ): | $(CURL) $(LOCAL_BIN)
	$(CURL) --progress-bar --fail --location --output $(YQ) "$(YQ_URL)"
	touch $(YQ)
	chmod +x $(YQ)
	$(YQ) --version | grep $(YQ_VERSION)
	ln -sf $(YQ) $(LOCAL_BIN)/yq
.PHONY: yq
yq: $(YQ)
.PHONY: releases-yq
releases-yq:
	$(OPEN) $(YQ_RELEASES)



### TARGETS ###
#

.DEFAULT_GOAL = help

.PHONY: help
help:
	@awk -F':+ |##' '/^[^\.][0-9a-zA-Z\._\-%]+:+.+##.+$$/ { printf "\033[36m%-26s\033[0m %s\n", $$1, $$3 }' $(MAKEFILE_LIST) \
	| sort

define MAKE_TARGETS
  awk -F':+' '/^[^\.%\t\_][0-9a-zA-Z\._\-\%]*:+.*$$/ { printf "%s\n", $$1 }' $(MAKEFILE_LIST)
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
	time $(FFMPEG) -i $(MP4) \
	  -hide_banner \
	  -vf "fps=1" \
	  $(subst .mp4,-1fps.gif,$(MP4))

.env:
	ln -sf ../../.env .env

.PHONY: env
env::
	@true

FPS ?= 30
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
	time $(FFMPEG) -i $(MOV) \
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
