
test: assets code

code:
	haxe build_script/common.hxml build_script/test.hxml

lint:
	haxelib run formatter -s src

js: assets
	haxe build_script/common.hxml build_script/js.hxml --no-traces
	cp build_script/index.html build/js/.

jsdebug: assets
	haxe build_script/common.hxml build_script/js.hxml -D debug
	cp build_script/index.html build/js/.

hl: assets
	haxe build_script/common.hxml build_script/hl.hxml

gcc: c
	rm -f ./game
	gcc -O3 -o game -I build/c/ build/c/game.c -lhl /usr/local/lib/*.hdll

c: assets
	haxe build_script/common.hxml build_script/c.hxml

assets:
	cp ./raw/*.png ./res/.

itch:
	cd build/js; zip ../../itch.zip *

clean:
	rm -f ./game
	rm -f ./game.hl
	rm -f -r build/*
