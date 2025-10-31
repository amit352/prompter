.PHONY: help install test build clean prompter prompter-docker docker-build docker-up docker-down docker-shell dev example

# Default target
.DEFAULT_GOAL := help

# Colors for output
CYAN := \033[0;36m
GREEN := \033[0;32m
YELLOW := \033[0;33m
RESET := \033[0m

##@ General

help: ## Display this help message
	@echo "$(CYAN)Prompter - Interactive Configuration Generator$(RESET)"
	@echo ""
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make $(CYAN)<target>$(RESET)\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  $(CYAN)%-20s$(RESET) %s\n", $$1, $$2 } /^##@/ { printf "\n$(YELLOW)%s$(RESET)\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

##@ Development

install: ## Install gem dependencies
	@echo "$(GREEN)Installing dependencies...$(RESET)"
	bundle install

test: ## Run test suite
	@echo "$(GREEN)Running tests...$(RESET)"
	bundle exec rspec

test-verbose: ## Run tests with verbose output
	@echo "$(GREEN)Running tests with verbose output...$(RESET)"
	bundle exec rspec --format documentation

build: ## Build gem package
	@echo "$(GREEN)Building gem...$(RESET)"
	gem build prompter.gemspec

install-local: build ## Build and install gem locally
	@echo "$(GREEN)Installing gem locally...$(RESET)"
	gem install ./prompter-*.gem

clean: ## Clean build artifacts
	@echo "$(GREEN)Cleaning build artifacts...$(RESET)"
	rm -f *.gem

##@ Running Prompter

prompter: ## Run prompter (Usage: make prompter [SCHEMA=path] [OUTPUT=path])
	@if [ -z "$(SCHEMA)" ] && [ -z "$(OUTPUT)" ]; then \
		echo "$(GREEN)Running prompter with default deployment schema...$(RESET)"; \
		ruby -Ilib bin/prompter deployment/schema.yml deployment/output.yml; \
	elif [ -z "$(OUTPUT)" ]; then \
		echo "$(GREEN)Running prompter with schema: $(SCHEMA)$(RESET)"; \
		ruby -Ilib bin/prompter $(SCHEMA); \
	else \
		echo "$(GREEN)Running prompter with schema: $(SCHEMA) -> output: $(OUTPUT)$(RESET)"; \
		ruby -Ilib bin/prompter $(SCHEMA) $(OUTPUT); \
	fi

dev: ## Run prompter with development schema (quick test)
	@echo "$(GREEN)Running development test schema...$(RESET)"
	ruby -Ilib bin/prompter examples/simple_test.yml examples/dev_output.yml

example: ## Run full feature example schema
	@echo "$(GREEN)Running full feature example...$(RESET)"
	ruby -Ilib bin/prompter examples/full_feature_test.yml examples/example_output.yml

processor-example: ## Run processor feature example (requires processor setup)
	@echo "$(GREEN)Running processor example...$(RESET)"
	ruby -r ./examples/processors/feature_flag_processor.rb \
		-Ilib bin/prompter \
		examples/processor_test.yml \
		examples/processor_output.yml

##@ Docker

docker-build: ## Build Docker image
	@echo "$(GREEN)Building Docker image...$(RESET)"
	docker-compose build

docker-up: ## Run prompter with Docker Compose (default schema)
	@echo "$(GREEN)Running prompter in Docker...$(RESET)"
	docker-compose run --rm prompter

docker-prompter: ## Run prompter in Docker (Usage: make docker-prompter SCHEMA=file OUTPUT=file)
	@if [ -z "$(SCHEMA)" ]; then \
		echo "$(GREEN)Running Docker prompter with defaults...$(RESET)"; \
		docker-compose run --rm prompter; \
	elif [ -z "$(OUTPUT)" ]; then \
		echo "$(GREEN)Running Docker prompter with schema: $(SCHEMA)$(RESET)"; \
		docker-compose run --rm prompter $(SCHEMA); \
	else \
		echo "$(GREEN)Running Docker prompter with schema: $(SCHEMA) -> output: $(OUTPUT)$(RESET)"; \
		docker-compose run --rm prompter $(SCHEMA) $(OUTPUT); \
	fi

docker-shell: ## Access Docker development shell
	@echo "$(GREEN)Starting Docker development shell...$(RESET)"
	docker-compose run --rm --profile dev prompter-shell

docker-down: ## Stop and remove Docker containers
	@echo "$(GREEN)Stopping Docker containers...$(RESET)"
	docker-compose down

docker-clean: ## Remove Docker containers, images, and volumes
	@echo "$(GREEN)Cleaning Docker resources...$(RESET)"
	docker-compose down -v --rmi all

##@ Testing

test-skip-if: ## Test skip_if functionality
	@echo "$(GREEN)Testing skip_if in nested children...$(RESET)"
	ruby examples/test_skip_if_simple.rb

test-nested-dig: ## Test nested dig functionality
	@echo "$(GREEN)Testing nested dig access...$(RESET)"
	ruby examples/test_nested_dig_fix.rb

test-processor: ## Test processor functionality
	@echo "$(GREEN)Testing processor feature...$(RESET)"
	ruby examples/test_processor.rb

test-all-examples: test-skip-if test-nested-dig test-processor ## Run all example tests
	@echo "$(GREEN)All example tests completed!$(RESET)"

##@ Git

status: ## Show git status
	@git status

diff: ## Show git diff
	@git diff

log: ## Show recent git commits
	@git log --oneline -10

branch: ## Show current branch
	@git branch -v

##@ Documentation

docs-help: ## Show CLI help
	@ruby -Ilib bin/prompter --help

docs-examples: ## Show CLI examples
	@ruby -Ilib bin/prompter --examples

docs-version: ## Show version
	@ruby -Ilib bin/prompter --version

##@ Quick Commands

quick-start: install prompter ## Quick start: install and run with defaults
	@echo "$(GREEN)Quick start completed!$(RESET)"

docker-start: docker-build docker-up ## Quick Docker start: build and run
	@echo "$(GREEN)Docker quick start completed!$(RESET)"

# Special targets for arguments
.PHONY: args
args:
	@echo "Available arguments:"
	@echo "  SCHEMA=path/to/schema.yml  - Path to schema file"
	@echo "  OUTPUT=path/to/output.yml  - Path to output file"
	@echo ""
	@echo "Examples:"
	@echo "  make prompter"
	@echo "  make prompter SCHEMA=custom.yml"
	@echo "  make prompter SCHEMA=custom.yml OUTPUT=result.yml"
	@echo "  make docker-prompter SCHEMA=schema.yml OUTPUT=output.yml"
