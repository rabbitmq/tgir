include $(dir $(word $(words $(MAKEFILE_LIST)),$(MAKEFILE_LIST)))/../../Makefile

TGIR := tgir-s01e08

# TODO: We will be using Digital Ocean for this, see E05

KUBECONFIG_DIR := $(XDG_CONFIG_HOME)/kubectl
KUBECONFIG := $(KUBECONFIG_DIR)/config
export KUBECONFIG
$(KUBECONFIG_DIR):
	@mkdir -p $(@)
# TODO: Retrieve kube config from Digital Ocean
$(KUBECONFIG): | $(KUBECTL) $(KUBECONFIG_DIR)
.PHONY: kubeconfig
kubeconfig: $(KUBECONFIG)

.PHONY: k9s
k9s: | $(K9S) $(KUBECONFIG) ## Interact with our K3S instance via a terminal UI
	$(K9S) --all-namespaces

define ENV
export PATH=$(LOCAL_BIN):$$PATH
export XDG_CONFIG_HOME="$(XDG_CONFIG_HOME)"
export KUBECONFIG="$(KUBECONFIG)"
unalias k 2>/dev/null; alias k=kubectl
unalias m 2>/dev/null; alias m=make
endef
export ENV
.PHONY: env
env:: | $(KUBECONFIG_DIR) ## Configure shell env - eval "$(make env)" OR source .env
