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
	@brew cask install docker
else
DOCKER ?= /usr/bin/docker
$(DOCKER):
	$(error Please install docker)
COMPOSE ?= $(DOCKER)-compose
$(COMPOSE):
	$(error Please install docker-compose)
endif



### TARGETS ###
#

.DEFAULT_GOAL = help

.PHONY: help
help:
	@awk -F": |##" '/^[^\.][a-zA-Z\._\-]+:+.+##.+$$/ { printf "\033[36m%-24s\033[0m %s\n", $$1, $$3 }' $(MAKEFILE_LIST) \
	| sort

define MAKE_TARGETS
  awk -F: '/^[^\.%\t][a-zA-Z\._\-]*:+.*$$/ { printf "%s\n", $$1 }' $(MAKEFILE_LIST)
endef
define BASH_AUTOCOMPLETE
  complete -W \"$$($(MAKE_TARGETS) | sort | uniq)\" make gmake m
endef
.PHONY: bash_autocomplete
bash_autocomplete: ## bac | Configure bash shell autocomplete - eval "$(make bash_autocomplete)"
	@echo "$(BASH_AUTOCOMPLETE)"
.PHONY: bac
bac: bash_autocomplete

ifneq ($(GITHUB_USER),)
GRIP_USER := --user $(GITHUB_USER)
endif
ifneq ($(GITHUB_PERSONAL_ACCESS_TOKEN),)
GRIP_PASS := --pass $(GITHUB_PERSONAL_ACCESS_TOKEN)
endif
.PHONY: preview_readme
preview_readme: $(DOCKER) ## pre | Preview README & live reload on edit - http://docker.localhost:5000
	@$(DOCKER) run --interactive --tty --rm \
	  --volume $(CURDIR):/data \
	  --volume $(HOME)/.grip:/.grip \
	  --expose 5000 --publish 5000:5000 \
	  mbentley/grip --context=. 0.0.0.0:5000 $(GRIP_USER) $(GRIP_PASS)
.PHONY: pre
pre: preview_readme
