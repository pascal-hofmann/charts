charts := $(wildcard charts/*/)
scripts := $(wildcard scripts/**/*.sh)

# Minikube related targets
minikube-start: ## Startup local minikube cluster
	minikube status 2> /dev/null > /dev/null || minikube start --vm-driver kvm2 --memory 4000
	minikube update-context

minikube-delete: ## Delete local minikube cluster
	minikube delete

minikube-install-helm: minikube-start ## Install Helm inside a cluster
	helm version --server 2> /dev/null > /dev/null || helm init --wait

minikube-install-chart: minikube-install-helm ## Install the chart provided as parameter
ifeq ("$(chart)","")
	$(error Please set the chart parameter)
else
	helm upgrade $(chart) charts/$(chart) --install
endif
# Chart related targets
chart-lint: ## Lint all charts
	@$(foreach chart,$(charts),helm lint --strict $(chart);)

chart-package: ## Package all charts
	mkdir -p repo
	@$(foreach chart,$(charts),helm dependency build $(chart);)
	@$(foreach chart,$(charts),helm package $(chart) --destination repo;)
ifneq ("$(wildcard repo/index.yaml)","")
	helm repo index --merge repo/index.yaml repo
else
	helm repo index repo
endif

# Script related targets
scripts-lint: ## Lint all scripts
	@$(foreach script,$(scripts),shellcheck -x $(script);)

# Meta-targets
.DEFAULT_GOAL := help
.PHONY: help
help:
	@echo Available targets:
	@grep -E '^[a-zA-Z_-]+:.*## .*$$' Makefile | sort | sed -e 's/^\(.*\):.*## \(.*\)$$/  \1\t\2/g' | expand -t 40