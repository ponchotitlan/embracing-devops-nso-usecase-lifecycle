.PHONY: run-nso-node download-neds test clean

run-nso-node:
	@pipeline/scripts/run-nso-node.sh

download-neds:
	@pipeline/scripts/download-neds.sh
	@pipeline/scripts/packages-reload.sh nso_node

test:
	@pipeline/scripts/load-preconfigs.sh nso_node

clean:
	@pipeline/scripts/clean-resources.sh