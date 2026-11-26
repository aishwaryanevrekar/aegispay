BIN := $(HOME)/.foundry/bin
FORGE := $(BIN)/forge
ANVIL := $(BIN)/anvil

.PHONY: clean build test demo deploy install

clean:
	@find . -name '._*' -type f -delete

install: clean
	$(FORGE) install foundry-rs/forge-std --no-commit

build: clean
	$(FORGE) build

test: clean
	$(FORGE) test -vv

demo: clean
	$(ANVIL) --silent > /tmp/aegis-anvil.log 2>&1 & \
	sleep 2; \
	$(FORGE) script script/DemoFlow.s.sol --rpc-url http://127.0.0.1:8545 --broadcast

deploy: clean
	$(FORGE) script script/Deploy.s.sol --rpc-url $(AEVUM_RPC_URL) --broadcast
