.PHONY: all clean slides server stop

all: slides

clean:
	rm -rf build

slides:
	mkdir -p build/slides
	docker compose run -e MARP_USER=$(shell id -u):$(shell id -g) generate --input-dir ./slides --output ./build/slides/
	docker compose run -e MARP_USER=$(shell id -u):$(shell id -g) generate --input-dir ./slides --output ./build/slides/ --pdf

server:
	docker compose run -e MARP_USER=$(shell id -u):$(shell id -g) -p 8080:8080 generate --server --watch ./slides

stop:
	docker compose down
