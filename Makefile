.PHONY: run-nso-node load-neds load-packages prepare-test-network run-tests create-artifact-packages create-artifact-tests get-current-release-tag calculate-new-release-tag clean

run-nso-node:
	@pipeline/scripts/run-nso-node.sh

load-neds:
	@pipeline/scripts/download-neds.sh
	@pipeline/scripts/packages-reload.sh

load-packages:
	@pipeline/scripts/compile-packages.sh
	status=$$(pipeline/scripts/packages-reload.sh); \
	if [ "$$status" = "failed" ]; then \
		echo "📦❌ Service Packages loading failed!"; \
		exit 1; \
	else \
		echo "📦✅ Service Packages loading successful!"; \
	fi

prepare-test-network:
	@pipeline/scripts/load-preconfigs.sh
	@pipeline/scripts/load-netsims.sh

run-tests:
	@pipeline/scripts/install-testing-libraries.sh
	status=$$(pipeline/scripts/run-robot-tests.sh); \
	if [ "$$status" = "failed" ]; then \
		echo "🤖❌ At least one test failed!"; \
		exit 1; \
	else \
		echo "🤖✅ All tests were successful!"; \
	fi

create-artifact-packages:
	@pipeline/scripts/create-artifact-packages.sh

create-artifact-tests:
	@pipeline/scripts/create-artifact-tests.sh

get-current-release-tag:
	@pipeline/scripts/get-latest-git-tag.sh

calculate-new-release-tag:
	@pipeline/scripts/increment-git-tag-version.sh $(VERSION)

clean:
	@pipeline/scripts/clean-resources.sh