ENVFILE = ""
ifneq (, $(wildcard ./.env))
	ENVFILE = .env
else
	ENVFILE = .env.example
endif

include ${ENVFILE}
export

WARN = \e[1;33m
UNCOLOR = \e[0m

CERT_FILE_ARRAY = ${HOST_CERT_PATH}/${DEFAULT_PUBLIC_CERT} ${HOST_CERT_PATH}/${DEFAULT_PRIVATE_KEY}

.PHONY: create-network
.create-network:
	@docker network create ${GATEWAY_NETWORK} --driver=bridge --attachable --internal=false 2> /dev/null && echo "Created network ${GATEWAY_NETWORK}" || echo "${WARN}Network ${GATEWAY_NETWORK} already exists${UNCOLOR}"

.PHONY: configure-local-settings
.configure-local-settings:
	@cp -n .env.example .env
	@mkdir -p acme ${HOST_CERT_PATH} ${CUSTOM_HOST_SECRET_STORE}
	@$(foreach file,${CERT_FILE_ARRAY},$(test ! -r $(file) -a -f $(file) && echo "${WARN}Certificate file `$(file)` does not exist or is not readable.${UNCOLOR}" || echo "Cerficate `$(file)` readable."))
	@touch -a acme/acme.json && chmod 600 acme/acme.json
	@cp -n authelia/secrets.example/* authelia/secrets/ && chmod 600 authelia/secrets/*

.PHONY: build
.build:
	@echo "Building docker images..." && docker-compose build 2>&1 >/dev/null

.PHONY: up
.up:
	@echo "Starting service..." && docker-compose up -d

.PHONY: seed
.seed:
	@echo "Seeding example user..."
	-bin/add_user authelia/example.ldif

.PHONY: clean
.clean:
	@docker-compose down

.PHONY: sanitize
.sanitize:
	@docker-compose down -v
	@docker network rm ${GATEWAY_NETWORK} 2> /dev/null && echo "Removed network: ${GATEWAY_NETWORK}" || echo "Network ${GATEWAY_NETWORK} could not be removed, and may still be in use by other containers/compose stacks."

.PHONY: target
target: .create-network .configure-local-settings .build .clean .up

.PHONY: testing
testing: .create-network .configure-local-settings .build .sanitize .up .seed
