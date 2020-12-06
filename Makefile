MAKEFLAGS += --silent
SHELL := /usr/bin/env bash
DOCKER_COMPOSE := $(shell which docker-compose)
DOCKER_COMPOSE_CI := $(DOCKER_COMPOSE) -f docker-compose.ci.yml
DOCKER_COMPOSE_INTEGRATION := $(shell which docker-compose) -f docker-compose.integration.yml
DOCKER_COMPOSE_PRODUCTION := $(shell which docker-compose) -f docker-compose.production.yml
ENV_PASSWORD ?= false ## Provide an environment password for encrypt_env and decrypt_env.
DEPLOY_FUNCTIONS_ONLY ?= false ## Do you want to skip building infrastructure and just deploy functions? Only applicable in integration.
SLS_DEBUG ?= false ## Set this to true to print debugging info from Serverless.

.PHONY: deploy_integration \
	destroy_integration \
	deploy_production \
	destroy_production \
	create_env \
	encrypt_env \
	decrypt_env \
	integration_endpoint


usage: ## Prints this help text.
	printf "make [target]\n\
Hack on $$(make project_name).\n\
\n\
TARGETS\n\
\n\
$$(fgrep -h '##' $(MAKEFILE_LIST) | fgrep -v '?=' | fgrep -v grep | sed 's/\\$$//' | sed -e 's/##//' | sed 's/^/  /g')\n\
\n\
ENVIRONMENT VARIABLES\n\
\n\
$$(fgrep '?=' $(MAKEFILE_LIST) | grep -v grep | sed 's/\?=.*##//' | sed 's/^/  /g')\n\
\n\
NOTES\n\
\n\
	- Adding a new stage? Add a comment with two pound signs after the stage name to add it to this help text.\n"


integration_endpoint: ## Obtains the serverless endpoint used for the 'deploy' integration environment.
	$$($(DOCKER_COMPOSE_INTEGRATION) run --rm serverless info | \
					 grep -r "GET -" | \
					 sed 's/.*GET - //' | \
					 sed 's/\(\/develop\).*/\1/'); \

deploy_integration: ## Deploys serverless functions into an integration env.
	skip_infra=false; \
	if test "$(DEPLOY_FUNCTIONS_ONLY)" == "true"; \
	then \
		if test -d ./secrets && ! test -z "$$(find ./secrets -mindepth 1)"; \
		then >&2 echo "INFO: Infrastructure deployment skipped."; skip_infra=true; \
		else >&2 echo "WARNING: DEPLOY_FUNCTIONS_ONLY specified but no infrastructure \
has been deployed yet. Ignoring."; \
		fi; \
	fi; \
	test "$$skip_infra" != "true" && $(DOCKER_COMPOSE_INTEGRATION) run --rm deploy-serverless-infra; \
	$(DOCKER_COMPOSE_INTEGRATION) run --rm deploy-serverless-functions;

destroy_integration: ## Destroys the serverless integration environment.
	for stage in destroy-serverless-functions destroy-serverless-infra; \
	do $(DOCKER_COMPOSE_INTEGRATION) run --rm "$$stage" || exit 1; \
	done

deploy_production: ## Deploys serverless functions into a production environment.
	if test "$(DEPLOY_FUNCTIONS_ONLY)" != "false"; \
	then \
		>&2 echo "WARNING: DEPLOY_FUNCTIONS_ONLY only applies during integration testing."; \
	fi; \
	for stage in deploy-serverless-infra deploy-serverless-domain deploy-serverless-functions; \
	do $(DOCKER_COMPOSE_PRODUCTION) run --rm "$$stage" || exit 1; \
	done

destroy_production: ## CAREFUL! Destroys the serverless production environment.
	for stage in destroy-serverless-functions destroy-serverless-infra; \
	do $(DOCKER_COMPOSE_PRODUCTION) run --rm "$$stage" || exit 1; \
	done

create_env: create_config_yml
create_env:
	if test -e .env; \
	then \
		>&2 echo "ERROR: A dotenv already exists here. 'rm -f .env' to remove it."; \
		exit 1; \
	fi; \
	cat .env.example | grep -Ev '^#' | grep -Ev '^$$' > .env; \
	if ! test -e .gitignore || ! grep -q '.env' .gitignore; \
	then \
		printf '.env\nsecrets/\n' >> .gitignore; \
	fi
	>&2 echo "INFO: New dotenv created and added to your .gitignore."

encrypt_env: check_for_env_password
encrypt_env: ## Encrypts environment dotfiles.
	ENV_PASSWORD=$(ENV_PASSWORD) $(DOCKER_COMPOSE_CI) run --rm encrypt_env

decrypt_env: check_for_env_password
decrypt_env: ## Decrypts environment dotfiles.
	ENV_PASSWORD=$(ENV_PASSWORD) $(DOCKER_COMPOSE_CI) run --rm decrypt_env

create_config_yml:
	if ! test -e config.yml; \
	then \
		cp config.yml.example config.yml; \
	fi;

check_for_env_password:
	if test -z $(ENV_PASSWORD); \
	then \
		>&2 echo "ERROR: Please provide a password for your environment. Add \
	ENV_PASSWORD=your-password-here to the beginning of your command to do this."; \
		exit 1; \
	fi

project_name:
	cat config.yml | grep project | cut -f2 -d : | tr -d ' '

logs:
	$(DOCKER_COMPOSE) -f docker-compose.$(ENVIRONMENT).yml run --rm \
		serverless logs -f $(FUNCTION_NAME)
