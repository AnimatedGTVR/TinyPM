.PHONY: build clean install uninstall test

build:
	./scripts/build.sh

clean:
	./scripts/build.sh --clean

install:
	./scripts/install.sh

uninstall:
	./scripts/uninstall.sh

test:
	./scripts/e2e-smoke.sh
