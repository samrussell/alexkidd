#include <stdio.h>
#include <SDL2/SDL.h>
#include <SDL/SDL_ttf.h>
#include <emscripten.h>
#include <unistd.h>
#include <stdlib.h>

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

TileBlock* loadTileBlock(const char* filename, int width, int height){
  FILE* tileFile = fopen(filename, "rb");
  int dataCount = width * height;
  Uint16* tileData = new Uint16[dataCount];
  fread(tileData, 1, dataCount * sizeof(tileData), tileFile);
  fclose(tileFile);

  return new TileBlock(width, height, tileData);
}

class Display {
    int width, height;
    SDL_Renderer* renderer;
    SDL_Surface *screen;
    SDL_Texture *texture;
  public:
    Uint32* pixels; // TODO make private, access via methods on Display
    Uint32* palette;
    Uint32** tiles;
    Display(int width, int height, SDL_Renderer* renderer, SDL_Surface* screen, SDL_Texture* texture);
    void printTile(Uint32* tile, Uint32 x, Uint32 y, Uint32 modifiers);
    void printTileBlock(TileBlock* tileBlock, int columnOffset, int rowOffset);
    void render();
};

Display::Display(int width, int height, SDL_Renderer* renderer, SDL_Surface* screen, SDL_Texture* texture){
  this->width = width;
  this->height = height;
  this->renderer = renderer;
  this->screen = screen;
  this->texture = texture;
  pixels = (Uint32*) screen->pixels;
}

void Display::render(){
  SDL_UpdateTexture(texture, NULL, screen->pixels, screen->pitch);
  SDL_RenderClear(renderer);
  SDL_RenderCopy(renderer, texture, NULL, NULL);
  SDL_RenderPresent(renderer);
}

void Display::printTile(Uint32* tile, Uint32 x, Uint32 y, Uint32 modifiers){
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
      Uint32 colourOffset = tile[sourceRow*8 + sourceColumn];
      pixels[(y + rowNum)*256 + (x + columnNum)] = palette[colourOffset];
    }   
  }
}

// TODO put the tiles somewhere that the tileblock can access
void Display::printTileBlock(TileBlock* tileBlock, int columnOffset, int rowOffset){
  for(int row=0; row<tileBlock->height; row++){
    for(int col=0; col<tileBlock->width; col++){
      Uint32 tileIndex = tileBlock->tile(col, row);
      Uint32* tile = tiles[tileIndex & 0x1FF];
      Uint32 modifiers = tileIndex & 0xFE00;
      printTile(tile, (columnOffset + col)*8, (rowOffset + row)*8, modifiers);
    }
  }
}

// kind of a factory to create the display

Display* buildDisplay(int width, int height, SDL_Renderer* renderer){
  SDL_Surface* screen = SDL_CreateRGBSurface(0, width, height, 32, 0x00FF0000, 0x0000FF00, 0x000000FF, 0xFF000000);
  SDL_Texture* texture = SDL_CreateTexture(renderer, SDL_PIXELFORMAT_ARGB8888, SDL_TEXTUREACCESS_STREAMING, width, height);
  return new Display(width, height, renderer, screen, texture);
}

int main()
{
  SDL_Init(SDL_INIT_VIDEO);
  TTF_Init();

  SDL_Window *window;
  SDL_Renderer *renderer;

  Uint32 palette[32];
  char rawPalette[32];

  Uint32 rawTiles[0x1000]; // 0x400 * 32 bit rows
  Uint32* tiles[512];

  SDL_CreateWindowAndRenderer(256, 192, 0, &window, &renderer);

  Display* display = buildDisplay(256, 192, renderer);

  // alex kidd load screen background colour
  for(int i=0; i<256*192; i++){
    display->pixels[i] = 0xFFFFFFAA;
  }

  // TODO put in method
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
  display->palette = palette;

  // load tiles
  FILE* tileFile = fopen("assets/start_screen_tiles.dat", "rb");
  fread(rawTiles, 1, 0x2000, tileFile);
  fclose(tileFile);

  // load sprite tiles too
  // this is quite manual, normally would be loaded in order
  // but this is just enough to get alex swimming
  FILE* sprite1File = fopen("assets/sprite_10.dat", "rb");
  // loaded from tile 0x19 onwards
  // 8x32bit blocks
  // this one has 5 tiles
  fread(&rawTiles[0x800 + 8*0x19], 1, 0xA0, sprite1File);
  fclose(tileFile);

  // TODO this definitely needs to be in a method
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
        Uint32 colourOffset = ((rawRow[columnNum] & 0x01000000) >> 21) | ((rawRow[columnNum] & 0x00010000) >> 14) | ((rawRow[columnNum] & 0x00000100) >> 7) | (rawRow[columnNum] & 0x00000001);
        tile[rowNum*8 + columnNum] = colourOffset;
      }
    }
    tiles[tileNum] = tile;
  }
  display->tiles = tiles;

  TileBlock* logo1Tiles = loadTileBlock("assets/logo1.dat", 14, 6);
  TileBlock* logo2Tiles = loadTileBlock("assets/logo2.dat", 13, 7);
  TileBlock* logo3Tiles = loadTileBlock("assets/logosnippet1.dat", 12, 7);
  TileBlock* logo4Tiles = loadTileBlock("assets/logosnippet2.dat", 14, 6);
  TileBlock* logo5Tiles = loadTileBlock("assets/logosnippet3.dat", 7, 8);
  TileBlock* logo6Tiles = loadTileBlock("assets/logosnippet4.dat", 6, 12);
  TileBlock* logo7Tiles = loadTileBlock("assets/logosnippet5.dat", 12, 16);
  TileBlock* logo8Tiles = loadTileBlock("assets/logosnippet6.dat", 17, 3);
  display->printTileBlock(logo1Tiles, 7, 2);
  display->printTileBlock(logo2Tiles, 13, 7);
  display->printTileBlock(logo3Tiles, 20, 0);
  display->printTileBlock(logo4Tiles, 12, 14);
  display->printTileBlock(logo5Tiles, 0, 0);
  display->printTileBlock(logo6Tiles, 26, 7);
  display->printTileBlock(logo7Tiles, 0, 8);
  display->printTileBlock(logo8Tiles, 13, 20);
  // load tiles for alex swimming


  display->render();
  printf("done\n");

  return 0;
}

