default: all

SRC = $(shell find src -name "*.ls" -type f | sort)
LIB = $(SRC:src/%.ls=lib/%.js)
BIN = bin/putiodl
LSC = node_modules/.bin/lsc

lib:
	mkdir -p lib/

lib/%.js: src/%.ls lib
	$(LSC) --output lib --bare --compile "$<"

bin/putiodl:	bin/putiodl.ls
	(echo "#!/usr/bin/env node" ; $(LSC) --bare --compile --print bin/putiodl.ls) > bin/putiodl
	chmod +x bin/putiodl

.PHONY: build clean

all: build

build: $(LIB) $(BIN)

clean:
	rm -rf lib
