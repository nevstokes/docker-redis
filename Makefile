IMAGE_NAME = nevstokes/redis

export

.DEFAULT_GOAL := help
.PHONY: build help test

build: Dockerfile hooks/build ## Build the Docker image
	@./hooks/build

help: ## Display list and descriptions of available targets
	@awk -F ':|\#\#' '/^[^\t].+:.*\#\#/ {printf "\033[36m%-15s\033[0m %s\n", $$1, $$NF }' $(MAKEFILE_LIST) | sort

test: ## Output the version in the image by way of a quick test
	@docker run --rm --entrypoint redis-cli $(IMAGE_NAME) -v | awk '{ print $$NF }'
