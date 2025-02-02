.PHONY: run-nso-node load-neds load-packages prepare-test-network run-tests create-artifact-packages create-artifact-tests clean

run-nso-node:
	@pipeline/scripts/run-nso-node.sh

load-neds:
	@pipeline/scripts/download-neds.sh
	@pipeline/scripts/packages-reload.sh nso_node

load-packages:
	@pipeline/scripts/compile-packages.sh nso_node
	@pipeline/scripts/packages-reload.sh nso_node

prepare-test-network:
	@pipeline/scripts/load-preconfigs.sh nso_node
	@pipeline/scripts/load-netsims.sh nso_node

run-tests:
	@pipeline/scripts/install-testing-libraries.sh nso_node
	@pipeline/scripts/run-robot-tests.sh nso_node

create-artifact-packages:
	@pipeline/scripts/create-artifact-packages.sh nso_node

create-artifact-tests:
	@pipeline/scripts/create-artifact-tests.sh nso_node

clean:
	@pipeline/scripts/clean-resources.sh