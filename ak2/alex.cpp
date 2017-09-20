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

class TileBlock {
    int width, height;
    Uint16* tileData;
  public:
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

  // do pixel stuff
  SDL_Surface *screen = SDL_CreateRGBSurface(0, 256, 192, 32, 0x00FF0000, 0x0000FF00, 0x000000FF, 0xFF000000);
  SDL_Texture *texture = SDL_CreateTexture(renderer, SDL_PIXELFORMAT_ARGB8888, SDL_TEXTUREACCESS_STREAMING, 256, 192);

  // alex kidd load screen background colour
  Uint32* pixels = (Uint32*) screen->pixels;
  for(int i=0; i<256*192; i++){
    pixels[i] = 0xFFFFFFAA;
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

  // this needs to become a BitBlt style method
  TileBlock* logo1Tiles = loadTiles("assets/logo1.dat", 14, 6);
  
  // print from (7, 2)
  // width 14, height 6

  int col1Offset = 7;
  int row1Offset = 2;
  for(int row=0; row<6; row++){
    for(int col=0; col<14; col++){
      Uint32 tileIndex = logo1Tiles->tile(col, row);
      Uint32* tile = tiles[tileIndex & 0x1FF];
      Uint32 modifiers = tileIndex & 0xFE00;
      printTile(pixels, tile, (col1Offset + col)*8, (row1Offset + row)*8, modifiers);
    }
  }

  FILE* logo2 = fopen("assets/logo2.dat", "rb");
  Uint16 logo2Tiles[13*7];
  fread(logo2Tiles, 1, 13*7*2, logo2);
  fclose(logo2);

  // print from (13, 7)
  // width 13, height 7 (odd coincidence)

  int col2Offset = 13;
  int row2Offset = 7;
  for(int row=0; row<7; row++){
    for(int col=0; col<13; col++){
      Uint32 tileIndex = logo2Tiles[row*13 + col];
      Uint32* tile = tiles[tileIndex & 0x1FF];
      Uint32 modifiers = tileIndex & 0xFE00;
      printTile(pixels, tile, (col2Offset + col)*8, (row2Offset + row)*8, modifiers);
    }
  }

  FILE* logo3 = fopen("assets/logosnippet1.dat", "rb");
  Uint16 logo3Tiles[12*7];
  fread(logo3Tiles, 1, 12*7*2, logo3);
  fclose(logo3);

  // print from (20, 0)
  // width 12, height 7
  
  int col3Offset = 20;
  int row3Offset = 0;
  for(int row=0; row<7; row++){
    for(int col=0; col<12; col++){
      Uint32 tileIndex = logo3Tiles[row*12 + col];
      Uint32* tile = tiles[tileIndex & 0x1FF];
      Uint32 modifiers = tileIndex & 0xFE00;
      printTile(pixels, tile, (col3Offset + col)*8, (row3Offset + row)*8, modifiers);
    }
  }

  SDL_UpdateTexture(texture, NULL, screen->pixels, screen->pitch);
  SDL_RenderClear(renderer);
  SDL_RenderCopy(renderer, texture, NULL, NULL);
  SDL_RenderPresent(renderer);

  printf("done\n");

  return 0;
}

