CC = emcc
all: alex.c
	$(CC) alex.c -O2 -s USE_SDL=2 -s USE_SDL_TTF=2 --preload-file assets -o index.html
