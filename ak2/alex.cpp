#include <stdio.h>
#include <SDL2/SDL.h>
#include <SDL/SDL_ttf.h>
#include <emscripten.h>
#include <unistd.h>
#include <stdlib.h>

void printTile(Uint32* pixels, Uint32* tile, Uint32 x, Uint32 y, Uint32 modifiers){
  for(int rowNum=0; rowNum<8; rowNum++){
    for(int columnNum=0; columnNum<8; columnNum++){
      Uint32 sourceRow = rowNum;
      Uint32 sourceColumn = columnNum;
      // horizontal flip
      if (modifiers & 0x200) {
        sourceColumn = 7 - sourceColumn;
      }
      // vertical flip
      if (modifiers & 0x400) {
        sourceRow = 7 - sourceRow;
      }
      pixels[(y + rowNum)*256 + (x + columnNum)] = tile[sourceRow*8 + sourceColumn];
    }   
  }
}

class Display {
    int width, height;
    SDL_Renderer* renderer;
    SDL_Surface *screen;
    SDL_Texture *texture;
  public:
    Uint32* pixels; // TODO make private, access via methods on Display
    Display(SDL_Renderer* renderer, int width, int height);
    void render();
};

Display::Display(SDL_Renderer* renderer, int width, int height){
  this->renderer = renderer;
  this->width = width;
  this->height = height;
  screen = SDL_CreateRGBSurface(0, width, height, 32, 0x00FF0000, 0x0000FF00, 0x000000FF, 0xFF000000);
  texture = SDL_CreateTexture(renderer, SDL_PIXELFORMAT_ARGB8888, SDL_TEXTUREACCESS_STREAMING, width, height);
  pixels = (Uint32*) screen->pixels;
}

void Display::render(){
  SDL_UpdateTexture(texture, NULL, screen->pixels, screen->pitch);
  SDL_RenderClear(renderer);
  SDL_RenderCopy(renderer, texture, NULL, NULL);
  SDL_RenderPresent(renderer);
}

class TileBlock {
    Uint16* tileData;
  public:
    int width, height;
    TileBlock(int width, int height, Uint16* tileData);
    Uint16 tile(int column, int row);
};

TileBlock::TileBlock(int width, int height, Uint16* tileData){
  this->width = width;
  this->height = height;
  this->tileData = tileData;
}

Uint16 TileBlock::tile(int column, int row){
  return this->tileData[row*this->width + column];
}

TileBlock* loadTiles(const char* filename, int width, int height){
  FILE* tileFile = fopen(filename, "rb");
  int dataCount = width * height;
  Uint16* tileData = new Uint16[dataCount];
  fread(tileData, 1, dataCount * sizeof(tileData), tileFile);
  fclose(tileFile);

  return new TileBlock(width, height, tileData);
}

// TODO put the tiles somewhere that the tileblock can access
// given these point to vram i guess the display owns this too?
// this method probably lives on Display
void printTileBlock(TileBlock* tileBlock, Display* display, Uint32** tiles, int columnOffset, int rowOffset){
  for(int row=0; row<tileBlock->height; row++){
    for(int col=0; col<tileBlock->width; col++){
      Uint32 tileIndex = tileBlock->tile(col, row);
      Uint32* tile = tiles[tileIndex & 0x1FF];
      Uint32 modifiers = tileIndex & 0xFE00;
      printTile(display->pixels, tile, (columnOffset + col)*8, (rowOffset + row)*8, modifiers);
    }
  }
}

int main()
{
  SDL_Init(SDL_INIT_VIDEO);
  TTF_Init();

  SDL_Window *window;
  SDL_Renderer *renderer;

  Uint32 palette[32];
  char rawPalette[32];

  Uint32 rawTiles[0x800]; // 0x400 * 32 bit rows
  Uint32* tiles[512];

  SDL_CreateWindowAndRenderer(256, 192, 0, &window, &renderer);

  Display* display = new Display(renderer, 256, 192);

  // alex kidd load screen background colour
  for(int i=0; i<256*192; i++){
    display->pixels[i] = 0xFFFFFFAA;
  }

  // load palette
  FILE* paletteFile = fopen("assets/logopalette.dat", "rb");
  fread(rawPalette, 1, 32, paletteFile);
  fclose(paletteFile);

  // convert these to colours
  for(int i=0; i<32; i++){
    char red = rawPalette[i] & 0x3;
    char green = (rawPalette[i] >> 2) & 0x3;
    char blue = (rawPalette[i] >> 4) & 0x3;
    palette[i] = (0xFF << 24) | ((red * 0x55) << 16) | ((green * 0x55) << 8) | (blue * 0x55);
  }

  // load tiles
  FILE* tileFile = fopen("assets/start_screen_tiles.dat", "rb");
  fread(rawTiles, 1, 0x2000, tileFile);
  fclose(tileFile);

  // convert some and apply palette
  // we'll go with tile #67 - a few colours, top right part of the A

  for(int tileNum=0; tileNum<512; tileNum++){
    Uint32 tileOffset = tileNum * 8;
    Uint32* tile = new Uint32[8*8];
    for(int rowNum=0; rowNum<8; rowNum++){
      // we do row at a time
      // 4 bits per pixel, striped across
      // weak version here for now
      Uint32 rawRow[8];
      Uint32 rowData = rawTiles[tileOffset + rowNum];

      rawRow[0] = (rowData & 0x80808080) >> 7;
      rawRow[1] = (rowData & 0x40404040) >> 6;
      rawRow[2] = (rowData & 0x20202020) >> 5;
      rawRow[3] = (rowData & 0x10101010) >> 4;
      rawRow[4] = (rowData & 0x08080808) >> 3;
      rawRow[5] = (rowData & 0x04040404) >> 2;
      rawRow[6] = (rowData & 0x02020202) >> 1;
      rawRow[7] = (rowData & 0x01010101);

      for(int columnNum=0; columnNum<8; columnNum++){
        Uint32 offset = ((rawRow[columnNum] & 0x01000000) >> 21) | ((rawRow[columnNum] & 0x00010000) >> 14) | ((rawRow[columnNum] & 0x00000100) >> 7) | (rawRow[columnNum] & 0x00000001);
        tile[rowNum*8 + columnNum] = palette[offset];
      }
    }
    tiles[tileNum] = tile;
  }

  TileBlock* logo1Tiles = loadTiles("assets/logo1.dat", 14, 6);
  TileBlock* logo2Tiles = loadTiles("assets/logo2.dat", 13, 7);
  TileBlock* logo3Tiles = loadTiles("assets/logosnippet1.dat", 12, 7);
  TileBlock* logo4Tiles = loadTiles("assets/logosnippet2.dat", 14, 6);
  TileBlock* logo5Tiles = loadTiles("assets/logosnippet3.dat", 7, 8);
  TileBlock* logo6Tiles = loadTiles("assets/logosnippet4.dat", 6, 12);
  TileBlock* logo7Tiles = loadTiles("assets/logosnippet5.dat", 12, 16);
  TileBlock* logo8Tiles = loadTiles("assets/logosnippet6.dat", 17, 3);
  printTileBlock(logo1Tiles, display, tiles, 7, 2);
  printTileBlock(logo2Tiles, display, tiles, 13, 7);
  printTileBlock(logo3Tiles, display, tiles, 20, 0);
  printTileBlock(logo4Tiles, display, tiles, 12, 14);
  printTileBlock(logo5Tiles, display, tiles, 0, 0);
  printTileBlock(logo6Tiles, display, tiles, 26, 7);
  printTileBlock(logo7Tiles, display, tiles, 0, 8);
  printTileBlock(logo8Tiles, display, tiles, 13, 20);

  display->render();
  printf("done\n");

  return 0;
}

