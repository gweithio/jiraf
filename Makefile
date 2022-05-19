.PHONY: test
default: build

run: 
	odin run src/*.odin -file -warnings-as-errors -collection:shared=src -collection:pkg=pkg

test: 
	odin test tests -warnings-as-errors -show-timings -collection:shared=src -collection:pkg=pkg

build: 
	odin build src -o:speed -out:jiraf -collection:shared=src -collection:pkg=pkg

install:
	make build && make move 

move:
	cp jiraf ~/bin

clean:
	rm tests/.bin
	rm src/.bin
	rm jiraf
