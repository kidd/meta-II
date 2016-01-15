all:
	perl metaII.pl > meta.lua
	lua meta.lua < bootstrap.txt >m2.lua
	lua m2.lua < bootstrap.txt >m3.lua
	diff m2.lua m3.lua
