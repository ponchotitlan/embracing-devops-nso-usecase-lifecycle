.PHONY: all render register build run up compile reload netsims down run-tests ai-analyze-tests create-artifact-packages create-artifact-tests clean deep-clean

# Makefile for building, creating and cleaning
# the NSO and CXTA containers for this development environment.

# Requirements:
# 1. Docker and Docker Compose installed and running.
# 2. BuildKit enabled (usually default in recent Docker versions, or set DOCKER_BUILDKIT=1).
# 3. A 'docker-compose.yml' file defining the services for NSO and CXTA, plus the runtime secrets.
# 4. A 'Dockerfile' for the NSO custom image, configured to use BuildKit's

# Default target: build and then up
all: up

# Target to render the templates in this repository (*j2 files) with the information from config.yaml
render:
	@echo "--- ✨ Rendering templates ---"
	./setup/render-templates.sh

# Target to mount a local Docker registry on localhost:5000 for your NSO container image,
# in case it comes from a clean `docker loads` and it is not hosted in a registry
register:
	@echo "--- 📤 Mounting local registry (if needed) ---"
	./setup/mount-registry-server.sh

# Target to build the Docker image with secrets
# The Dockerfile in the repository is used for this
# The Docker BuildKit is used for best security practices - The secrets are not recorded in the layers history
build:
	@echo "--- 🏗️ Building NSO custom image with BuildKit secrets ---"
	./setup/build-image.sh

# Target to run the docker compose services with healthcheck
# We don't know how long the NSO container is going to take to become healthy.
# as it depends on the artifacts and NEDs from the custom image.
# Therefore, we are using a script instead of a fixed timed.
run:
	@echo "--- 🚀 Starting Docker Compose services ---"
	./setup/run-services.sh

# Target to run the `packages reload` command in the CLI
# of the NSO container
compile:
	@echo "--- 🛠️ Compiling your services ---"
	./setup/compile-packages.sh

# Target to run the `packages reload` command in the CLI
# of the NSO container
reload:
	@echo "--- 🔀 Reloading the services ---"
	./setup/packages-reload.sh

# Target to create and onboard the netsim devices
# in the NSO container
netsims:
	@echo "--- ⬇️ Loading preconfiguration files ---"
	./setup/load-preconfigs.sh
	@echo "--- 🛸 Loading netsims ---"
	./setup/load-netsims.sh

# Target to start Docker Compose services
up: render register build run compile reload netsims

# Target to stop Docker Compose services
down:
	@echo "--- 🛑 Stopping Docker Compose services ---"
	docker compose down

run-tests:
	@echo "--- 🤖 Running Robot Framework tests ---"
	./setup/install-testing-libraries.sh
	status=$$(./setup/run-robot-tests.sh); \
	if [ "$$status" = "failed" ]; then \
		echo "🤖❌ At least one test failed!"; \
		exit 1; \
	else \
		echo "🤖✅ All tests were successful!"; \
	fi

ai-analyze-tests:
	@echo "--- 🧠 Analyzing test results with AI ---"
	./setup/run-ai-analysis.sh

create-artifact-packages:
	./setup/create-artifact-packages.sh

create-artifact-tests:
	./setup/create-artifact-tests.sh

# Target to clean resources (stop containers, remove NEDs)
clean:
	@echo "--- 🧹 Cleaning resources ---"
	./setup/clean-resources.sh

# Target to deep clean (includes volumes and NSO state files)
deep-clean: down
	@echo "--- 🧹🔥 Deep cleaning (volumes and state) ---"
	docker compose down -v
	docker volume rm -f my-nso-cicd-local-dev-etc 2>/dev/null || true
	rm -rf ncs/ssh/ ncs/ssl/ ncs/ncs.crypto_keys
	rm -f docker-compose.yml Dockerfile
	@echo "--- ✅ Deep clean complete. Run 'make up' to rebuild ---"