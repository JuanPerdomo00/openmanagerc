FLAGS = -extra-linker-flags:"-lraylib -lm"

build:
	odin build . $(FLAGS)

run:
	odin run . $(FLAGS)

clean:
	rm -f openmanagerc

.PHONY: build run clean
