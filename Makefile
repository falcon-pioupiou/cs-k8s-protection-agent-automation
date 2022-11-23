
export CONFIG_DIRECTORY=config/

PHONY: base overlays configs

base:
	./1-generate_base_template.sh

overlays:
	./2-generate_overlays.sh

configs:
	./3-generate_configs.sh

cleanup-all:
	echo "delete all base config and overlays"
	rm -rf ${CONFIG_DIRECTORY}

rebuild: cleanup-all base overlays configs