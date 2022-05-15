.PHONY: test
default: run

run: 
	odin run src/*.odin -file -warnings-as-errors -collection:shared=src

test: 
	odin test tests -warnings-as-errors -show-timings -collection:shared=src

build: 
	odin build src -o:speed -out:jiraf -collection:shared=src

install:
	make build && mv jiraf ~/bin

clean:
	rm tests/.bin
	rm src/.bin
	rm jiraf
