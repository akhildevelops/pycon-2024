CFLAGS = -Ofast -shared -fpic
SHELL:=/bin/bash
add.so: add/add.c
	$(CC) $(CFLAGS) -o build/$@ $<

prime.so: prime/prime.c
	$(CC) $(CFLAGS) -o build/$@ $<

concat.so: concat/concat.c
	$(CC) $(CFLAGS) -o build/$@ $<

add: add.so
	python3 add/add.py

concat: concat.so
	python3 concat/concat_c.py

prime: prime.so
	time python3 prime/prime_c.py 100000
	echo -e "\n\n"
	time python3 prime/prime_py.py 100000

.PHONY:clean build

clean:
	rm -rf build/*.so

build:
	mkdir -p build

all: build add.so prime.so concat.so