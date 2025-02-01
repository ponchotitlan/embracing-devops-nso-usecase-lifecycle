.PHONY: run-nso-node download-neds prepare-testbed clean

run-nso-node:
	@pipeline/scripts/run-nso-node.sh

download-neds:
	@pipeline/scripts/download-neds.sh
	@pipeline/scripts/packages-reload.sh nso_node

prepare-testbed:
	@pipeline/scripts/load-preconfigs.sh nso_node
	@pipeline/scripts/load-netsims.sh nso_node

clean:
	@pipeline/scripts/clean-resources.sh