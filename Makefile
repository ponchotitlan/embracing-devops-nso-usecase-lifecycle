.PHONY: run-nso-node load-neds load-packages prepare-test-network clean

run-nso-node:
	@pipeline/scripts/run-nso-node.sh

load-neds:
	@pipeline/scripts/download-neds.sh

load-packages:
	@pipeline/scripts/compile-packages.sh nso_node
	@pipeline/scripts/packages-reload.sh nso_node

prepare-test-network:
	@pipeline/scripts/load-preconfigs.sh nso_node
	@pipeline/scripts/load-netsims.sh nso_node

clean:
	@pipeline/scripts/clean-resources.sh