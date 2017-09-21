; Source code created by SMS Examine V1.2a
; Size: 131072 bytes

.MEMORYMAP
SLOTSIZE $4000
SLOT 0 $0000
SLOT 1 $4000
SLOT 2 $8000
DEFAULTSLOT 2
.ENDME

.ROMBANKMAP
BANKSTOTAL 8
BANKSIZE $4000
BANKS 8
.ENDRO


.BANK 0 SLOT 0
.ORG $0000

_START:
	; disable interrupts
	di
	; interrupt mode 1
	; interrupt handler is at address 0038
	im   1
	; set stack at $DFF0
	ld   sp, $DFF0
	; goto _LABEL_85_2
	jr   _LABEL_85_2

_LABEL_8_10:
	; writes de to VDP register
	ld   a, e
	out  ($BF), a
	ld   a, d
	out  ($BF), a
	ret


; Data from F to 1A (12 bytes)
.db $FF, $87, $4F, $06, $00, $09, $7E, $23, $66, $6F, $C9, $FF

_LABEL_1B_39:
	; some big long jump based on a having high bit?
	bit  7, a
	ret  z

	and  $0F
_RST_20H:
	; when hl = 0x3B and a = 0x02
	add  a, a
	; a = 0x04
	ld   e, a
	; e = 0x04
	ld   d, $00
	; d = 0x00
	; de = 0x0004
	add  hl, de
	; hl = 0x3F
	ld   a, (hl)
	; a = 0xE5
	inc  hl
	ld   h, (hl)
	; h = 0x09
	ld   l, a
	; could be 0x076D
	; hl = 0x09E5
	; we get 76d lots but rarely 9e5
	; off in some memory bank somewhere, idk how to get to it :/
	jp   (hl)


; Data from 2A to 2F (6 bytes)
.db $FF, $FF, $FF, $FF, $FF, $FF

_RST_30H:
	; used to load palettes
	; also appears to be used in the sound loop
	rst  $8
	ld   c, $BE
_LABEL_33_112:
	outi
	jr   nz, _LABEL_33_112
	ret

; this gets called 140 times per second!!
; at $38 because we set interrupt mode to 1
; called by vsync or scanline
; in any case the video rendering drives this
_IRQ_HANDLER:
	jp   _LABEL_C0_13


; looks like some function pointers that we hit sometimes
; 76D, 76D, 9E5, 194F, 18CE, 1BC9, 6C0C (doesn't make sense)
; we do hit 76D from $53 - this is a call to executable code
; i reckon there must be a function there
; Data from 3B to 52 (24 bytes)
.db $6D, $07, $6D, $07, $E5, $09, $4F, $19, $CE, $18, $C9, $1B, $0C, $6C, $C9, $7D
.db $50, $16, $88, $0A, $88, $0A, $CD, $1F

_LABEL_53_93:
	xor  a
	ld   ($C01F), a
_LABEL_57_147:
	; start screen loop
	; waits for $C01F to get data
	; then goes and does it
	; and gets a function pointer from it
	; then jumps to it
	ld   hl, $C01F
	; a gets set sometimes to 0 and sometimes to 2
	; masked to 0x0F
	ld   a, (hl)
	and  $0F
	exx
	ld   hl, $003B
	rst  $20
	jp   _LABEL_57_147


; Data from 65 to 65 (1 bytes)
.db $FF

; non-maskable interrupt
; called when the pause button is pushed
; we can postpone this until we care about the menu
_NMI_HANDLER:
	push af
	ld   a, ($C31A)
	cp   $0F
	jp   z, _LABEL_82_149
	ld   a, ($C015)
	or   a
	jp   nz, _LABEL_82_149
	ld   a, ($C01F)
	cp   $8A
	jr   c, _LABEL_82_149
	ld   a, $01
	ld   ($C093), a
_LABEL_82_149:
	pop  af
	retn

; start of actual game
; this gets things prepped before we load the start screen
_LABEL_85_2:
	; set paging register
	; in practise this sets to 02
	; the game leaves first two registers both at 00 and third at 02
	; this might change later?
	ld   a, $82
	ld   ($FFFF), a
	call _LABEL_9E02_3 ; all 4 channels turned off
	; this is kind of cute
	; this is a memmove from c000 to c001
	; with c000 initialised to 0
	; so it's just zeroing out the memory from c000 to dfff
	; i.e. all ram
	ld   hl, $C000
	ld   de, $C001
	ld   bc, $1FFF
	ld   (hl), l
	ldir
	call _LABEL_341_4 ; some no-op sanity check? warm up the registers before using them?
	call _LABEL_350_7 ; some sort of console check, answer is in $C005 (is 0 for us)
_LABEL_9F_14:
	; we get sent here in a soft reset
	; from hard start/reset we do everything again for some reason
	ld   a, $82
	ld   ($FFFF), a
	ld   sp, $DFF0
	call _LABEL_9E02_3 ; all 4 channels turned off
	call _LABEL_26B_8 ; initialise graphics to black screen + sane values
	ld   hl, $0000
	ld   de, $4000
	ld   bc, $3800
	call _LABEL_184_9 ; this appears to zero out the first 3800 bytes of VRAM (all the sprite/tile patterns)
	ei ; enable interrupts
	call _LABEL_2F6_92 ; enable display
	jp   _LABEL_53_93

; interrupt handler
; "video handler" i guess
; called some number of hundreds of times per second
; this probably drives the main event loop - getting user input, time-tick based actions, etc
_LABEL_C0_13:
	; push all the registers
	push af
	push bc
	push de
	push hl
	; swap with shadow registers
	exx
	ex   af, af'
	push af
	push bc
	push de
	push hl
	push ix
	push iy
	; i think we're doing a semi-obligatory check of $BF
	in   a, ($BF) ; video status register, bit 7 is vsync, 6 is line interrupt, 5 is sprite collision
	in   a, ($DD) ; joypad port 2
	and  $10 ; mask everything except bit 4, reset button
	; store reset button flag in $C096
	ld   hl, $C096
	ld   c, (hl)
	ld   (hl), a
	xor  c
	and  c
	; jump if reset button has been pressed/released since last interrupt
	; looks like this is a soft reset
	jp   nz, _LABEL_9F_14
	; store current memory location in a
	ld   a, ($FFFF)
	; $C008 looks like a bitmap of things to do here
	; we zero it at the end here
	; save af (a and flags), so we can reload memory at the end
	push af
	ld   a, ($C008)
	; rotate right with carry on `a` register
	rrca
	push af
	; call conditional on carry flag - carry flag gets set if `a` from above has lsb set (1)
	; bit 0
	; sync sprite map from C700 to VRAM 3F00
	; $E7
	call c, _LABEL_1F7_15
	; compare $C200 with $C201
	call _LABEL_41B3_24
	pop  af
	rrca
	push af
	; bit 1
	call _LABEL_367_26 ; get joypad buttons pushed
	call _LABEL_107C_35 ; ? some magic far jump
	pop  af
	rrca
	push af
	; bit 2
	call _LABEL_264F_36 ; updates sprite colour
	pop  af
	rrca
	; bit 3
	; this is a conditional "go to $842 via $20"
	ld   a, ($C01F)
	ld   hl, $0127
	call c, _LABEL_1B_39 ; hits rst $20 but only if a has high bit set, otherwise short circuits
	ld   a, $82
	; this sets it to 02 not 82 ?!
	ld   ($FFFF), a
	call _LABEL_984F_43
	xor  a
	ld   ($C008), a
	pop  af
	ld   ($FFFF), a
	; pop all the registers and shadow registers
	pop  iy
	pop  ix
	pop  hl
	pop  de
	pop  bc
	pop  af
	exx
	ex   af, af'
	pop  hl
	pop  de
	pop  bc
	pop  af
	; enable interrupts (they were disabled because we were in the handler)
	ei
	ret

; method jumps
; 842 gets used by start screen
; Data from 127 to 13E (24 bytes)
.db $42, $08, $42, $08, $35, $0A, $01, $1A, $CD, $18, $EE, $1B, $AE, $6E, $29, $7F
.db $A6, $16, $B1, $0A, $B1, $0A, $E6, $1F

_LABEL_13F_38:
	; set palette value
	; 0x00-0x0f = tile
	; 0x10-0x1f = sprite
	push af
	rst  $8
	pop  af
	out  ($BE), a
	ret


; Data from 145 to 17B (55 bytes)
.db $CF, $79, $B7, $28, $01, $04, $78, $41, $0E, $BE, $ED, $A3, $C2, $4F, $01, $3D
.db $C2, $4F, $01, $C9, $CF, $3A, $0A, $C1, $0E, $BE, $ED, $A3, $F5, $F1, $ED, $79
.db $20, $F8, $C9, $CF, $79, $B7, $28, $01, $04, $78, $41, $0E, $BE, $ED, $A2, $C2
.db $72, $01, $3D, $C2, $72, $01, $C9

_LABEL_17C_101:
	; clear screen display (set 3800-3EFF to 00)
	ld   de, $7800
	ld   bc, $0700
	ld   l, $00
	; set VRAM pointer to 3800 (screen display)
_LABEL_184_9:
	; fill vram
	; de = 4000 + starting point (so 7800 -> vram 3800)
	; bc = size (0700 = 700 bytes)
	; l = value (00)
	rst  $8; writes de to $BF
	ld   a, c
	or   a
	ld   a, l
	jr   z, _LABEL_18B_11
	inc  b
_LABEL_18B_11:
	out  ($BE), a
	dec  c
	jr   nz, _LABEL_18B_11
	djnz _LABEL_18B_11
	ret

_LABEL_193_109:
	; print rectangle of tiles to screen
	; hl = memory of flattened blob
	; de = initial coordinate
	; b = height
	; c = width (in bytes, twice the number of tiles)
	; gets called twice
	; hl=$AD9E, de=$788E, bc=$061C
	; hl=$AE46, de=$79DA, bc=$071A
	; b = number of iterations (whole loop)
	; c = number of bytes to copy in each iteration
	; $061C = 06 * 1C = 0xA8 (14 tiles)
	; $071A = 07 * 1A = 0xB6 (13 tiles)
	; we appear to write chunks of 0x1C or 0x1A but then skip hl forward by 0x40 after that
	; 0x40 is the width of the screen (32 = 0x20, and 2 bytes per thing)
	; 788E = write to 0x388E in VRAM (weird... display mem starts at 0x3800 so we skip a bunch?!)
	; 79DA = write to 0x39DA in VRAM (weird... display mem starts at 0x3800 so we skip a bunch?!)
	; the idea here is to dump the "ALEX KIDD" logo on the screen
	; by passing de=$788E or $79DA we get to start at a certain x,y coordinate and print line at a time
	; then we just nudge de forward 0x40 at a time
	; in any case this would appear to be syncing (most of) the screen to VRAM
	; this is part of the start screen, it dumps a bunch of tiles in two specific chunks
	push bc
	rst  $8; write de to VDP register
	ld   b, c
	ld   c, $BE
_LABEL_198_110:
	outi
	nop
	jr   nz, _LABEL_198_110
	ex   de, hl
	ld   bc, $0040
	add  hl, bc
	ex   de, hl
	pop  bc
	djnz _LABEL_193_109
	ret


; Data from 1A7 to 1F6 (80 bytes)
.db $32, $0A, $C1, $C5, $CF, $41, $0E, $BE, $ED, $A3, $3A, $0A, $C1, $00, $ED, $79
.db $00, $C2, $AF, $01, $EB, $01, $40, $00, $09, $EB, $C1, $10, $E6, $C9, $21, $40
.db $00, $CF, $C5, $AF, $D3, $BE, $0D, $20, $FB, $19, $EB, $C1, $10, $F0, $C9, $32
.db $0B, $C1, $CF, $7E, $D9, $0E, $BE, $06, $04, $67, $3A, $0B, $C1, $1F, $54, $38
.db $02, $16, $00, $ED, $51, $10, $F6, $D9, $23, $0B, $78, $B1, $C2, $DA, $01, $C9

_LABEL_1F7_15:
	; called by video handler
	; 2x places kick this off (bit 0)
	; am expecting some sort of screen/state update here
	; $C01F could be the number of rows to update
	ld   a, ($C01F)
	and  $0F
	cp   $02
	jr   c, _LABEL_208_16
	ld   hl, $C10D
	inc  (hl)
	bit  0, (hl)
	jr   z, _LABEL_224_17
_LABEL_208_16:
	; sync sprites from C700 to VRAM
	; send 7F00 to VDP register
	; this is (0x7000 + 0x3F00) = write to 0x3F00 in VRAM
	; Screen display: 32x28 table of tile numbers/attributes
	; in other words, update on-screen tiles
	; then copy 0x40 bytes from $C700 to port 0xBE
	; this is the y position of each of 64 sprites
	ld   hl, $C700
	ld   de, $7F00
	ld   bc, $40BE
	rst  $8
_LABEL_212_18:
	outi
	jr   nz, _LABEL_212_18
	; copy sprite x coordinates and tiles
	; these are in (x, tile_id) pairs
	; memove(c780_local, 3f80_vram, 0x80)
	ld   hl, $C780
	ld   de, $7F80
	ld   b, $80
	rst  $8
_LABEL_21F_19:
	outi
	jr   nz, _LABEL_21F_19
	ret

_LABEL_224_17:
	ld   a, ($C009)
	cp   $13
	jr   c, _LABEL_208_16
	; copy 0x11=17 sprites to 3f80
	; memove(c780_local, 3f80_vram, 0x80)
	ld   hl, $C700
	ld   bc, $11BE
	ld   de, $7F00
	rst  $8
_LABEL_235_20:
	outi
	jr   nz, _LABEL_235_20
	ld   hl, ($C009)
	ld   a, l
	; accounting, subtract the 0x11 sprites from some counter
	dec  l
	sub  $11
	ld   b, a
_LABEL_241_21:
	; send another 0x11 but increment b this time?!
	outd
	jr   nz, _LABEL_241_21
	; then 0xD0 - 35 all up at this stage
	ld   a, $D0
	out  ($BE), a
	; then another 0x22=34 - 39 all up
	ld   hl, $C780
	ld   de, $7F80
	ld   b, $22
	rst  $8
_LABEL_252_22:
	outi
	jr   nz, _LABEL_252_22
	ld   hl, ($C009)
	sla  l
	set  7, l
	ld   a, l
	sub  $A2
	ld   b, a
_LABEL_261_23:
	; some padding for the rest of the sprite mem?
	dec  l
	dec  l
	outi
	outd
	jp   nz, _LABEL_261_23
	ret

_LABEL_26B_8:
	; initialises graphics
	; write a string of 0x16 (22 bytes) from $027D to port $BF
	; $26, $80, $A0, $81, $FF, $82, $FF, $83, $FF, $84, $FF, $85, $FF, $86, $00, $88, $00, $89, $00, $87, $10, $C0
	; sets VDP registers 0-9 as follows:
	; 0 = 26 (do not display leftmost column, shift all sprites left, stretch screen - 33 columns wide)
	; 1 = A0 (don't display, do start vsync interupts though?!)
	; 2 = FF (nametable at $3800, default)
	; 3 = FF (??)
	; 4 = FF (??)
	; 5 = FF (sprite table at $3900, default)
	; 6 = FF (sprites are the second lot of tiles - $2000, tile 256 - 511)
	; 7 = 00 (use colour 0 for border)
	; 8 = 00 (hscroll = 0)
	; 9 = 00 (vscroll = 0)
	; last set ($10, $C0) sets us up to write to palette ram
	ld   hl, $027D
	ld   bc, $16BF
	otir
	; colour 0 is 000 - guarantees black border
	xor  a
	out  ($BE), a
	; $C004 = ($27F) = $A0
	; we must track $C004 to figure whether display/vsync interrupts are enabled/disabled
	ld   a, ($027F)
	ld   ($C004), a
	ret


; Data from 27D to 292 (22 bytes)
.db $26, $80, $A0, $81, $FF, $82, $FF, $83, $FF, $84, $FF, $85, $FF, $86, $00, $88
.db $00, $89, $00, $87, $10, $C0

_LABEL_293_104:
	;4.times do
	ld   b, $04
_LABEL_295_108:
	push bc
	push de
	call _LABEL_2A0_105
	pop  de
	; so we do 0+4n
	; then 1+4n
	; etc etc
	; so this is 2 rows at a time (out of 8)
	inc  de
	pop  bc
	djnz _LABEL_295_108
	ret

_LABEL_2A0_105:
	; gets called 4 times
	ld   a, (hl)
	inc  hl
	or   a
	; 0 terminates
	ret  z

	ld   b, a
	ld   c, a
	res  7, b ; make sure it isn't a negative number
_LABEL_2A8_107:
	; de is either $4020 or $6400
	; these translate to write to $0020 or $2400
	; both of these are addresses of sprite/tile defs
	; each is 32 bytes (each nybble is a colour)
	; looks like we RLE the sprites, and stack them 4 bytes at a time
	; presumably this helps with compression?
	; important thing is that HL seems fixed - base sprites + some modifiers?
	ld   a, e
	out  ($BF), a
	ld   a, d
	out  ($BF), a
	ld   a, (hl)
	out  ($BE), a
	bit  7, c
	; repeat the same character if bit 7 is 0
	jp   z, _LABEL_2B7_106
	; if bit 7 is set, then we're dumping characters 1 by 1
	inc  hl
_LABEL_2B7_106:
	inc  de
	inc  de
	inc  de
	inc  de
	djnz _LABEL_2A8_107
	; djnz preserves flags so this is the zero flag from earlier
	; in other words, this makes sure we increment hl if we didn't just above
	jp   nz, _LABEL_2A0_105
	inc  hl
	jp   _LABEL_2A0_105


; Data from 2C4 to 2E5 (34 bytes)
.db $CF, $1E, $08, $56, $CB, $22, $1F, $1D, $20, $FA, $D3, $BE, $23, $0B, $78, $B1
.db $20, $EF, $C9, $21, $00, $C7, $11, $01, $C7, $01, $BF, $00, $36, $E0, $ED, $B0
.db $3E, $01

_LABEL_2E6_99:
	; this looks like it sets the sync bitmap and busy waits until the interrupt handler has been called
	; debugger spends a ton of time here, makes a lot of sense
	ld   hl, $C008
	ld   (hl), a
_LABEL_2EA_100:
	ld   a, (hl)
	or   a
	jr   nz, _LABEL_2EA_100
	ret

_LABEL_2EF_97:
	; disable display
	ld   a, ($C004)
	and  $BF
	jr   _LABEL_2FB_98

_LABEL_2F6_92:
	; enable display
	ld   a, ($C004) ; caches VDP register 1
	or   $40
_LABEL_2FB_98:
	; write a to vdp register 1
	ld   ($C004), a
	ld   e, a
	ld   d, $81
	rst  $8
	ret


; Data from 303 to 310 (14 bytes)
.db $AF, $32, $BE, $C0, $32, $B0, $C0, $5F, $16, $89, $CF, $15, $CF, $C9

_LABEL_311_96:
	; called from just before busy wait thing
	call _LABEL_2EF_97 ; disable display
	; zero a bunch of state (scroll counters?)
	ld   hl, $0000
	ld   ($C0AF), hl
	ld   ($C0BD), hl
	ld   ($C0AB), hl
	ld   ($C0B9), hl
	; fill from C700 to C7BF with E0
	ld   hl, $C700
	ld   de, $C701
	ld   bc, $00BF
	ld   (hl), $E0
	ldir
	; zero out scroll values (registers 8 and 9)
	ld   de, $8800
	rst  $8
	ld   d, $89
	rst  $8
	; enable interrupts
	ei
	; set bottom-most sync bit, busy wait
	; this gets it to sync $C700 to sprite info table (done in interrupt)
	ld   a, $01
	call _LABEL_2E6_99
	di
	; clear screen display
	jp   _LABEL_17C_101

_LABEL_341_4:
	; this doesn't seem to have any side effects?!
	ld   b, $0A
_LABEL_343_6:
	push bc
	ld   bc, $3333
_LABEL_347_5:
	dec  bc
	ld   a, b
	or   c
	jr   nz, _LABEL_347_5
	pop  bc
	djnz _LABEL_343_6
	ret

_LABEL_350_7:
	; some sort of checking on $DE/$DF, $C005 holds the result (ends up being 1 or 0, is 0 for us)
	ld   a, $92
	out  ($DF), a
	ld   hl, $C005
	ld   a, (hl)
	and  $02
	or   $01
	ld   (hl), a
	xor  a
	out  ($DE), a
	in   a, ($DE)
	or   a
	ret  z

	res  0, (hl)
	ret

_LABEL_367_26:
	; input detection, output in $C006
	ld   a, ($C005)
	bit  0, a
	jp   nz, _LABEL_374_27
	in   a, ($DC)
	jp   _LABEL_3C4_28

_LABEL_374_27:
	ld   a, $07
	out  ($DE), a
	in   a, ($DC)
	ld   c, a
	ld   a, $04
	out  ($DE), a
	in   a, ($DC)
	bit  5, a
	jp   nz, _LABEL_388_29
	res  1, c
_LABEL_388_29:
	ld   a, $05
	out  ($DE), a
	in   a, ($DC)
	bit  5, a
	jp   nz, _LABEL_395_30
	res  2, c
_LABEL_395_30:
	ld   a, $06
	out  ($DE), a
	in   a, ($DC)
	bit  5, a
	jp   nz, _LABEL_3A2_31
	res  3, c
_LABEL_3A2_31:
	bit  6, a
	jp   nz, _LABEL_3A9_32
	res  0, c
_LABEL_3A9_32:
	ld   a, $02
	out  ($DE), a
	in   a, ($DC)
	bit  4, a
	jp   nz, _LABEL_3B6_33
	res  4, c
_LABEL_3B6_33:
	ld   a, $03
	out  ($DE), a
	in   a, ($DC)
	bit  4, a
	jp   nz, _LABEL_3C3_34
	res  5, c
_LABEL_3C3_34:
	ld   a, c
_LABEL_3C4_28:
	ld   hl, $C006
	cpl
	ld   c, a
	xor  (hl)
	ld   (hl), c
	inc  hl
	and  c
	ld   (hl), a
	ret


; Data from 3CF to 43A (108 bytes)
.db $3A, $05, $C0, $E6, $20, $C0, $01, $30, $C0, $11, $83, $04, $26, $00, $19, $CD
.db $0B, $04, $D0, $21, $30, $C0, $0E, $99, $71, $23, $71, $23, $71, $C9, $3A, $05
.db $C0, $E6, $20, $C0, $01, $20, $C0, $11, $89, $04, $26, $00, $19, $CD, $0B, $04
.db $D0, $21, $00, $C0, $0E, $99, $71, $23, $71, $23, $71, $C9, $0A, $86, $27, $02
.db $03, $23, $0A, $8E, $27, $02, $03, $23, $0A, $8E, $27, $02, $C9, $0A, $96, $27
.db $02, $23, $0C, $0A, $9E, $27, $02, $23, $0C, $0A, $9E, $27, $02, $C9, $0A, $96
.db $27, $23, $0C, $0A, $9E, $27, $23, $0C, $0A, $9E, $27, $C9

_LABEL_43B_102:
	; these two hold counters?
	; subtract one from the other
	ld   de, $C020
	ld   hl, $C000
	ld   b, $03
	or   a ; not sure what this does, we override a and the flags should get reset
_LABEL_444_103:
	; this checks if ($C020) > ($C000)
	ld   a, (de)
	sbc  a, (hl)
	inc  hl
	inc  de
	djnz _LABEL_444_103
	ret  c

	; if so, copy ($C020) into ($C000)
	ex   de, hl
	dec  hl
	dec  de
	ld   bc, $0003
	lddr
	ret


; Data from 454 to 76C (793 bytes)
.db $0E, $03, $CD, $08, $00, $CB, $FB, $3E, $C0, $06, $02, $ED, $6F, $F5, $FE, $C0
.db $20, $08, $CB, $7B, $28, $06, $3E, $00, $18, $02, $CB, $BB, $D3, $BE, $F5, $F1
.db $3A, $0A, $C1, $D3, $BE, $F1, $10, $E3, $ED, $6F, $2B, $0D, $20, $D9, $C9, $01
.db $00, $00, $02, $00, $00, $20, $00, $00, $40, $00, $00, $60, $00, $00, $80, $00
.db $00, $00, $01, $00, $20, $01, $00, $00, $02, $00, $00, $10, $00, $23, $5E, $23
.db $56, $23, $46, $23, $7E, $C9, $46, $C5, $CD, $A1, $04, $23, $E5, $66, $6F, $CD
.db $59, $01, $E1, $C1, $10, $F1, $C9, $08, $3E, $82, $32, $FF, $FF, $08, $11, $00
.db $44, $01, $00, $02, $21, $05, $B3, $C3, $D6, $01, $DD, $6E, $1B, $DD, $7E, $1C
.db $E6, $01, $DD, $77, $1C, $67, $29, $7D, $E6, $7E, $4F, $29, $7C, $87, $5F, $16
.db $00, $21, $EE, $04, $19, $7E, $23, $66, $6F, $E9, $FE, $04, $35, $05, $71, $05
.db $A8, $05, $E4, $05, $1B, $06, $57, $06, $8E, $06, $21, $CA, $06, $06, $00, $09
.db $7E, $D9, $5F, $DD, $6E, $1D, $CD, $4C, $07, $DD, $7E, $1E, $84, $DD, $77, $0E
.db $DD, $7E, $19, $CE, $00, $DD, $77, $0A, $D9, $23, $6E, $DD, $5E, $1D, $CD, $4C
.db $07, $DD, $7E, $1F, $84, $DD, $77, $0C, $DD, $7E, $1A, $DE, $00, $DD, $77, $09
.db $C9, $21, $CC, $06, $79, $2F, $C6, $7F, $4F, $06, $00, $09, $7E, $D9, $5F, $DD
.db $6E, $1D, $CD, $4C, $07, $DD, $7E, $1F, $84, $DD, $77, $0C, $DD, $7E, $1A, $DE
.db $00, $DD, $77, $09, $D9, $23, $6E, $DD, $5E, $1D, $CD, $4C, $07, $DD, $7E, $1E
.db $84, $DD, $77, $0E, $DD, $7E, $19, $CE, $00, $DD, $77, $0A, $C9, $21, $CC, $06
.db $06, $00, $09, $7E, $D9, $5F, $DD, $6E, $1D, $CD, $4C, $07, $DD, $7E, $1F, $94
.db $DD, $77, $0C, $DD, $7E, $1A, $CE, $00, $DD, $77, $09, $D9, $23, $6E, $DD, $5E
.db $1D, $CD, $4C, $07, $DD, $7E, $1E, $84, $DD, $77, $0E, $DD, $7E, $19, $CE, $00
.db $DD, $77, $0A, $C9, $21, $CA, $06, $79, $2F, $C6, $7F, $4F, $06, $00, $09, $7E
.db $D9, $5F, $DD, $6E, $1D, $CD, $4C, $07, $DD, $7E, $1E, $84, $DD, $77, $0E, $DD
.db $7E, $19, $CE, $00, $DD, $77, $0A, $D9, $23, $6E, $DD, $5E, $1D, $CD, $4C, $07
.db $DD, $7E, $1F, $94, $DD, $77, $0C, $DD, $7E, $1A, $CE, $00, $DD, $77, $09, $C9
.db $21, $CA, $06, $06, $00, $09, $7E, $D9, $5F, $DD, $6E, $1D, $CD, $4C, $07, $DD
.db $7E, $1E, $94, $DD, $77, $0E, $DD, $7E, $19, $DE, $00, $DD, $77, $0A, $D9, $23
.db $6E, $DD, $5E, $1D, $CD, $4C, $07, $DD, $7E, $1F, $94, $DD, $77, $0C, $DD, $7E
.db $1A, $CE, $00, $DD, $77, $09, $C9, $21, $CC, $06, $79, $2F, $C6, $7F, $4F, $06
.db $00, $09, $7E, $D9, $5F, $DD, $6E, $1D, $CD, $4C, $07, $DD, $7E, $1F, $94, $DD
.db $77, $0C, $DD, $7E, $1A, $CE, $00, $DD, $77, $09, $D9, $23, $6E, $DD, $5E, $1D
.db $CD, $4C, $07, $DD, $7E, $1E, $94, $DD, $77, $0E, $DD, $7E, $19, $DE, $00, $DD
.db $77, $0A, $C9, $21, $CC, $06, $06, $00, $09, $7E, $D9, $5F, $DD, $6E, $1D, $CD
.db $4C, $07, $DD, $7E, $1F, $84, $DD, $77, $0C, $DD, $7E, $1A, $DE, $00, $DD, $77
.db $09, $D9, $23, $6E, $DD, $5E, $1D, $CD, $4C, $07, $DD, $7E, $1E, $94, $DD, $77
.db $0E, $DD, $7E, $19, $DE, $00, $DD, $77, $0A, $C9, $21, $CA, $06, $79, $2F, $C6
.db $7F, $4F, $06, $00, $09, $7E, $D9, $5F, $DD, $6E, $1D, $CD, $4C, $07, $DD, $7E
.db $1E, $94, $DD, $77, $0E, $DD, $7E, $19, $DE, $00, $DD, $77, $0A, $D9, $23, $6E
.db $DD, $5E, $1D, $CD, $4C, $07, $DD, $7E, $1F, $84, $DD, $77, $0C, $DD, $7E, $1A
.db $DE, $00, $DD, $77, $09, $C9, $00, $FF, $03, $FF, $06, $FF, $09, $FF, $0D, $FF
.db $10, $FF, $13, $FE, $16, $FE, $19, $FE, $1C, $FD, $1F, $FD, $22, $FD, $25, $FC
.db $29, $FC, $2C, $FB, $2F, $FB, $32, $FA, $35, $F9, $38, $F9, $3B, $F8, $3E, $F7
.db $41, $F7, $44, $F6, $47, $F5, $4A, $F4, $4D, $F3, $50, $F2, $53, $F1, $56, $F0
.db $59, $EF, $5C, $EE, $5F, $ED, $62, $EC, $64, $EA, $67, $E9, $6A, $E8, $6D, $E7
.db $70, $E5, $73, $E4, $75, $E2, $78, $E1, $7B, $DF, $7E, $DE, $80, $DC, $83, $DB
.db $86, $D9, $88, $D7, $8B, $D6, $8E, $D4, $90, $D2, $93, $D0, $95, $CF, $98, $CD
.db $9A, $CB, $9D, $C9, $9F, $C7, $A2, $C5, $A4, $C3, $A7, $C1, $A9, $BF, $AB, $BD
.db $AE, $BB, $B0, $B9, $B2, $B7, $B4, $B4, $65, $06, $08, $16, $00, $6A, $29, $30
.db $01, $19, $10, $FA, $C9, $06, $11, $AF, $C3, $68, $07, $8F, $38, $03, $BB, $38
.db $02, $93, $B7, $3F, $ED, $6A, $10, $F3, $C9

; This label is reached with a register jump
; seems to be the default event to go to
; ALEX KIDD start screen
_LABEL_76D_94:
	; this appears to just load the start screen and nothing else
	exx
	bit  7, (hl)
	; nothing to do so short circuit to busy wait
	jp   nz, _LABEL_7EC_95
	; set bit ($C01F) and don't come back in here until it gets re-set
	set  7, (hl)
	; this strikes me as "init everything for the start screen"
	; it loads all the sprites, puts the alex kidd logo on screen
	; then we're ready to do everything else
	xor  a
	ld   ($C10A), a
	; disable display and reset a bunch of stuff including scroll
	; populates base sprite/tile data (done in interrupt)
	; clears screen display
	call _LABEL_311_96
	ld   de, $6000
	ld   bc, $0020
	ld   l, $00
	; zeroes out first 0x20 bytes from vram 2000
	; (first 0x20 sprites are special maybe? all we use?)
	; address $784
	call _LABEL_184_9
	; load memory bank 2
	ld   a, $82
	ld   ($FFFF), a
	call _LABEL_9DF3_45 ; turns sound channels to 0 volume and fills C111 - C1F5 with 00
	call _LABEL_43B_102 ; copies from ($C020) to ($C000) if one is bigger - seems to track which demo is playing
	; zero out C020-DDFF
	ld   hl, $C020
	ld   de, $C021
	ld   bc, $1DDF
	ld   (hl), $00
	ldir
	ld   hl, $C226
	ld   (hl), $3C
	xor  a
	; zero out $C227 and $C228
	ld   ($C227), a
	ld   ($C228), a
	; load rom 4 in bank 2
	ld   a, $84
	ld   ($FFFF), a
	ld   hl, $B332
	ld   de, $4020
	; $7b6
	; no tiles loaded
	call _LABEL_293_104 ; unpack tileset from $B332 (0x13332 in file) and load into VRAM
	ld   hl, $AD9E ; 12D9E in ROM
	ld   de, $788E ; start at (7, 2) - (y_coord + x_coord+row_length)*bytes_in_word = (7 + 2*32)*2 = 142 = 8E
	ld   bc, $061C ; height 6, width 14
	; $7c2
	; loading screen tiles all loaded
	call _LABEL_193_109 ; sync screen display from memory
	ld   hl, $AE46 ; 12E46 in ROM
	ld   de, $79DA ; start at (13, 7) - (y_coord + x_coord+row_length)*bytes_in_word = (13 + 7*32)*2 = 474 = 1DA
	ld   bc, $071A ; height 7, width 13
	; $7ce
	; word ALEX is loaded in tilemap
	call _LABEL_193_109 ; sync screen display from memory
	; load palette
	ld   hl, $08C6 ; palette location
	ld   de, $C000 ; palette entry 0
	ld   b, $20
	; $7d9
	; whole ALEX KIDD in miracle world logo is loaded
	rst  $30
	; 7da
	; palette now updated
	call _LABEL_8F6_113 ; <- look at how this loads the sprites/tiles - this includes alex, janken, and backgrounds
	; other sprites loaded (not just logo but the stuff that pops up during loading screen)
	call _LABEL_2F6_92 ; enable display
	; no change observed to maps
	ei
	ld   hl, $01D0
	ld   ($C103), hl
	ld   a, $81
	ld   ($C110), a
_LABEL_7EC_95:
	;set vsync bits 3 and 0 and busy wait
	ld   a, $09
	; this plays out the first chunk of music - we should see where it goes
	; a = 0x01 + 0x08
	; the 0x08 means we get sent to $842 at the end of the interrupt loop
	call _LABEL_2E6_99 ; int whatever... with a=09
	; we get to here after the first second of music and first sprite (underwater top right) displayed
	call _LABEL_2694_121 ; didn't look too closely, looks to be a bunch of init stuff
	ld   a, ($C006) ; a = bitmask of joypad buttons
	ld   b, a
	and  $30
	jr   nz, _LABEL_80C_146
	ld   hl, ($C103)
	dec  hl
	ld   ($C103), hl
	ld   a, h
	or   l
	ret  nz

	ld   a, $02
	ld   ($C01F), a
	ret

_LABEL_80C_146:
	ld   a, $26
	ld   ($C05F), a
	ld   hl, $0824
	ld   de, $C01F
	ld   bc, $0019
	ldir
	xor  a
	ld   ($C10A), a
	ld   ($C005), a
	ret


; Data from 824 to 841 (30 bytes)
.db $03, $00, $00, $00, $01, $01, $03, $00, $00, $00, $00, $00, $00, $00, $00, $00
.db $00, $00, $00, $00, $00, $00, $03, $00, $00, $00, $00, $00, $00, $00

; This label is reached with a register jump
; used by the start screen
; gets called by $20
; then jumps back there?!
_LABEL_842_40:
	ld   hl, $C226
	dec  (hl)
	ret  nz

	ld   (hl), $20
	inc  hl
	ld   a, (hl)
	cp   $06
	jr   c, _LABEL_866_41 ; jump if ($C227) is less than 6
	; if we haven't jumped then $C227 is 6 or more
	; this might be where we pick a demo and start that?
	dec  hl
	ld   (hl), $03
	inc  hl
	inc  hl
	inc  (hl)
	ld   a, (hl)
	and  $03
	ld   hl, $08F2
	ld   e, a
	ld   d, $00
	add  hl, de
	ld   a, (hl)
	ld   de, $C002
	; set palette 02 to colour in a
	jp   _LABEL_13F_38

_LABEL_866_41:
	inc  (hl)
	ld   hl, $FFFF
	ld   (hl), $84
	ld   hl, $08E6
	jp   _RST_20H

; 872-8F5 disassembled
ld     hl,$aefc ; 0x12EFC = 77564 in ROM
ld     de,$7828 ; start at (20, 0) - (y_coord + x_coord+row_length)*bytes_in_word = (20 + 0*32)*2 = 40 = 0x28
ld     bc,$0718 ; height 7, width 12, 7*12*2 = 168 bytes
call   $0193
jp     $09c2
ld     hl,$b0a4 ; 0x130A4 = 77988 in ROM
ld     de,$7b98 ; start at (12, 14) - (y_coord + x_coord+row_length)*bytes_in_word = (12 + 14*32)*2 = 920 = 0x398
ld     bc,$061c ; height 6, width 14, 6*14*2 = 168 bytes
call   $0193
jp     $097e
ld     hl,$afa4 ; 0x12FA4 = 77732 in ROM
ld     de,$7800 ; start at (0, 0)
ld     bc,$080e ; height 8, width 7, 8*7*2 = 112 bytes
jp     $0193
ld     hl,$b014 ; 0x13014 = 77844 in ROM
ld     de,$79f4 ; start at (26, 7) - (y_coord + x_coord+row_length)*bytes_in_word = (26 + 7*32)*2 = 500 = 0x1F4
ld     bc,$0c0c ; height 12, width 6, 12*6*2 = 144 bytes
call   $0193
jp     $0967
ld     hl,$b1b2 ; 0x131B2 = 78258 in ROM
ld     de,$7a00 ; start at (0, 8) - (y_coord + x_coord+row_length)*bytes_in_word = (0 + 8*32)*2 = 512 = 0x200
ld     bc,$1018 ; height 16, width 12, 16*12*2 = 384 bytes
call   $0193
jp     $0995
ld     hl,$b14c ; 0x1314C = 78156 in ROM
ld     de,$7d1a ; start at (13, 20) - (y_coord + x_coord+row_length)*bytes_in_word = (13 + 20*32)*2 = 1306 = 0x51A
ld     bc,$0322 ; height 3, width 17, 3*17*2 = 102 bytes
jp     $0193
; $8C6-$8F5 appears to be data

; Data from 872 to 8F5 (132 bytes)
.db $21, $FC, $AE, $11, $28, $78, $01, $18, $07, $CD, $93, $01, $C3, $C2, $09, $21
.db $A4, $B0, $11, $98, $7B, $01, $1C, $06, $CD, $93, $01, $C3, $7E, $09, $21, $A4
.db $AF, $11, $00, $78, $01, $0E, $08, $C3, $93, $01, $21, $14, $B0, $11, $F4, $79
.db $01, $0C, $0C, $CD, $93, $01, $C3, $67, $09, $21, $B2, $B1, $11, $00, $7A, $01
.db $18, $10, $CD, $93, $01, $C3, $95, $09, $21, $4C, $B1, $11, $1A, $7D, $01, $22
.db $03, $C3, $93, $01, $2F, $00, $03, $04, $0C, $08, $05, $0B, $30, $38, $3C, $3F
.db $02, $06, $2F, $00, $2F, $3F, $05, $0B, $03, $02, $00, $30, $3C, $0C, $0F, $08
.db $3A, $36, $03, $0A, $72, $08, $81, $08, $90, $08, $9C, $08, $AB, $08, $BA, $08
.db $03, $0F, $08, $0F

_LABEL_8F6_113:
	ld   a, $1E
	ld   ($C0F8), a
	ld   hl, $C300
	ld   ($C0F9), hl
	call _LABEL_9D9_114
	ld   a, $1D
	call _LABEL_41C0_117
	ld   bc, $0036
	call _LABEL_41C8_118
	ld   bc, $002C
	call _LABEL_41C8_118
	ld   bc, $0014
	call _LABEL_41C8_118
	ld   hl, $A357
	ld   de, $6400
	call _LABEL_293_104
	ld   a, $82
	ld   ($FFFF), a
	ld   hl, $8F7C
	ld   de, $C800
	xor  a
	call _LABEL_951_119
	ld   hl, $9153
	ld   de, $C828
	ld   a, $0B
	call _LABEL_951_119
	ld   hl, $8F16
	ld   de, $C850
	ld   a, $13
	call _LABEL_951_119
	ld   hl, $8E02
	ld   de, $C878
	ld   a, $19
_LABEL_951_119:
	push de
	ld   bc, $0024
	ldir
	pop  hl
	ld   e, (hl)
	inc  hl
	ld   b, e
	ld   d, $00
	add  hl, de
	ld   c, a
_LABEL_95F_120:
	inc  hl
	inc  hl
	ld   a, (hl)
	add  a, c
	ld   (hl), a
	djnz _LABEL_95F_120
	ret

; 967-9D8 disassembled
; my guess for these is putting sprites over top
; deal with this later

ld     ix,$c300
ld     (ix+$00),$18
ld     hl,$c800
ld     ($c307),hl
ld     (ix+$0c),$dc
ld     (ix+$0e),$46
ret
ld     ix,$c320
ld     (ix+$00),$18
ld     hl,$c828
ld     ($c327),hl
ld     (ix+$0c),$70
ld     (ix+$0e),$7c
ret
ld     ix,$c340
ld     (ix+$00),$18
ld     hl,$c850
ld     ($c347),hl
ld     (ix+$0c),$18
ld     (ix+$0e),$4f
ld     ix,$c3c0
ld     (ix+$00),$18
ld     hl,$961a
ld     ($c3c7),hl
ld     (ix+$0c),$30
ld     (ix+$0e),$77
ret
ld     ix,$c360
ld     (ix+$00),$18
ld     hl,$c878
ld     ($c367),hl
ld     (ix+$0c),$c9
ld     (ix+$0e),$0c
ret

; Data from 967 to 9D8 (114 bytes)
.db $DD, $21, $00, $C3, $DD, $36, $00, $18, $21, $00, $C8, $22, $07, $C3, $DD, $36
.db $0C, $DC, $DD, $36, $0E, $46, $C9, $DD, $21, $20, $C3, $DD, $36, $00, $18, $21
.db $28, $C8, $22, $27, $C3, $DD, $36, $0C, $70, $DD, $36, $0E, $7C, $C9, $DD, $21
.db $40, $C3, $DD, $36, $00, $18, $21, $50, $C8, $22, $47, $C3, $DD, $36, $0C, $18
.db $DD, $36, $0E, $4F, $DD, $21, $C0, $C3, $DD, $36, $00, $18, $21, $1A, $96, $22
.db $C7, $C3, $DD, $36, $0C, $30, $DD, $36, $0E, $77, $C9, $DD, $21, $60, $C3, $DD
.db $36, $00, $18, $21, $78, $C8, $22, $67, $C3, $DD, $36, $0C, $C9, $DD, $36, $0E
.db $0C, $C9

_LABEL_9D9_114:
	ld   b, $1E
	ld   hl, $C300
_LABEL_9DE_116:
	call _LABEL_278D_115
	inc  hl
	djnz _LABEL_9DE_116
	ret


; Data from 9E5 to 107B (1687 bytes)
.incbin "..\..\Projects\Alex Kidd\Alex Kidd in Miracle World.sms.dat.2"

; inserting this stuff

        ORG     09E5h

        LD      HL,0C01Fh
        BIT     7,(HL)
        JP      NZ,L0A8E
        SET     7,(HL)
        LD      A,(0C016h)
        INC     A
        CP      05h
        JP      C,L09FA
        LD      A,01h
L09FA:  LD      (0C016h),A
        LD      C,A
        LD      B,00h
        LD      HL,0A7Bh
        ADD     HL,BC
        LD      A,(HL)
        LD      (0C023h),A
        CP      02h
        JP      NZ,L0A12
        LD      A,07h
        LD      (0C054h),A
L0A12:  LD      A,85h
        LD      (0FFFFh),A
        LD      A,(0C016h)
        LD      HL,0A7Eh
        RST     0x10

L0A1E:  DEC     HL
        LD      (0C105h),HL
        LD      HL,0C005h
        LD      A,(HL)
        AND     03h
        OR      20h             ; ' '
        LD      (HL),A
        LD      HL,01FFh
        LD      (0C107h),HL
        JP      L0ABD

L0A34:  RET

L0A35:  LD      A,85h
        LD      (0FFFFh),A
        LD      A,(0C006h)
        AND     30h             ; '0'
        JR      Z,L0A4C
        LD      A,01h
        LD      (0C01Fh),A
        LD      HL,0C005h
        RES     5,(HL)
        RET

L0A4C:  LD      BC,(0C107h)
        DJNZ    L0A71
        LD      HL,(0C105h)
        INC     HL
        LD      A,(HL)
        OR      A
        JR      NZ,L0A65
        LD      A,00h
        LD      (0C01Fh),A
        LD      HL,0C005h
        RES     5,(HL)
        RET

L0A65:  LD      B,A
        INC     HL
        LD      A,C
        LD      C,(HL)
        LD      (0C105h),HL
        XOR     C
        AND     C
        LD      (0C007h),A
L0A71:  LD      (0C107h),BC
        LD      A,C
        LD      (0C006h),A
        JP      L0AB1

L0A7C:  LD      (BC),A
        INC     BC
        INC     B
        DEC     B
        DEC     (HL)
        ADC     A,L
        LD      E,E
        ADC     A,L
        DEC     SP
        ADC     A,(HL)
        LD      L,E
        ADC     A,A
        EXX
        BIT     7,(HL)
        JP      Z,L0ABD
L0A8E:  CALL    645Eh
        CALL    6F44h
        CALL    2694h
        CALL    67C4h
        CALL    6B49h
        LD      A,09h
        CALL    02E6h
        LD      A,(0C093h)
        OR      A
        RET     Z
        XOR     A
        LD      (0C093h),A
        LD      A,0Bh
        LD      (0C01Fh),A
        RET

L0AB1:  CALL    264Fh
        CALL    4229h
        CALL    158Fh
        JP      6920h

L0ABD:  CALL    0311h
        CALL    09D9h
        LD      A,82h
        LD      (0FFFFh),A
        CALL    9DF3h
        LD      HL,0C0A0h
        LD      DE,0C0A1h
        LD      BC,002Ah
        LD      (HL),00h
        LDIR
        LD      A,1Eh
        LD      (0C0F8h),A
        LD      HL,0C300h
        LD      (0C0F9h),HL
        CALL    10FFh ; this calls the bit that ultimately loads the palette
        CALL    1134h
        LD      HL,0B0A9h
        LD      DE,61A0h
        LD      BC,0060h
        CALL    0145h
        LD      HL,9349h
        LD      DE,66C0h
        LD      BC,0100h
        CALL    0145h
        LD      A,(0C023h)
        LD      HL,0E1Eh
        LD      C,A
        LD      B,00h
        ADD     HL,BC
        LD      A,(HL)
        OR      A
        JP      Z,L0B3A
        CP      01h
        JP      NZ,L0B1D
        LD      A,01h
        LD      (0C051h),A
        JP      L0B22

L0B1D:  LD      A,09h
        LD      (0C054h),A
L0B22:  LD      HL,9B29h
        LD      DE,6200h
        LD      BC,0020h
        CALL    0145h
        LD      HL,9429h
        LD      DE,6220h
        LD      BC,01C0h
        CALL    0145h
L0B3A:  LD      A,85h
        LD      (0FFFFh),A
        LD      DE,5600h
        LD      HL,0B2B1h
        CALL    0293h
        LD      A,83h
        LD      (0FFFFh),A
        LD      HL,8000h
        LD      DE,4020h
        LD      BC,0480h
        CALL    0145h
        CALL    L0E6C
        CALL    65B1h
        LD      A,(0C023h)
        LD      HL,0D6Dh
        LD      C,A
        ADD     A,A
        ADD     A,C
        LD      C,A
        LD      B,00h
        ADD     HL,BC
        LD      A,(HL)
        LD      (0C069h),A
        INC     HL
        LD      A,(HL)
        INC     HL
        LD      H,(HL)
        LD      L,A
        LD      (0C0FDh),HL
        LD      A,82h
        LD      (0FFFFh),A
        LD      A,(0C023h)
        LD      HL,0B503h
        CALL    0010h
        LD      (0C061h),HL
        XOR     A
        LD      (0C08Eh),A
        LD      (0C215h),A
        LD      HL,0D900h
        LD      (HL),00h
        LD      DE,0D901h
        LD      BC,05FFh
        LDIR
        LD      A,(0C023h)
        CP      0Bh
        JP      C,L0C43
        JP      NZ,L0BF3
        LD      A,01h
        LD      (0C08Eh),A
        LD      HL,97DDh
        LD      B,05h
        LD      DE,0D900h
L0BB5:  LD      (0C078h),DE
        LD      (0C07Ah),DE
L0BBD:  PUSH    BC
        LD      A,(HL)
        OR      A
        INC     HL
        JP      Z,L0BCD
        INC     A
        DEC     HL
L0BC6:  LDI
        INC     DE
        DEC     A
        JP      NZ,L0BC6
L0BCD:  EX      DE,HL
        LD      HL,(0C07Ah)
        LD      BC,0020h
        ADD     HL,BC
        LD      (0C07Ah),HL
        EX      DE,HL
        POP     BC
        DJNZ    L0BBD
        LD      A,(HL)
        CP      0FFh
        JP      Z,L0C43
        EX      DE,HL
        LD      HL,(0C078h)
        LD      BC,0100h
        ADD     HL,BC
        LD      (0C078h),HL
        EX      DE,HL
        LD      B,05h
        JP      L0BB5

L0BF3:  CP      10h
        JP      NZ,L0C43
        LD      A,01h
        LD      (0C08Eh),A
        LD      HL,9800h
        LD      B,07h
        LD      DE,0D900h
L0C05:  LD      (0C078h),DE
        LD      (0C07Ah),DE
L0C0D:  PUSH    BC
        LD      A,(HL)
        OR      A
        INC     HL
        JP      Z,L0C1D
        INC     A
        DEC     HL
L0C16:  LDI
        INC     DE
        DEC     A
        JP      NZ,L0C16
L0C1D:  EX      DE,HL
        LD      HL,(0C07Ah)
        LD      BC,0020h
        ADD     HL,BC
        LD      (0C07Ah),HL
        EX      DE,HL
        POP     BC
        DJNZ    L0C0D
        LD      A,(HL)
        CP      0FFh
        JP      Z,L0C43
        EX      DE,HL
        LD      HL,(0C078h)
        LD      BC,0100h
        ADD     HL,BC
        LD      (0C078h),HL
        EX      DE,HL
        LD      B,07h
        JP      L0C05

L0C43:  LD      IX,0C300h
        LD      (IX+00h),01h
        LD      A,(0C023h)
        ADD     A,A
        LD      C,A
        LD      B,00h
        LD      HL,0DA1h
        ADD     HL,BC
        LD      A,(HL)
        LD      (IX+0Ch),A
        INC     HL
        LD      A,(HL)
        LD      (IX+0Eh),A
        CALL    29C2h
        CALL    2694h
        LD      A,(0C023h)
        LD      HL,0D2Ah
        CALL    0010h
        LD      (0C00Eh),HL
        LD      HL,156Bh
        LD      A,(0C023h)
        ADD     A,A
        LD      E,A
        LD      D,00h
        ADD     HL,DE
        LD      A,(HL)
        INC     HL
        LD      H,(HL)
        LD      L,A
        LD      (0C223h),HL
        LD      A,01h
        LD      (0C220h),A
        LD      A,(0C023h)
        LD      HL,0D08h
        CALL    0010h
        LD      (0C085h),HL
        LD      A,(0C023h)
        LD      HL,0D4Ch
        CALL    0010h
        LD      (0C089h),HL
        LD      A,(0C023h)
        LD      C,A
        LD      B,00h
        LD      HL,0E2Fh
        ADD     HL,BC
        LD      A,(HL)
        LD      (0C07Ch),A
        LD      A,87h
        LD      (0FFFFh),A
        LD      HL,0AFC9h
        LD      DE,6400h
L0CB9:  LD      BC,00E0h
L0CBC:  CALL    0145h
        LD      HL,0AFC9h
        LD      BC,00E0h
L0CC5:  CALL    02C5h
        LD      A,85h
        LD      (0FFFFh),A
        LD      HL,0B191h
        LD      DE,65C0h
L0CD3:  LD      BC,0080h
L0CD6:  CALL    0145h
        LD      HL,0B0B1h
        LD      DE,6640h
        LD      BC,0060h
        CALL    0145h
        LD      HL,0B0F1h
        LD      BC,0020h
        CALL    02C5h
        LD      A,82h
        LD      (0FFFFh),A
        LD      A,(0C023h)
        LD      C,A
        LD      B,00h
        LD      HL,0DC4h
        ADD     HL,BC
        LD      A,(HL)
        LD      (0C110h),A
        LD      HL,0C01Fh
        SET     7,(HL)
        EI
        JP      02F6h

; looks like data from here
;00000CF0  32 FF FF 3A 23 C0 4F 06 00 21 C4 0D 09 7E 32 10 2..:#.O..!...~2.
;00000D00  C1 21 1F C0 CB FE FB C3 F6 02 62 64 62 64 7B 65 .!........bdbd{e
;00000D10  62 64 39 65 62 64 62 64 62 64 39 65 62 64 7D 64 bd9ebdbdbd9ebd}d
;00000D20  62 64 62 64 62 64 62 64 7D 64 62 64 89 10 DE 10 bdbdbdbd}dbd....
;00000D30  89 10 E1 10 89 10 E4 10 E7 10 EA 10 89 10 ED 10 ................
;00000D40  F0 10 F3 10 F6 10 F9 10 FC 10 89 10 89 10 48 6F ..............Ho
L0D0A:  LD      H,D
        LD      H,H
        LD      H,D
L0D0D:  LD      H,H
        LD      A,E
        LD      H,L
        LD      H,D
        LD      H,H
        ADD     HL,SP
        LD      H,L
L0D14:  LD      H,D
        LD      H,H
        LD      H,D
        LD      H,H
        LD      H,D
        LD      H,H
        ADD     HL,SP
L0D1B:  LD      H,L
        LD      H,D
        LD      H,H
        LD      A,L
        LD      H,H
L0D20:  LD      H,D
        LD      H,H
        LD      H,D
        LD      H,H
        LD      H,D
L0D25:  LD      H,H
        LD      H,D
        LD      H,H
        LD      A,L
        LD      H,H
        LD      H,D
        LD      H,H
L0D2C:  ADC     A,C
        DJNZ    L0D0D
L0D2F:  DJNZ    L0CB9+1         ; reference not aligned to instruction
L0D31:  DJNZ    L0D14
        DJNZ    L0CBC+2         ; reference not aligned to instruction
L0D35:  DJNZ    L0D1B
L0D37:  DJNZ    L0D20
L0D39:  DJNZ    L0D25
L0D3B:  DJNZ    L0CC5+1         ; reference not aligned to instruction
L0D3D:  DJNZ    L0D2C
L0D3F:  DJNZ    L0D31
L0D41:  DJNZ    L0D35+1         ; reference not aligned to instruction
L0D43:  DJNZ    L0D3B
L0D45:  DJNZ    L0D3F+1         ; reference not aligned to instruction
L0D47:  DJNZ    L0D45
L0D49:  DJNZ    L0CD3+1         ; reference not aligned to instruction
L0D4B:  DJNZ    L0CD6
L0D4D:  DJNZ    L0D97
        LD      L,A
        LD      C,B
        LD      L,A
        LD      C,B
        LD      L,A
        LD      C,B
        LD      L,A
        LD      C,B
        LD      L,A
        LD      C,B
        LD      L,A
L0D5A:  LD      C,B
        LD      L,A
        LD      C,B
        LD      L,A
        LD      C,B
        LD      L,A
        LD      C,B
        LD      L,A
        ADD     A,H
        LD      (HL),B
        LD      C,B
        LD      L,A
        LD      C,B
        LD      L,A
        LD      C,B
L0D69:  LD      L,A
        LD      C,B
        LD      L,A
        ADD     A,H
        LD      (HL),B
        LD      C,B
        LD      L,A
        NOP
        NOP
        NOP
        LD      H,B
        LD      D,H
        CALL    Z,5C72h
        CALL    Z,0000h
        NOP
        LD      B,D
        LD      B,B
        RET

L0D7F:  SUB     B
        JR      NZ,L0D4D+1      ; reference not aligned to instruction
        NOP
        NOP
        NOP
        JR      NC,L0D8F
        CALL    Z,0000h
        NOP
        LD      (HL),B
        JR      L0D5A

L0D8E:  NOP
L0D8F:  NOP
        NOP
        LD      D,B
        RET     NC
        RET

L0D94:  NOP
        NOP
        NOP
L0D97:  NOP
        NOP
        NOP
        LD      D,B
        DJNZ    L0D69
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        JR      NZ,L0DFD
        JR      NZ,L0D2F
        LD      B,B
        JR      NZ,L0DC5
        SUB     B
        JR      NZ,L0E1D
        JR      NZ,L0D37
        JR      NZ,L0D39
        JR      NZ,L0D3B
        JR      NZ,L0D3D
        JR      NZ,L0D3F
        JR      NZ,L0D41
        JR      NZ,L0D43
        RET     PE
        LD      (HL),B
        JR      NZ,L0D47
        JR      NZ,L0D49
        JR      NZ,L0D4B
        DJNZ    L0D4D
L0DC5:  ADD     A,D
        ADD     A,D
        ADD     A,E
        ADD     A,D
        ADC     A,B
        ADD     A,D
        ADD     A,D
        ADD     A,D
        ADD     A,E
        ADD     A,D
        ADD     A,H
        ADD     A,D
        ADC     A,B
        ADD     A,D
        ADD     A,D
        ADD     A,H
        ADD     A,D
        ADD     A,D
        LD      C,L
        LD      C,(HL)
        LD      C,A
        LD      C,L
        LD      C,(HL)
        LD      C,A
        LD      C,L
        LD      C,(HL)
        LD      C,A
        LD      C,L
        LD      C,(HL)
        LD      C,A
        LD      C,L
        LD      C,(HL)
        LD      C,A
        LD      C,L
        LD      C,(HL)
        LD      C,A
        LD      C,L
        LD      C,(HL)
        LD      C,A
        LD      C,L
        LD      C,(HL)
        LD      C,A
        LD      C,L
        LD      C,(HL)
        LD      C,A
        LD      C,L
        LD      C,(HL)
        LD      C,A
        LD      C,L
        LD      C,(HL)
        LD      C,A
        LD      C,L
        LD      C,(HL)
        LD      C,A
        LD      C,L
        LD      C,(HL)
L0DFD:  LD      C,A
        LD      C,L
        LD      C,(HL)
        LD      C,A
        LD      C,L
        LD      C,(HL)
        LD      C,A
        LD      C,L
        LD      C,(HL)
        LD      C,A
        LD      C,L
        LD      C,(HL)
        LD      C,A
        LD      C,L
        LD      C,(HL)
        LD      C,A
        LD      C,L
        LD      C,(HL)
        LD      C,A
        LD      C,L
        LD      C,(HL)
        LD      C,A
        LD      C,L
        LD      C,(HL)
        LD      C,A
        LD      C,L
        LD      C,(HL)
        LD      C,A
        LD      C,L
        LD      C,(HL)
        LD      C,A
        LD      C,L
L0E1D:  LD      C,(HL)
        LD      C,A
        NOP
        NOP
        NOP
        NOP
        ADD     HL,BC
        NOP
        NOP
        NOP
        LD      BC,0000h
        NOP
        ADD     HL,BC
        NOP
        NOP
        NOP
        NOP
        LD      BC,0302h
        INC     B
        DEC     B
        LD      B,07h
        EX      AF,AF'
        LD      (BC),A
        LD      A,(BC)
        DEC     BC
        INC     C
        DEC     C
        LD      C,0Fh
        DJNZ    L0E52
        PUSH    DE
        CALL    L0E4B
        INC     HL
        POP     DE
        INC     DE
        JP      L0E4B

        ; --- START PROC L0E4B ---
L0E4B:  LD      A,(HL)
        OR      A
        RET     Z
        BIT     7,A
        JR      NZ,L0E5E
L0E52:  LD      B,A
        INC     HL
        LD      A,(HL)
L0E55:  LD      (DE),A
        INC     DE
        INC     DE
        DJNZ    L0E55
        INC     HL
        JP      L0E4B

L0E5E:  AND     7Fh             ; ''
        LD      B,A
L0E61:  INC     HL
        LD      A,(HL)
        LD      (DE),A
        INC     DE
        INC     DE
        DJNZ    L0E61
        INC     HL
        JP      L0E4B

        ; --- START PROC L0E6C ---
L0E6C:  LD      HL,84A2h
        LD      DE,44A0h
        CALL    0293h
        LD      A,(0C023h)
        LD      HL,0E7Bh
        RST     0x20

L0E7C:  RET

L0E7D:  SBC     A,A
        LD      C,0F9h
        RRCA
        LD      HL,540Fh
        RRCA
        SBC     A,C
        RRCA
        LD      L,H
        RRCA
        XOR     (HL)
        RRCA
        RET

L0E8C:  LD      C,0C6h
        RRCA
        NOP
        RRCA
        LD      D,H
        RRCA
        LD      L,H
        RRCA
        LD      SP,HL
        RRCA
        LD      E,B
        DJNZ    L0E9A
L0E9A:  RRCA
        RST     0x18

L0E9C:  LD      C,22h           ; '"'
L0E9E:  DJNZ    L0EB1
        AND     B
        LD      B,(HL)
        LD      BC,0080h
        LD      L,00h
        CALL    0184h
        LD      A,(0C023h)
        LD      HL,847Eh
        RST     0x10

L0EB1:  LD      DE,4720h
        CALL    0293h
        LD      HL,0B7F6h
        LD      DE,4E60h
        LD      B,0A0h
        RST     0x30

L0EC0:  LD      HL,8583h
        LD      DE,4F00h
        JP      0293h

L0EC9:  LD      HL,89E1h
        LD      DE,4EC0h
        CALL    0293h
        LD      A,(0C023h)
        LD      HL,847Eh
        RST     0x10

L0ED9:  LD      DE,46A0h
        JP      0293h

L0EDF:  LD      DE,46A0h
        LD      BC,0080h
        LD      L,00h
        CALL    0184h
        LD      A,(0C023h)
        LD      HL,847Eh
        RST     0x10

L0EF1:  LD      DE,4720h
        CALL    0293h
        LD      HL,8583h
        LD      DE,4F00h
        JP      0293h

L0F00:  LD      DE,46A0h
        LD      BC,0080h
        LD      L,00h
        CALL    0184h
        LD      A,(0C023h)
        LD      HL,847Eh
        RST     0x10

L0F12:  LD      DE,4720h
        CALL    0293h
        LD      HL,89E1h
        LD      DE,4EC0h
        JP      0293h

L0F21:  LD      DE,46A0h
        LD      BC,0200h
        LD      L,00h
        CALL    0184h
        LD      A,(0C023h)
        LD      HL,847Eh
        RST     0x10

L0F33:  LD      DE,48A0h
        CALL    0293h
        LD      HL,0B896h
        LD      DE,4D00h
        CALL    0293h
        LD      HL,0B7F6h
        LD      DE,4E60h
        LD      B,0A0h
        RST     0x30

L0F4B:  LD      HL,8583h
        LD      DE,4F00h
        JP      0293h

L0F54:  LD      DE,46A0h
        LD      BC,0080h
        LD      L,00h
        CALL    0184h
        LD      A,(0C023h)
        LD      HL,847Eh
        RST     0x10

L0F66:  LD      DE,4720h
        JP      0293h

L0F6C:  LD      DE,46A0h
        LD      BC,0080h
        LD      L,00h
        CALL    0184h
        LD      A,02h
        LD      HL,847Eh
        RST     0x10

L0F7D:  LD      DE,4720h
        CALL    0293h
        LD      A,(0C023h)
        LD      HL,847Eh
        RST     0x10

L0F8A:  LD      DE,4920h
        CALL    0293h
        LD      HL,89E1h
        LD      DE,4EC0h
        JP      0293h

L0F99:  CALL    L0E9E+1         ; reference not aligned to instruction
        LD      HL,0B896h
        LD      DE,4D00h
        CALL    0293h
        LD      HL,8E65h
        LD      DE,47A0h
        JP      0293h

L0FAE:  LD      DE,46A0h
        LD      BC,0080h
        LD      L,0Ah
        CALL    0184h
        LD      A,(0C023h)
        LD      HL,847Eh
        RST     0x10

L0FC0:  LD      DE,4720h
        JP      0293h

L0FC6:  LD      DE,46A0h
        LD      BC,0080h
        LD      L,00h
        CALL    0184h
        LD      A,(0C023h)
        LD      HL,847Eh
        RST     0x10

L0FD8:  LD      DE,4720h
        CALL    0293h
        LD      HL,0B896h
        LD      DE,4D00h
        CALL    0293h
        LD      HL,8583h
        LD      DE,4F00h
        CALL    0293h
        LD      HL,8E65h
        LD      DE,47A0h
        JP      0293h

L0FF9:  LD      DE,46A0h
        LD      BC,0080h
        LD      L,00h
        CALL    0184h
        LD      A,02h
        LD      HL,847Eh
        RST     0x10

L100A:  LD      DE,4720h
        CALL    0293h
        LD      HL,89E1h
        LD      DE,4EC0h
        CALL    0293h
        LD      HL,8E65h
        LD      DE,47A0h
        JP      0293h

L1022:  LD      DE,46A0h
        LD      BC,0200h
        LD      L,00h
        CALL    0184h
        LD      A,03h
        LD      HL,847Eh
        RST     0x10

L1033:  LD      DE,48A0h
        CALL    0293h
        LD      A,(0C023h)
        LD      HL,847Eh
        RST     0x10

L1040:  LD      DE,4AA0h
        CALL    0293h
        LD      HL,0B75Ch
        LD      DE,4720h
        CALL    0293h
        LD      HL,8583h
        LD      DE,4F00h
        JP      0293h

L1058:  LD      DE,46A0h
        LD      BC,0080h
        LD      L,00h
        CALL    0184h
        LD      A,0Bh
        LD      HL,847Eh
        RST     0x10

L1069:  LD      DE,4720h
        CALL    0293h
        LD      A,(0C023h)
        LD      HL,847Eh
        RST     0x10

L1076:  LD      DE,4DA0h
        JP      0293h



_LABEL_107C_35:
	ld   a, ($C01F)
	cp   $89
	ret  c

	cp   $8B
	ret  z

	ld   hl, ($C00E)
	jp   (hl)


; Data from 1089 to 264E (5574 bytes)
.incbin "..\..\Projects\Alex Kidd\Alex Kidd in Miracle World.sms.dat.4"

; imported yazd data

        ORG     1089h

        LD      A,(0C092h)
        OR      A
        JP      NZ,L10B0
        LD      HL,0C100h
        DEC     (HL)
        JP      P,L10B0
        LD      (HL),08h
        INC     HL
        LD      A,(HL)
        CP      04h
        JR      C,L10A1
        XOR     A
        LD      (HL),A
L10A1:  INC     (HL)
        LD      E,A
        LD      D,00h
        LD      HL,10D6h
        ADD     HL,DE
        LD      DE,0C00Bh
        LD      A,(HL)
        CALL    013Fh
L10B0:  LD      A,(0C054h)
        OR      A
        RET     Z
        CP      03h
        RET     NC
        LD      HL,0C05Dh
        DEC     (HL)
        RET     P
        LD      (HL),04h
        INC     HL
        LD      A,(HL)
        CP      04h
        JR      C,L10C7
        XOR     A
        LD      (HL),A
L10C7:  INC     (HL)
        LD      E,A
        LD      D,00h
        LD      HL,10DAh
        ADD     HL,DE
        LD      DE,0C014h
        LD      A,(HL)
        JP      013Fh

L10D6:  RST     0x38

L10D7:  EI
        INC     SP
        CCF
        INC     SP
        CCF
        JP      L10B0

L10E1:  JP      L10B0

L10E4:  JP      L10B0

L10E7:  JP      L10B0

L10EA:  JP      L10B0

L10ED:  JP      L10B0

L10F0:  JP      L10B0

L10F3:  JP      L10B0

L10F6:  JP      L10B0

L10F9:  JP      L10B0

L10FC:  JP      L10B0

        ; --- START PROC L10FF ---
L10FF:  LD      A,87h
        LD      (0FFFFh),A
        LD      A,(0C023h)
        LD      HL,1110h
        RST     0x10

L110B:  LD      DE,0C000h
        LD      B,20h           ; ' '
        RST     0x30

L1111:  RET

L1112:  SBC     A,(HL)
        CP      H
        LD      E,0BEh
        SBC     A,0BCh
        CP      0BCh
        LD      E,0BDh
        LD      A,0BDh
        LD      E,(HL)
        CP      L
        LD      A,(HL)
        CP      L
        CP      (HL)
        CP      L
        SBC     A,0BDh
        SBC     A,(HL)
        CP      L
        CP      0BDh
        LD      E,0BEh
        LD      A,0BEh
        CP      (HL)
        CP      H
        LD      E,(HL)
        CP      (HL)
        LD      A,(HL)
        CP      (HL)
        ; --- START PROC L1134 ---
L1134:  LD      A,87h
        LD      (0FFFFh),A
        LD      A,(0C023h)
        LD      HL,1140h
        JP      0020h

L1142:  LD      H,H
        LD      DE,117Fh
        SBC     A,L
        LD      DE,11B5h
        OUT     (11h),A
        EX      DE,HL
        LD      DE,1206h
        LD      HL,3912h
        LD      (DE),A
        LD      D,H
        LD      (DE),A
        LD      L,A
        LD      (DE),A
        SBC     A,C
        LD      (DE),A
        XOR     (HL)
        LD      (DE),A
        RET     NZ
        LD      (DE),A
        RST     0x08

L115F:  LD      (DE),A
        NOP*

        LD      DE,0CD13h
        OR      D
        INC     D
        CALL    L14A6
        CALL    L14BE
        CALL    L132F
        CALL    L133B
        CALL    L1350
        CALL    L137D
        CALL    L135C
        JP      L1368

L117F:  CALL    L14B2
        CALL    L14A6
        CALL    L14BE
        CALL    L1455
        CALL    L1461
        CALL    L132F
        CALL    L1392
        CALL    L139E
        CALL    L13AA
        JP      L13B6

L119D:  CALL    L14B2
        CALL    L14A6
        CALL    L14CA
        CALL    L132F
        CALL    L1368
        CALL    L137D
        CALL    L13C2
        JP      L13CE

L11B5:  CALL    L14B2
        CALL    L14A6
        CALL    L14CA
        CALL    L154A
        CALL    L132F
        CALL    L133B
        CALL    L13DA
        CALL    L1455
        CALL    L1461
        JP      L13B6

L11D3:  CALL    L14B2
        CALL    L14A6
        CALL    L14BE
        CALL    L132F
        CALL    L1368
        CALL    L133B
        CALL    L137D
        JP      L13E6

L11EB:  CALL    L14B2
        CALL    L14A6
        CALL    L14BE
        CALL    L1455
        CALL    L1461
        CALL    L132F
        CALL    L13FB
        CALL    L1512
        JP      L1410

L1206:  CALL    L14B2
        CALL    L14A6
        CALL    L14CA
        CALL    L1455
        CALL    L1461
        CALL    L14E2
        CALL    L132F
        CALL    L1425
        JP      L149A

L1221:  CALL    L14B2
        CALL    L14A6
        CALL    L14D6
        CALL    L132F
        CALL    L1392
        CALL    L149A
        CALL    L1431
        JP      L139E

L1239:  CALL    L14B2
        CALL    L14A6
        CALL    L14BE
        CALL    L132F
        CALL    L133B
        CALL    L1368
        CALL    L1350
        CALL    L13E6
        JP      L135C

L1254:  CALL    L14B2
        CALL    L14A6
        CALL    L14BE
        CALL    L13B6
        CALL    L132F
        CALL    L143D
        CALL    L1449
        CALL    L1455
        JP      L1461

L126F:  CALL    L14B2
        CALL    L14A6
        CALL    L14CA
        CALL    L132F
        CALL    L14E2
        CALL    L1455
        CALL    L14EE
        CALL    L1476
        CALL    L1461
        CALL    L1425
        CALL    L139E
        CALL    L1392
        CALL    L13AA
        JP      L149A

L1299:  CALL    L14B2
        CALL    L14A6
        CALL    L14BE
        CALL    L1455
        CALL    L1461
        CALL    L13AA
        JP      L132F

L12AE:  CALL    L14B2
        CALL    L14A6
        CALL    L14BE
        CALL    L132F
        CALL    L13B6
        JP      L133B

L12C0:  CALL    L14B2
        CALL    L14A6
        CALL    L14BE
        CALL    L14FA
        JP      L132F

L12CF:  CALL    L14B2
        CALL    L14A6
        CALL    L14BE
        CALL    L1455
        CALL    L1461
        CALL    L132F
        CALL    L1392
        CALL    L139E
        CALL    L13AA
        JP      L13B6

L12ED:  CALL    L14B2
        CALL    L14A6
        CALL    L14BE
        CALL    L132F
        CALL    L13AA
        CALL    L1482
        CALL    L151E
        CALL    L148E
        CALL    L1455
        CALL    L1461
        CALL    L1425
        JP      L13B6

L1311:  CALL    L14B2
        CALL    L14A6
        CALL    L14BE
        CALL    L132F
        CALL    L1368
        CALL    L1482
        CALL    L1561
        CALL    L1506
        CALL    L1350
        JP      L135C

        ; --- START PROC L132F ---
L132F:  LD      HL,87E9h
        LD      DE,6880h
        LD      BC,0220h
        JP      0145h

        ; --- START PROC L133B ---
L133B:  LD      HL,8A09h
        LD      DE,6FA0h
        LD      BC,0180h
        CALL    0145h
        LD      HL,8A09h
        LD      BC,0180h
        JP      02C5h

        ; --- START PROC L1350 ---
L1350:  LD      HL,8DC9h
        LD      DE,7580h
        LD      BC,0040h
        JP      0145h

        ; --- START PROC L135C ---
L135C:  LD      HL,8B89h
        LD      DE,75C0h
        LD      BC,0240h
        JP      0145h

        ; --- START PROC L1368 ---
L1368:  LD      HL,0AE09h
        LD      DE,6AA0h
        LD      BC,0100h
        CALL    0145h
        LD      HL,0AE09h
        LD      BC,0100h
        JP      02C5h

        ; --- START PROC L137D ---
L137D:  LD      HL,95E9h
        LD      DE,6CA0h
        LD      BC,0180h
        CALL    0145h
        LD      HL,95E9h
        LD      BC,0180h
        JP      02C5h

        ; --- START PROC L1392 ---
L1392:  LD      HL,9CA9h
        LD      DE,6C00h
        LD      BC,0020h
        JP      0145h

        ; --- START PROC L139E ---
L139E:  LD      HL,9B49h
        LD      DE,6AA0h
        LD      BC,0160h
        JP      0145h

        ; --- START PROC L13AA ---
L13AA:  LD      HL,9D49h
        LD      DE,7000h
        LD      BC,0100h
        JP      0145h

        ; --- START PROC L13B6 ---
L13B6:  LD      HL,9E49h
        LD      DE,7760h
        LD      BC,00A0h
        JP      0145h

        ; --- START PROC L13C2 ---
L13C2:  LD      HL,0AF09h
        LD      DE,7200h
        LD      BC,00C0h
        JP      0145h

L13CE:  LD      HL,9B09h
        LD      DE,77E0h
        LD      BC,0020h
        JP      0145h

        ; --- START PROC L13DA ---
L13DA:  LD      HL,8FC9h
        LD      DE,72A0h
        LD      BC,0100h
        JP      0145h

        ; --- START PROC L13E6 ---
L13E6:  LD      HL,8EC9h
        LD      DE,72A0h
        LD      BC,0100h
        CALL    0145h
        LD      HL,8EC9h
        LD      BC,0100h
        JP      02C5h

        ; --- START PROC L13FB ---
L13FB:  LD      HL,9769h
        LD      DE,6C00h
        LD      BC,02E0h
        CALL    0145h
        LD      HL,9769h
        LD      BC,02E0h
        JP      02C5h

L1410:  LD      HL,9A49h
        LD      DE,7280h
        LD      BC,00C0h
        CALL    0145h
        LD      HL,9A49h
        LD      BC,00C0h
        JP      02C5h

        ; --- START PROC L1425 ---
L1425:  LD      HL,9EE9h
        LD      DE,7680h
        LD      BC,00C0h
        JP      0145h

        ; --- START PROC L1431 ---
L1431:  LD      HL,0A2A9h
        LD      DE,6C20h
        LD      BC,0AE0h
        JP      0145h

        ; --- START PROC L143D ---
L143D:  LD      HL,0A0A9h
        LD      DE,73E0h
        LD      BC,0020h
        JP      0145h

        ; --- START PROC L1449 ---
L1449:  LD      HL,0A0C9h
        LD      DE,7320h
        LD      BC,00C0h
        JP      0145h

        ; --- START PROC L1455 ---
L1455:  LD      HL,9FA9h
        LD      DE,7400h
        LD      BC,0100h
        JP      0145h

        ; --- START PROC L1461 ---
L1461:  LD      HL,8E09h
        LD      DE,7500h
        LD      BC,00C0h
        CALL    0145h
        LD      HL,8E09h
        LD      BC,00C0h
        JP      02C5h

        ; --- START PROC L1476 ---
L1476:  LD      HL,90C9h
        LD      DE,7180h
        LD      BC,0280h
        JP      0145h

        ; --- START PROC L1482 ---
L1482:  LD      HL,0A229h
        LD      DE,6DC0h
        LD      BC,0080h
        JP      0145h

        ; --- START PROC L148E ---
L148E:  LD      HL,8629h
        LD      DE,6E40h
        LD      BC,01C0h
        JP      0145h

        ; --- START PROC L149A ---
L149A:  LD      HL,0AD89h
        LD      DE,7740h
        LD      BC,0080h
        JP      0145h

        ; --- START PROC L14A6 ---
L14A6:  LD      HL,85A9h
        LD      DE,6840h
        LD      BC,0040h
        JP      0145h

        ; --- START PROC L14B2 ---
L14B2:  LD      HL,8529h
        LD      DE,6800h
        LD      BC,0040h
        JP      0145h

        ; --- START PROC L14BE ---
L14BE:  LD      HL,8529h
        LD      DE,67C0h
        LD      BC,0040h
        JP      0145h

        ; --- START PROC L14CA ---
L14CA:  LD      HL,8569h
        LD      DE,67C0h
        LD      BC,0040h
        JP      0145h

        ; --- START PROC L14D6 ---
L14D6:  LD      HL,85E9h
        LD      DE,67C0h
        LD      BC,0040h
        JP      0145h

        ; --- START PROC L14E2 ---
L14E2:  LD      HL,83C9h
        LD      DE,6F80h
        LD      BC,0080h
        JP      0145h

        ; --- START PROC L14EE ---
L14EE:  LD      HL,8169h
        LD      DE,7100h
        LD      BC,0080h
        JP      0145h

        ; --- START PROC L14FA ---
L14FA:  LD      HL,81E9h
        LD      DE,6B20h
        LD      BC,0080h
        JP      0145h

        ; --- START PROC L1506 ---
L1506:  LD      HL,8449h
        LD      DE,7100h
        LD      BC,0080h
        JP      0145h

        ; --- START PROC L1512 ---
L1512:  LD      HL,8069h
        LD      DE,6AA0h
        LD      BC,0100h
        JP      0145h

        ; --- START PROC L151E ---
L151E:  LD      A,85h
        LD      (0FFFFh),A
        LD      HL,0AF51h
        LD      DE,7180h
        LD      BC,0020h
        CALL    0145h
        LD      HL,0AF51h
        LD      BC,0020h
        CALL    02C5h
        LD      HL,0AF71h
        LD      DE,71C0h
        LD      BC,0040h
        CALL    0145h
        LD      A,87h
        LD      (0FFFFh),A
        RET

        ; --- START PROC L154A ---
L154A:  LD      A,85h
        LD      (0FFFFh),A
        LD      HL,0B211h
        LD      DE,76E0h
        LD      BC,0080h
        CALL    0145h
        LD      A,87h
        LD      (0FFFFh),A
        RET

        ; --- START PROC L1561 ---
L1561:  LD      HL,0A189h
        LD      DE,7180h
        LD      BC,0080h
        JP      0145h

L156D:  JP      NC,0DF15h
        DEC     D
        JP      NC,0EC15h
        DEC     D
        JP      NC,0DF15h
        DEC     D
        LD      (DE),A
        LD      D,1Fh
        LD      D,0D2h
        DEC     D
        RST     0x18

L1580:  DEC     D
        RRA
        LD      D,1Fh
        LD      D,0DFh
        DEC     D
        RRA
        LD      D,0DFh
        DEC     D
        LD      SP,HL
        DEC     D
        JP      NC,L2114+1      ; reference not aligned to instruction
        DEC     H
        JP      NZ,367Eh
        NOP
        OR      A
        JP      Z,L159F
        LD      HL,0C220h
        DEC     (HL)
        RET     NZ
        INC     (HL)
L159F:  LD      HL,0C220h
        DEC     (HL)
        RET     NZ
        LD      (HL),12h
        LD      A,85h
        LD      (0FFFFh),A
        LD      HL,(0C223h)
        JP      (HL)

        ; --- START PROC L15AF ---
L15AF:  LD      HL,0C221h
        INC     (HL)
        LD      A,(HL)
        CP      04h
        JP      C,L15C8
        JP      L15C6

        ; --- START PROC L15BC ---
L15BC:  LD      HL,0C222h
        INC     (HL)
        LD      A,(HL)
        CP      06h
        JP      C,L15C8
        ; --- START PROC L15C6 ---
L15C6:  XOR     A
        LD      (HL),A
        ; --- START PROC L15C8 ---
L15C8:  ADD     A,A
        LD      L,A
        LD      H,00h
        ADD     HL,DE
        LD      A,(HL)
        INC     HL
        LD      H,(HL)
        LD      L,A
        RET

L15D2:  LD      DE,1620h
        CALL    L15BC
        LD      DE,5100h
        LD      B,40h           ; '@'
        RST     0x30

L15DE:  RET

L15DF:  LD      DE,162Ch
        CALL    L15BC
        LD      DE,48C0h
        LD      B,40h           ; '@'
        RST     0x30

L15EB:  RET

L15EC:  LD      DE,1638h
        CALL    L15AF
        LD      DE,49E0h
        LD      B,60h           ; '`'
        RST     0x30

L15F8:  RET

L15F9:  LD      DE,1640h
        CALL    L15AF
        LD      DE,48A0h
        LD      B,60h           ; '`'
        RST     0x30

L1605:  LD      DE,1620h
        CALL    L15BC
        LD      DE,5100h
        LD      B,40h           ; '@'
        RST     0x30

L1611:  RET

L1612:  LD      DE,1648h
        CALL    L15AF
        LD      DE,4B40h
        LD      B,60h           ; '`'
        RST     0x30

L161E:  RET

L161F:  RET

L1620:  LD      D,E
        CP      B
        SUB     E
        CP      B
        OUT     (0B8h),A
        INC     DE
        CP      C
        OUT     (0B8h),A
        SUB     E
        CP      B
        LD      D,E
        CP      C
        SUB     E
        CP      C
        OUT     (0B9h),A
        INC     DE
        CP      D
        OUT     (0B9h),A
        SUB     E
        CP      C
        LD      D,E
        CP      D
        OR      E
        CP      D
        INC     DE
        CP      E
        LD      (HL),E
        CP      E
        OUT     (0BBh),A
        INC     SP
        CP      H
        SUB     E
        CP      H
        DI
        CP      H
        LD      D,E
        CP      L
        OR      E
        CP      L
        INC     DE
        CP      (HL)
        LD      (HL),E
        CP      (HL)
        EXX
        BIT     7,(HL)
        JP      Z,L1735
        LD      A,09h
        CALL    02E6h
        LD      A,(0D800h)
        OR      A
        JR      NZ,L166B
        LD      A,8Ah
        LD      (0C01Fh),A
        LD      B,0Ah
        JP      0343h

L166B:  LD      A,(0C095h)
        OR      A
        RET     NZ
        LD      HL,0000h
        LD      (0C0B9h),HL
        LD      A,0BDh
        LD      (0C014h),A
L167B:  LD      A,01h
        CALL    02E6h
        LD      HL,0C014h
        DEC     (HL)
        JP      NZ,L167B
        LD      A,82h
        LD      (0FFFFh),A
        CALL    9DF3h
        LD      HL,0C030h
        LD      DE,0C031h
        LD      (HL),00h
        LDI
        LDI
        LD      A,01h
        LD      (0C025h),A
        LD      A,06h
        LD      (0C01Fh),A
        RET

L16A6:  LD      A,(0D800h)
        OR      A
        RET     Z
        CALL    69B5h
        LD      HL,(0C0B9h)
        LD      DE,(0C0BDh)
        ADD     HL,DE
        LD      A,H
        CP      0E0h
        JR      C,L16BF
        LD      C,20h           ; ' '
        ADD     A,C
        LD      H,A
L16BF:  LD      (0C0BDh),HL
        CP      D
        RET     Z
        AND     07h
        RET     NZ
        LD      A,H
        ADD     A,0C0h
        LD      C,20h           ; ' '
        JR      C,L16D4
        CP      0E0h
        JR      NC,L16D4
        LD      C,00h
L16D4:  ADD     A,C
        LD      L,A
        LD      H,00h
        ADD     HL,HL
        ADD     HL,HL
        ADD     HL,HL
        LD      DE,7800h
        ADD     HL,DE
        EX      DE,HL
        LD      A,83h
        LD      (0FFFFh),A
        LD      HL,(0C094h)
        LD      A,(HL)
        INC     HL
        OR      A
        JP      Z,L170D
        LD      B,A
        INC     A
        JP      Z,L1730
        INC     A
        JR      Z,L1711
        PUSH    DE
        EXX
        POP     DE
        LD      L,00h
        LD      BC,0040h
        CALL    0184h
        EXX
        LD      A,(HL)
        OR      E
        LD      E,A
        INC     HL
        XOR     A
        LD      (0C10Ah),A
        CALL    0159h
L170D:  LD      (0C094h),HL
        RET

L1711:  PUSH    HL
        LD      A,D
        ADD     A,E
        LD      HL,0100h
        CP      0FEh
        LD      BC,0040h
        JR      C,L172A
        LD      BC,0020h
        CALL    0184h
        LD      BC,0020h
        LD      DE,7800h
L172A:  CALL    0184h
        POP     HL
        JR      L170D

L1730:  XOR     A
        LD      (0C095h),A
        RET

L1735:  CALL    9DF3h
        LD      B,05h
        CALL    0343h
        CALL    0311h
        LD      HL,0C0A0h
        LD      DE,0C0A1h
        LD      BC,002Ah
        LD      (HL),00h
        LDIR
        XOR     A
        LD      (0C091h),A
        LD      A,(0C023h)
        CP      11h
        JP      Z,L1788
        LD      A,01h
        LD      (0C092h),A
        LD      A,83h
        LD      (0FFFFh),A
        LD      A,(0C023h)
        PUSH    AF
        INC     A
        LD      (0C023h),A
        CALL    0E6Ch
        CALL    L10FF
        LD      A,87h
        LD      (0FFFFh),A
        CALL    L1134
        POP     AF
        LD      (0C023h),A
        LD      HL,8AD6h
        LD      DE,8AD6h
        LD      BC,0607h
        JR      L17A1

L1788:  LD      A,(0D800h)
        OR      A
        JP      NZ,L189A
        LD      HL,0BC53h
        LD      DE,0BC53h
        LD      BC,0300h
        LD      A,(0C07Fh)
        OR      A
        JR      Z,L17A1
        LD      BC,0400h
L17A1:  LD      A,85h
        LD      (0FFFFh),A
        LD      (0C0A3h),HL
        LD      (0C0A8h),DE
        LD      A,B
        LD      (0C0B6h),A
        XOR     A
        LD      (0C0C4h),A
        LD      A,C
        LD      (0C0A0h),A
        XOR     A
        LD      (0C0A5h),A
        LD      A,08h
        LD      (0C080h),A
        LD      HL,7800h
        LD      (0C0B7h),HL
        LD      (0C0C5h),HL
L17CB:  LD      HL,0100h
        LD      (0C0ABh),HL
        CALL    67C4h
        CALL    6B49h
        CALL    6920h
        LD      HL,(0C0AFh)
        LD      A,H
        OR      L
        JR      NZ,L17CB
        LD      A,88h
        LD      (0C08Dh),A
        LD      HL,0000h
        LD      (0C0ABh),HL
        LD      A,(0C080h)
        LD      (0C0C9h),A
        LD      IX,0C300h
        LD      DE,0020h
        LD      A,(0C0F8h)
        LD      B,A
L17FD:  CALL    278Ah
        ADD     IX,DE
        DJNZ    L17FD
        LD      A,82h
        LD      (0FFFFh),A
        LD      IX,0C300h
        LD      (IX+00h),01h
        LD      A,(0C023h)
        CP      11h
        JR      Z,L1822
        LD      (IX+0Ch),10h
        LD      (IX+0Eh),88h
        JR      L1874

L1822:  XOR     A
        LD      (0C0C9h),A
        LD      (IX+0Ch),10h
        LD      (IX+0Eh),88h
        LD      A,(0C07Fh)
        OR      A
        JR      NZ,L1857
        LD      C,4Ch           ; 'L'
        LD      DE,88F0h
        LD      B,01h
        LD      (IX+0Ch),70h    ; 'p'
        LD      (IX+0Eh),0A0h
        LD      (IX+0Ah),0FFh
        LD      IX,0C3A0h
        LD      (IX+00h),C
        LD      (IX+0Ch),E
        LD      (IX+0Eh),D
        LD      (IX+03h),B
L1857:  LD      C,60h           ; '`'
        LD      DE,98C0h
        LD      A,(0C07Fh)
        OR      A
        JR      Z,L1867
        LD      C,61h           ; 'a'
        LD      DE,9008h
L1867:  LD      IX,0C3C0h
        LD      (IX+00h),C
        LD      (IX+0Ch),E
        LD      (IX+0Eh),D
L1874:  LD      IX,0C300h
        CALL    29C2h
        CALL    2694h
        LD      DE,8026h
        RST     0x08

L1882:  LD      A,(0C023h)
        INC     A
        LD      C,A
        LD      B,00h
        LD      HL,0DC4h
        ADD     HL,BC
        LD      A,(HL)
        LD      (0C110h),A
        LD      HL,0C01Fh
        SET     7,(HL)
        EI
        JP      02F6h

L189A:  XOR     A
        LD      DE,0C000h
        CALL    013Fh
        XOR     A
        LD      DE,0C010h
        CALL    013Fh
        CALL    09D9h
        CALL    2694h
        LD      A,83h
        LD      (0FFFFh),A
        LD      HL,0B96Ah
        LD      (0C094h),HL
        LD      HL,0039h
        LD      (0C0B9h),HL
        LD      A,0B0h
        LD      (0C110h),A
        LD      HL,0C01Fh
        SET     7,(HL)
        EI
        JP      02F6h

L18CD:  RET

L18CE:  EXX
        BIT     7,(HL)
        JP      Z,L18ED
        LD      A,82h
        LD      (0FFFFh),A
        LD      A,01h
        CALL    02E6h
        LD      HL,0C023h
        INC     (HL)
        LD      A,85h
        LD      (0FFFFh),A
        LD      A,03h
        LD      (0C01Fh),A
        RET

L18ED:  SET     7,(HL)
        CALL    9DF3h
        LD      B,05h
        CALL    0343h
        CALL    0311h
        LD      HL,0D7D0h
        LD      DE,0D7D1h
        LD      (HL),00h
        LD      BC,000Eh
        LDIR
        XOR     A
        LD      (0C08Eh),A
        LD      B,1Eh
        LD      DE,0020h
        LD      IX,0C300h
L1914:  CALL    278Ah
        ADD     IX,DE
        DJNZ    L1914
        LD      HL,0D800h
        LD      DE,0D801h
        LD      (HL),00h
        LD      BC,0007h
        LDIR
        LD      A,(0C023h)
        CP      0Ah
        JP      NZ,L1935
        LD      HL,0D802h
        SET     0,(HL)
L1935:  LD      DE,8026h
        CALL    0008h
        XOR     A
        LD      (0C091h),A
        LD      (0C055h),A
        LD      (0C054h),A
        LD      (0C051h),A
        LD      (0C092h),A
        EI
        JP      02F6h

L194F:  EXX
        BIT     7,(HL)
        JP      Z,L1A46
        LD      A,(0C03Ch)
        CP      15h
        JP      Z,L19AB
        LD      A,82h
        LD      (0FFFFh),A
        LD      A,(0C03Dh)
        OR      A
        LD      A,09h
        JP      NZ,L196D
        LD      A,01h
L196D:  CALL    02E6h
        CALL    2694h
        LD      A,85h
        LD      (0FFFFh),A
        XOR     A
        LD      (0C03Dh),A
        LD      A,(0C03Eh)
        DEC     A
        LD      (0C03Eh),A
        RET     NZ
        LD      HL,0C03Ch
        INC     (HL)
        LD      A,(HL)
        ADD     A,A
        LD      B,00h
        LD      C,A
        LD      HL,9E45h
        ADD     HL,BC
        LD      A,(HL)
        INC     HL
        LD      H,(HL)
        LD      L,A
        LD      (0C038h),HL
        LD      A,03h
        LD      (0C03Eh),A
        LD      A,01h
        LD      (0C03Dh),A
        LD      HL,(0C03Ah)
        INC     HL
        INC     HL
        LD      (0C03Ah),HL
        RET

L19AB:  LD      IX,0C300h
        LD      (IX+00h),56h    ; 'V'
        LD      A,(0C023h)
        CP      10h
        JP      C,L19CB
        LD      IX,0C320h
        LD      (IX+00h),58h    ; 'X'
        LD      (IX+0Ch),98h
        LD      (IX+0Eh),50h    ; 'P'
L19CB:  LD      A,82h
        LD      (0FFFFh),A
        LD      A,01h
        CALL    02E6h
        CALL    2694h
        LD      HL,0C03Fh
        DEC     (HL)
        JP      NZ,L19CB
        LD      IX,0C300h
        CALL    278Ah
        LD      IX,0C320h
        CALL    278Ah
        LD      IX,0C340h
        CALL    278Ah
        CALL    2694h
        LD      A,0Ah
        LD      (0C01Fh),A
        LD      B,05h
        JP      0343h

L1A01:  LD      A,85h
        LD      (0FFFFh),A
        LD      HL,(0C038h)
        LD      DE,(0C03Ah)
        LD      BC,1202h
        CALL    0193h
        LD      DE,(0C03Ah)
        INC     DE
        INC     DE
        LD      (0C03Ah),DE
        LD      HL,0A18Dh
        LD      BC,1202h
        CALL    0193h
        LD      DE,(0C03Ah)
        INC     DE
        INC     DE
        LD      (0C03Ah),DE
        LD      HL,0A1B1h
        LD      BC,1202h
        CALL    0193h
        LD      DE,(0C03Ah)
        DEC     DE
        DEC     DE
        DEC     DE
        DEC     DE
        LD      (0C03Ah),DE
        RET

L1A46:  SET     7,(HL)
        CALL    0311h
        CALL    09D9h
        CALL    0303h
        LD      A,82h
        LD      (0FFFFh),A
        CALL    9DF3h
        XOR     A
        LD      (0C03Ch),A
        LD      (0C03Dh),A
        LD      A,03h
        LD      (0C03Eh),A
        LD      A,85h
        LD      (0FFFFh),A
        LD      HL,1B97h
        LD      DE,0C000h
        LD      BC,0010h
        CALL    0145h
        XOR     A
        LD      DE,0C010h
        CALL    013Fh
        LD      HL,0A1D5h
        LD      DE,4000h
        CALL    0293h
        LD      DE,78C8h
        LD      (0C03Ah),DE
        LD      HL,9E75h
        LD      BC,1202h
        CALL    0193h
        LD      DE,(0C03Ah)
        INC     DE
        INC     DE
        LD      (0C03Ah),DE
        LD      HL,9E99h
        LD      BC,1202h
        CALL    0193h
        LD      DE,(0C03Ah)
        INC     DE
        INC     DE
        LD      (0C03Ah),DE
        LD      HL,0A18Dh
        LD      BC,1202h
        CALL    0193h
        LD      DE,(0C03Ah)
        INC     DE
        INC     DE
        LD      (0C03Ah),DE
        LD      HL,0A1B1h
        LD      BC,1202h
        CALL    0193h
        LD      DE,78C8h
        INC     DE
        INC     DE
        LD      (0C03Ah),DE
        LD      A,01h
        LD      (0C03Ch),A
        LD      A,87h
        LD      (0FFFFh),A
        LD      DE,6800h
        LD      BC,0020h
        LD      L,00h
        CALL    0184h
        LD      HL,0A209h
        LD      DE,6820h
        LD      BC,0020h
        CALL    0145h
        LD      HL,8269h
        LD      DE,6840h
        LD      BC,0140h
        CALL    0145h
        LD      A,03h
        LD      (0C0F8h),A
        LD      HL,0C300h
        LD      (0C0F9h),HL
        LD      A,83h
        LD      (0FFFFh),A
        LD      HL,0BC69h
        LD      DE,6C00h
        CALL    0293h
        LD      IX,0C340h
        LD      (IX+00h),62h    ; 'b'
        LD      A,82h
        LD      (0FFFFh),A
        CALL    2694h
        LD      A,85h
        LD      (0FFFFh),A
        LD      A,50h           ; 'P'
        LD      (0C03Fh),A
        LD      A,86h
        LD      (0C110h),A
        EI
        JP      02F6h

L1B41:  BIT     0,(IX+01h)
        JP      NZ,L1B88
        SET     0,(IX+01h)
        LD      (IX+05h),08h
        LD      (IX+06h),08h
        LD      A,(0C023h)
        ADD     A,A
        LD      C,A
        LD      B,00h
        LD      HL,1BA5h
        ADD     HL,BC
        LD      A,(HL)
        LD      (IX+0Ch),A
        INC     HL
        LD      A,(HL)
        LD      B,A
        LD      A,(0C01Fh)
        AND     7Fh             ; ''
        CP      03h
        JP      Z,L1B84
        LD      A,B
        SUB     18h
        LD      B,A
        LD      A,(0C092h)
        OR      A
L1B78:  JR      Z,L1B84
        LD      (IX+0Ch),5Eh    ; '^'
        LD      (IX+0Eh),46h    ; 'F'
        JR      L1B88

L1B84:  LD      A,B
        LD      (IX+0Eh),A
L1B88:  LD      HL,8A18h
        JP      280Eh

L1B8E:  LD      (IX+07h),73h    ; 's'
        LD      (IX+08h),80h
        RET

L1B97:  NOP
        CPL
        DEC     BC
        LD      B,01h
        INC     C
        EX      AF,AF'
        INC     B
        CCF
        LD      A,38h           ; '8'
        INC     BC
        JR      NC,L1BA5
L1BA5:  RRCA
        NOP
        LD      C,L
        LD      (HL),H
        LD      B,H
        LD      H,H
        LD      D,E
        LD      E,H
        LD      E,D
        LD      C,(HL)
        LD      H,D
        LD      C,(HL)
        LD      (HL),B
        LD      B,L
        LD      L,B
        JR      NC,L1C33
        LD      HL,(L258D)
        SBC     A,E
        LD      (2AADh),A
        RET     NZ
        JR      NC,L1B78
        LD      B,L
        LD      (HL),B
        ADD     A,B
        SUB     B
        LD      L,(HL)
        AND     H
        LD      B,H
        OR      H
        LD      (HL),B
        EXX
        BIT     7,(HL)
        JP      Z,L1D04
        BIT     6,(HL)
        JP      NZ,L1C33
        LD      A,09h
        CALL    02E6h
        LD      A,(0C011h)
        OR      A
        JR      Z,L1BE5
        LD      A,07h
        LD      (0C01Fh),A
        RET

L1BE5:  CALL    2694h
        LD      HL,0C055h
        JP      L1EAF

L1BEE:  LD      HL,0C032h
        LD      DE,7D48h
        CALL    0454h
        CALL    4229h
        LD      A,(0C057h)
        OR      A
        RET     Z
        LD      D,A
        XOR     A
        LD      (0C057h),A
        LD      A,86h
        LD      (0FFFFh),A
        LD      A,(0C023h)
        LD      HL,1FA9h
        RST     0x10

L1C10:  LD      B,03h
L1C12:  PUSH    BC
        LD      A,(HL)
        CP      D
        JR      NZ,L1C2B
        INC     HL
        PUSH    HL
        LD      A,(HL)
        INC     HL
        LD      H,(HL)
        LD      L,A
        SET     0,(HL)
        POP     HL
        INC     HL
        INC     HL
        LD      E,(HL)
        INC     HL
        LD      D,(HL)
        LD      BC,0306h
        CALL    L2532
L1C2B:  LD      BC,0005h
        ADD     HL,BC
        POP     BC
        DJNZ    L1C12
        RET

L1C33:  CALL    9DF3h
        CALL    0311h
        LD      A,82h
        LD      (0FFFFh),A
        LD      A,8Ah
        LD      (0C01Fh),A
        LD      DE,0C800h
        LD      HL,0D000h
        LD      BC,0700h
        LDIR
        LD      HL,0C800h
        LD      DE,7800h
        LD      BC,0700h
        CALL    0145h
        CALL    69B5h
        LD      HL,0C0CAh
        LD      DE,0C0A0h
        LD      BC,002Ah
        LDIR
        LD      A,(0C023h)
        LD      C,A
        LD      B,00h
        LD      HL,0DC4h
        ADD     HL,BC
        LD      A,(HL)
        LD      (0C110h),A
        LD      A,1Eh
        LD      (0C0F8h),A
        LD      DE,0C300h
        LD      HL,0CFA0h
        LD      BC,0020h
        LDIR
        LD      IX,0C300h
        CALL    29C2h
        CALL    2694h
        CALL    L10FF
        LD      A,83h
        LD      (0FFFFh),A
        CALL    0E6Ch
        LD      A,85h
        LD      (0FFFFh),A
        LD      HL,0B2B1h
        LD      DE,5600h
        CALL    0293h
        LD      A,82h
        LD      (0FFFFh),A
        LD      A,(0C054h)
        CP      07h
        JR      C,L1CD6
        CP      08h
        JR      Z,L1CD6
        LD      A,87h
        LD      (0FFFFh),A
        LD      HL,9B29h
        LD      DE,6200h
        LD      BC,0020h
        CALL    0145h
        LD      HL,9429h
        LD      DE,6220h
        LD      BC,01C0h
        CALL    0145h
L1CD6:  LD      A,(0C06Ch)
        LD      (0C069h),A
        LD      HL,(0C06Dh)
        LD      (0C0FDh),HL
        XOR     A
        LD      (0C011h),A
        LD      (0C055h),A
        LD      (0C056h),A
        LD      A,82h
        LD      (0FFFFh),A
        LD      E,26h           ; '&'
        LD      D,80h
        RST     0x08

L1CF6:  EI
        LD      A,09h
        CALL    02E6h
        CALL    02F6h
        LD      B,0Ah
        JP      0343h

L1D04:  SET     7,(HL)
        CALL    9DF3h
        LD      HL,0C0A0h
        LD      DE,0C0CAh
        LD      BC,002Ah
        LDIR
        DEC     HL
        LD      (HL),00h
        LD      D,H
        LD      E,L
        DEC     DE
        LD      BC,0029h
        LDDR
        CALL    0311h
        LD      B,05h
        CALL    0343h
        CALL    0303h
        LD      HL,0C800h
        LD      DE,0D000h
        LD      BC,0700h
        LDIR
        LD      A,85h
        LD      (0FFFFh),A
        LD      HL,908Eh
        LD      DE,0C800h
        CALL    0E41h
        LD      A,01h
        LD      (0C0F8h),A
        LD      HL,0CF80h
        LD      DE,0CF81h
        LD      BC,005Fh
        LD      (HL),00h
        LDIR
        LD      A,82h
        LD      (0FFFFh),A
        LD      HL,0C300h
        LD      DE,0CFA0h
        LD      BC,0020h
        LDIR
        LD      IX,0C300h
        LD      (IX+00h),01h
        LD      (IX+0Ch),20h    ; ' '
        LD      (IX+0Eh),88h
        CALL    29C2h
        CALL    2694h
        LD      A,(0C056h)
        OR      A
        JR      Z,L1D8B
        LD      HL,1F60h
        RST     0x10

L1D85:  SET     0,(HL)
        XOR     A
        LD      (0C056h),A
L1D8B:  LD      A,82h
        LD      (0FFFFh),A
        LD      DE,5800h
        LD      HL,0B385h
        LD      BC,0050h
        LD      A,01h
        CALL    01D6h
        LD      A,85h
        LD      (0FFFFh),A
        LD      HL,93F3h
        LD      DE,4520h
        CALL    0293h
        LD      HL,9840h
        LD      DE,4E00h
        CALL    0293h
        LD      DE,0CB08h
        LD      HL,9800h
        LD      BC,0808h
        CALL    L2522
        LD      HL,0AF11h
        LD      DE,5200h
        LD      BC,01C0h
        CALL    0145h
        LD      HL,0B291h
        LD      DE,5FE0h
        LD      BC,0020h
        CALL    0145h
        LD      HL,0B0B1h
        LD      DE,5420h
        LD      BC,01E0h
        CALL    0145h
        LD      HL,1F42h
        LD      DE,0C000h
        LD      BC,0020h
        CALL    0145h
        LD      A,01h
        LD      (0C055h),A
        LD      A,(0C069h)
        LD      (0C06Ch),A
        LD      A,28h           ; '('
        LD      (0C069h),A
        LD      HL,(0C0FDh)
        LD      (0C06Dh),HL
        LD      HL,0CC06h
        LD      (0C0FDh),HL
        LD      A,16h
        LD      (0C011h),A
        LD      B,03h
        LD      HL,0D7D0h
L1E17:  LD      A,(HL)
        OR      A
        JR      Z,L1E24
        LD      DE,0005h
        ADD     HL,DE
        DJNZ    L1E17
        JP      L1E77

L1E24:  LD      A,01h
        LD      (0C011h),A
        XOR     A
        LD      (0C057h),A
        LD      DE,8006h
        RST     0x08

L1E31:  LD      A,86h
        LD      (0FFFFh),A
        LD      A,(0C023h)
        LD      HL,1F87h
        RST     0x10

L1E3D:  LD      A,03h
        LD      DE,0D7D1h
L1E42:  LDI
        LDI
        LDI
        LDI
        INC     DE
        DEC     A
        JR      NZ,L1E42
        DEC     DE
        LD      A,0FFh
        LD      (DE),A
        LD      HL,0D7D0h
L1E55:  PUSH    HL
        LD      A,(HL)
        CP      0FFh
        JP      Z,L1E76
        OR      A
        JR      NZ,L1E6E
        INC     HL
        LD      E,(HL)
        INC     HL
        LD      D,(HL)
        INC     HL
        LD      A,(HL)
        INC     HL
        LD      H,(HL)
        LD      L,A
        LD      BC,0306h
        CALL    L2522
L1E6E:  POP     HL
        LD      BC,0005h
        ADD     HL,BC
        JP      L1E55

L1E76:  POP     HL
L1E77:  LD      HL,1F30h
        LD      DE,0CD44h
        LD      BC,0012h
        LDIR
        LD      DE,7800h
        LD      HL,0C800h
        LD      BC,0600h
        CALL    0145h
        LD      HL,0C032h
        LD      DE,7D48h
        CALL    0454h
        LD      A,82h
        LD      (0FFFFh),A
        EI
        CALL    02F6h
        LD      A,(0C023h)
        LD      C,A
        LD      B,00h
        LD      HL,0DC4h
        ADD     HL,BC
        LD      A,(HL)
        LD      (0C110h),A
        RET

L1EAF:  LD      HL,0C055h
        BIT     6,(HL)
        JR      Z,L1EC2
        LD      A,(0C31Ah)
        CP      03h
        RET     Z
        RES     6,(HL)
        XOR     A
        LD      (0C056h),A
L1EC2:  LD      A,(0C056h)
        OR      A
        RET     Z
        LD      C,A
        ADD     A,A
        ADD     A,C
        LD      C,A
        LD      B,00h
        LD      HL,1F6Bh
        ADD     HL,BC
        LD      BC,0C030h
        CALL    042Dh
        JP      C,L1F1E
        DEC     HL
        DEC     HL
        DEC     BC
        DEC     BC
        CALL    041Ch
        LD      HL,0C055h
        SET     6,(HL)
        LD      A,(0C056h)
        LD      (0C057h),A
        CP      07h
        JR      NC,L1EFC
        LD      HL,1F60h
        RST     0x10

L1EF4:  SET     0,(HL)
        XOR     A
        LD      (0C056h),A
        JR      L1F0A

L1EFC:  CP      08h
        JR      Z,L1F10
        LD      (0C054h),A
        XOR     A
        LD      (0C05Ah),A
        LD      (0C056h),A
L1F0A:  LD      A,03h
        LD      (0C011h),A
        RET

L1F10:  LD      HL,0C025h
        LD      A,(HL)
        ADD     A,01h
        DAA
        LD      (HL),A
        XOR     A
        LD      (0C056h),A
        JR      L1F0A

L1F1E:  XOR     A
        LD      (0C056h),A
        LD      (0C057h),A
        LD      HL,0C055h
        SET     6,(HL)
        LD      A,02h
        LD      (0C011h),A
        RET

L1F30:  RST     0x38

L1F31:  NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        RET     NZ
        NOP
        JR      NC,L1F83
        LD      (BC),A
        INC     BC
        RRCA
        DEC     BC
        NOP
        LD      B,25h           ; '%'
        LD      HL,(2F01h)
        INC     A
        INC     C
        EX      AF,AF'
        INC     A
        JR      NC,L1F93
        DEC     B
        DEC     BC
        INC     BC
        LD      (BC),A
        NOP
        JR      NC,L1F97
        INC     C
        RRCA
        EX      AF,AF'
        LD      A,(0336h)
        LD      A,(BC)
        LD      C,C
        RET     NZ
        LD      C,D
        RET     NZ
        LD      B,(HL)
        RET     NZ
        LD      B,A
        RET     NZ
        LD      C,B
        RET     NZ
        LD      C,L
        RET     NZ
        LD      (DE),A
        NOP
        NOP
        DJNZ    L1F73
L1F73:  NOP
        DJNZ    L1F76
L1F76:  NOP
        LD      (DE),A
        NOP
        NOP
        DJNZ    L1F7C
L1F7C:  NOP
        DJNZ    L1F7F
L1F7F:  NOP
        JR      NZ,L1F82
L1F82:  NOP
L1F83:  LD      D,B
        NOP
        NOP
        JR      NZ,L1F88
L1F88:  NOP
        LD      B,L
        CP      (HL)
        LD      B,L
        CP      (HL)
        LD      D,C
        CP      (HL)
        LD      D,C
        CP      (HL)
        LD      D,C
        CP      (HL)
L1F93:  LD      D,C
        CP      (HL)
        LD      E,L
        CP      (HL)
L1F97:  LD      E,L
        CP      (HL)
        LD      L,C
        CP      (HL)
        LD      L,C
        CP      (HL)
        LD      (HL),L
        CP      (HL)
        LD      (HL),L
        CP      (HL)
        LD      (HL),L
        CP      (HL)
        LD      (HL),L
        CP      (HL)
        ADD     A,C
        CP      (HL)
        ADD     A,C
        CP      (HL)
        ADD     A,C
        CP      (HL)
        LD      D,C
        CP      A
        LD      D,C
        CP      A
        LD      H,B
        CP      A
        LD      H,B
        CP      A
        LD      H,B
        CP      A
        LD      H,B
        CP      A
        LD      L,A
        CP      A
        LD      L,A
        CP      A
        LD      A,(HL)
        CP      A
        LD      A,(HL)
        CP      A
        ADC     A,L
        CP      A
        ADC     A,L
        CP      A
        ADC     A,L
        CP      A
        ADC     A,L
        CP      A
        SBC     A,H
        CP      A
        SBC     A,H
        CP      A
        SBC     A,H
        CP      A
        EXX
        BIT     7,(HL)
        JP      Z,L2198
        CALL    2694h
        LD      A,09h
        CALL    02E6h
        LD      A,(0C093h)
        OR      A
        RET     Z
        XOR     A
        LD      (0C093h),A
        JR      L1FE9

L1FE6:  JP      L263D

L1FE9:  CALL    9DF3h
        LD      A,82h
        LD      (0FFFFh),A
        CALL    0311h
        LD      DE,0C800h
        LD      HL,0D000h
        LD      BC,0700h
        LDIR
        LD      HL,0C800h
        LD      DE,7800h
        LD      BC,0700h
        CALL    0145h
        CALL    69B5h
        LD      HL,0C300h
        LD      (0C0F9h),HL
        LD      A,1Eh
        LD      (0C0F8h),A
        LD      HL,0C0CAh
        LD      DE,0C0A0h
        LD      BC,002Ah
        LDIR
        LD      A,(0C023h)
        PUSH    AF
        LD      A,(0C092h)
        OR      A
        JR      Z,L2032
        LD      HL,0C023h
        INC     (HL)
L2032:  CALL    L10FF
        LD      A,83h
        LD      (0FFFFh),A
        CALL    0E6Ch
        LD      HL,8000h
        LD      DE,4020h
        LD      BC,0480h
        CALL    0145h
        POP     AF
        LD      (0C023h),A
        LD      A,85h
        LD      (0FFFFh),A
        LD      HL,0B2B1h
        LD      DE,5600h
        CALL    0293h
        LD      A,87h
        LD      (0FFFFh),A
        LD      A,(0C054h)
        CP      03h
        JR      NZ,L208F
        LD      HL,9CC9h
        LD      DE,6200h
        LD      BC,0080h
        CALL    0145h
        LD      HL,9CC9h
        LD      BC,0080h
        CALL    02C5h
        LD      A,85h
        LD      (0FFFFh),A
        LD      HL,0AFB1h
        LD      DE,6300h
        LD      BC,0080h
        CALL    0145h
        JR      L20CB

L208F:  CP      04h
        JR      NZ,L20B2
        LD      HL,84C9h
        LD      DE,6280h
        LD      BC,00C0h
        CALL    0145h
        LD      A,85h
        LD      (0FFFFh),A
        LD      HL,0B031h
        LD      DE,6200h
        LD      BC,0080h
        CALL    0145h
        JR      L20CB

L20B2:  CP      05h
        JR      NZ,L20CB
        LD      HL,83A9h
        LD      DE,6200h
        LD      BC,0020h
        CALL    0145h
        LD      HL,83A9h
        LD      BC,0020h
        CALL    02C5h
L20CB:  LD      A,(0C023h)
        PUSH    AF
        LD      A,(0C092h)
        OR      A
        JR      Z,L20D9
        LD      HL,0C023h
        INC     (HL)
L20D9:  LD      A,87h
        LD      (0FFFFh),A
        CALL    L1134
        POP     AF
        LD      (0C023h),A
        LD      A,82h
        LD      (0FFFFh),A
        LD      A,(0C054h)
        CP      01h
        JR      NZ,L20F8
        LD      IX,0C300h
        CALL    2A6Eh
L20F8:  LD      IX,0CF80h
        CALL    278Ah
        LD      IX,0CFA0h
        CALL    278Ah
        LD      IX,0CFC0h
        CALL    278Ah
        LD      IX,0C300h
        CALL    2694h
L2114:  CALL    67C4h
        CALL    6B49h
        LD      IX,0C300h
        LD      A,(0C023h)
        LD      C,A
        LD      B,00h
        LD      HL,0DC4h
        ADD     HL,BC
        LD      A,(HL)
        LD      (0C110h),A
        LD      A,(0C092h)
        OR      A
        JR      Z,L2139
        LD      A,82h
        LD      (0C110h),A
        JR      L2152

L2139:  LD      A,(0C31Ah)
        CP      05h
        JR      NZ,L2152
        LD      A,83h
        LD      (0C110h),A
        LD      A,(0C023h)
        CP      10h
        JP      NZ,L2152
        LD      A,84h
        LD      (0C110h),A
L2152:  LD      A,(0C054h)
        CP      07h
        JP      C,L216F
        JP      NZ,L2165
        LD      A,85h
        LD      (0C110h),A
        JP      L216F

L2165:  CP      08h
        JP      Z,L216F
        LD      A,88h
        LD      (0C110h),A
L216F:  EI
        LD      A,8Ah
        LD      (0C01Fh),A
        LD      A,09h
        CALL    02E6h
        LD      A,(0C054h)
        OR      A
        JR      Z,L2190
        CP      03h
        JR      NC,L2190
        LD      B,0AAh
        CP      01h
        JR      Z,L218C
        LD      B,0ABh
L218C:  LD      A,B
        LD      (0C110h),A
L2190:  CALL    02F6h
        LD      B,0Ah
        JP      0343h

L2198:  SET     7,(HL)
        CALL    9DF3h
        LD      HL,0C0A0h
        LD      DE,0C0CAh
        LD      BC,002Ah
        LDIR
        DEC     HL
        LD      (HL),00h
        LD      D,H
        LD      E,L
        DEC     DE
        LD      BC,0029h
        LDDR
        CALL    0311h
        LD      B,05h
        CALL    0343h
        LD      HL,0C800h
        LD      DE,0D000h
        LD      BC,0700h
        LDIR
        LD      HL,0C800h
        LD      DE,0C801h
        LD      BC,06FFh
        LD      (HL),00h
        LDIR
        XOR     A
        LD      (0C03Ch),A
        LD      A,85h
        LD      (0FFFFh),A
        LD      B,18h
        LD      DE,0C808h
        LD      (0C03Ah),DE
        LD      HL,9E75h
        LD      (0C038h),HL
L21EB:  PUSH    BC
        LD      DE,(0C03Ah)
        LD      HL,(0C038h)
        LD      BC,1202h
        CALL    L2522
        LD      DE,(0C03Ah)
        INC     DE
        INC     DE
        LD      (0C03Ah),DE
        LD      HL,0C03Ch
        INC     (HL)
        LD      A,(HL)
        ADD     A,A
        LD      B,00h
        LD      C,A
        LD      HL,9E45h
        ADD     HL,BC
        LD      A,(HL)
        INC     HL
        LD      H,(HL)
        LD      L,A
        LD      (0C038h),HL
        POP     BC
        DJNZ    L21EB
        XOR     A
        LD      (0C053h),A
        LD      A,03h
        LD      (0C0F8h),A
        LD      HL,0CF80h
        LD      (0C0F9h),HL
        LD      DE,0CF81h
        LD      BC,005Fh
        LD      (HL),00h
        LDIR
        CALL    69B5h
        LD      A,87h
        LD      (0FFFFh),A
        LD      DE,6800h
        LD      BC,0020h
        LD      L,00h
        CALL    0184h
        LD      HL,0A209h
        LD      DE,6820h
        LD      BC,0020h
        CALL    0145h
        LD      HL,8269h
        LD      DE,6840h
        LD      BC,0140h
        CALL    0145h
        LD      A,82h
        LD      (0FFFFh),A
        LD      IX,0CF80h
        LD      (IX+00h),21h    ; '!'
        LD      (IX+07h),1Dh
        LD      (IX+08h),8Ah
        LD      (IX+06h),08h
        LD      (IX+05h),08h
        LD      (IX+0Ch),74h    ; 't'
        LD      (IX+0Eh),8Eh
        SET     0,(IX+01h)
        LD      IX,0CFA0h
        LD      (IX+00h),56h    ; 'V'
        RES     0,(IX+01h)
        CALL    2694h
        LD      A,(0C023h)
        CP      10h
        JR      C,L22AD
        LD      IX,0CFC0h
        LD      (IX+00h),58h    ; 'X'
        LD      (IX+0Ch),98h
        LD      (IX+0Eh),38h    ; '8'
L22AD:  LD      A,82h
        LD      (0FFFFh),A
        LD      DE,5800h
        LD      HL,0B385h
        LD      BC,0050h
        LD      A,01h
        CALL    01D6h
        LD      A,85h
        LD      (0FFFFh),A
        LD      HL,0A1D5h
        LD      DE,4000h
        CALL    0293h
        LD      HL,0AF11h
        LD      DE,5980h
        LD      BC,01C0h
        CALL    0145h
        LD      HL,0B0B1h
        LD      DE,5BA0h
        LD      BC,01E0h
        CALL    0145h
        LD      A,87h
        LD      (0FFFFh),A
        LD      HL,8000h
        LD      DE,5F80h
        CALL    0293h
        LD      HL,83C9h
        LD      DE,5B20h
        LD      BC,0080h
        CALL    0145h
        LD      HL,0A229h
        LD      DE,5D80h
        LD      BC,0080h
        CALL    0145h
        LD      HL,8169h
        LD      DE,5E00h
        LD      BC,0080h
        CALL    0145h
        LD      HL,81E9h
        LD      DE,5E80h
        LD      BC,0080h
        CALL    0145h
        LD      HL,9349h
        LD      DE,5780h
        LD      BC,0080h
        CALL    0145h
        LD      HL,0A189h
        LD      DE,5F00h
        LD      BC,0080h
        CALL    0145h
        LD      HL,23FDh
        LD      DE,0C000h
        LD      BC,0020h
        CALL    0145h
        CALL    L24EC
        LD      DE,7800h
        LD      HL,0C800h
        LD      BC,0600h
        CALL    0145h
        LD      HL,2429h
        LD      DE,7D42h
        LD      BC,0204h
        CALL    0193h
        LD      HL,0C025h
        LD      DE,7D88h
        LD      C,01h
        CALL    0456h
        LD      HL,2431h
        LD      DE,7CC2h
        LD      BC,0204h
        CALL    0193h
        LD      A,0C0h
        LD      DE,7D12h
        CALL    013Fh
        LD      HL,0C032h
        LD      DE,7D06h
        CALL    0454h
        LD      A,08h
        LD      (0C10Ah),A
        LD      HL,241Dh
        LD      DE,7D94h
        LD      B,0Ch
        CALL    0159h
        LD      HL,0C022h
        LD      DE,7D9Eh
        CALL    0454h
        LD      A,82h
        LD      (0FFFFh),A
        LD      A,(0C023h)
        LD      C,A
        LD      B,00h
        LD      HL,0DC4h
        ADD     HL,BC
        LD      A,(HL)
        LD      (0C110h),A
        LD      A,(0C31Ah)
        CP      05h
        JR      NZ,L23D0
        LD      A,83h
        LD      (0C110h),A
        LD      A,(0C023h)
        CP      10h
        JP      NZ,L23D0
        LD      A,84h
        LD      (0C110h),A
L23D0:  LD      A,(0C054h)
        CP      07h
        JP      C,L23ED
        JP      NZ,L23E3
        LD      A,85h
        LD      (0C110h),A
        JP      L23ED

L23E3:  CP      08h
        JP      Z,L23ED
        LD      A,88h
        LD      (0C110h),A
L23ED:  LD      A,(0C092h)
        OR      A
        JR      Z,L23F8
        LD      A,82h
        LD      (0C110h),A
L23F8:  EI
        CALL    02F6h
        RET

L23FD:  NOP
        CPL
        DEC     BC
        LD      B,01h
        INC     C
        EX      AF,AF'
        INC     B
        CCF
        LD      A,38h           ; '8'
        INC     BC
        JR      NC,L240B
L240B:  RRCA
        NOP
        NOP
        CCF
        DEC     B
        DEC     BC
        INC     BC
        LD      (BC),A
        NOP
        JR      NC,L2452
        INC     C
        RRCA
        EX      AF,AF'
        LD      A,(0336h)
        LD      A,(BC)
        CALL    M,0FEFDh
        RST     0x38

L2421:  NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        RET     NZ
        CALL    PO,0E508h
        EX      AF,AF'
        AND     08h
        RST     0x20

L2430:  EX      AF,AF'
        CP      H
        EX      AF,AF'
        CP      L
        EX      AF,AF'
        CP      (HL)
        EX      AF,AF'
        CP      A
        EX      AF,AF'
        LD      B,(IX+14h)
        LD      (IX+07h),1Dh
        LD      (IX+08h),8Ah
        RES     4,B
        LD      A,(0C006h)
        LD      C,A
        AND     03h
        LD      HL,0000h
        CALL    NZ,L24B6
L2452:  LD      (IX+11h),L
        LD      (IX+12h),H
        LD      HL,0000h
        CALL    L24CF
        LD      (IX+0Fh),L
        LD      (IX+10h),H
        SET     1,B
        LD      (IX+14h),B
        LD      A,(0C31Ah)
        CP      10h
        RET     Z
        LD      A,(0C054h)
        CP      07h
        RET     NC
        LD      A,(0C051h)
        OR      A
        RET     NZ
        LD      A,(0C053h)
        OR      A
        RET     NZ
        LD      DE,1404h
        CALL    7C4Bh
        AND     0E0h
        RET     Z
        LD      D,A
        EXX
        LD      HL,8A18h
        CALL    280Eh
        EXX
        LD      A,(0C006h)
        AND     30h             ; '0'
        RET     Z
        LD      A,8Fh
        LD      (0C110h),A
        LD      A,81h
        LD      (0C053h),A
        XOR     A
        LD      (0C05Ah),A
        LD      A,D
        RRCA
        RRCA
        RRCA
        RRCA
        LD      C,A
        LD      B,00h
        LD      HL,2542h
        ADD     HL,BC
        LD      A,(HL)
        INC     HL
        LD      H,(HL)
        LD      L,A
        JP      (HL)

        ; --- START PROC L24B6 ---
L24B6:  RET

L24B7:  RRCA
        LD      A,(IX+0Eh)
        JR      C,L24C6
        CP      9Ch
        RET     NC
        LD      HL,0200h
        SET     4,B
        RET

L24C6:  CP      88h
        RET     C
        LD      HL,0FE00h
        RES     3,B
        RET

        ; --- START PROC L24CF ---
L24CF:  LD      A,C
        AND     0Ch
        RES     2,B
        RET     Z
        SET     2,B
        AND     04h
        LD      A,(IX+0Ch)
        JR      NZ,L24E5
        CP      0E8h
        RET     NC
        LD      HL,0200h
        RET

L24E5:  CP      70h             ; 'p'
        RET     C
        LD      HL,0FE00h
        RET

        ; --- START PROC L24EC ---
L24EC:  LD      HL,0C04Fh
        SET     0,(HL)
        LD      HL,0C046h
        LD      B,0Ah
L24F6:  LD      A,(HL)
        OR      A
        JR      Z,L251E
        PUSH    HL
        PUSH    BC
        LD      A,B
        ADD     A,A
        LD      E,A
        LD      D,00h
        LD      A,86h
        LD      (0FFFFh),A
        LD      HL,0BDB7h
        ADD     HL,DE
        LD      A,(HL)
        INC     HL
        LD      H,(HL)
        LD      L,A
        LD      E,(HL)
        INC     HL
        LD      D,(HL)
        INC     HL
        LD      A,(HL)
        INC     HL
        LD      H,(HL)
        LD      L,A
        LD      BC,0204h
        CALL    L2522
        POP     BC
        POP     HL
L251E:  INC     HL
        DJNZ    L24F6
        RET

        ; --- START PROC L2522 ---
L2522:  PUSH    BC
        LD      B,00h
        PUSH    DE
        LDIR
        POP     DE
        EX      DE,HL
        LD      C,40h           ; '@'
        ADD     HL,BC
        EX      DE,HL
        POP     BC
        DJNZ    L2522
        RET

        ; --- START PROC L2532 ---
L2532:  LD      HL,0040h
        PUSH    BC
        PUSH    DE
        XOR     A
L2538:  LD      (DE),A
        INC     DE
        DEC     C
        JR      NZ,L2538
        POP     DE
        ADD     HL,DE
        EX      DE,HL
        POP     BC
        DJNZ    L2532
        RET

L2544:  LD      E,D
        DEC     H
        LD      L,B
        DEC     H
        HALT
        DEC     H
        ADD     A,B
        DEC     H
        SUB     H
        DEC     H
        OUT     (25h),A         ; '%'
        XOR     B
        DEC     H
        CALL    PO,0E508h
        EX      AF,AF'
        AND     08h
        RST     0x20

L2559:  EX      AF,AF'
        XOR     A
        LD      (0C046h),A
        LD      HL,7CF4h
        LD      DE,0CCF4h
        LD      A,03h
        JR      L25B4

L2568:  XOR     A
        LD      (0C047h),A
        LD      HL,7CF8h
        LD      DE,0CCF8h
        LD      A,04h
        JR      L25B4

L2576:  LD      HL,7CE0h
        LD      DE,0CCE0h
        LD      A,06h
        JR      L25B4

L2580:  XOR     A
        LD      (0C049h),A
        LD      HL,05FFh
        LD      (0C05Ah),HL
        LD      HL,7CF0h
L258D:  LD      DE,0CCF0h
        LD      A,01h
        JR      L25B4

L2594:  XOR     A
        LD      (0C04Ah),A
        LD      HL,05FFh
        LD      (0C05Ah),HL
        LD      HL,7CECh
        LD      DE,0CCECh
        LD      A,02h
        JR      L25B4

L25A8:  XOR     A
        LD      (0C04Dh),A
        LD      HL,7CDCh
        LD      DE,0CCDCh
        LD      A,05h
L25B4:  LD      (0C054h),A
        LD      (0C058h),HL
        LD      BC,0204h
        CALL    L2532
        LD      HL,0C320h
        LD      B,03h
L25C5:  CALL    278Dh
        INC     HL
        DJNZ    L25C5
        LD      HL,0C31Ch
        LD      A,(HL)
        AND     0F4h
        LD      (HL),A
        RET

L25D3:  CALL    9DF3h
        CALL    0311h
        LD      HL,0C800h
        LD      DE,0C801h
        LD      (HL),00h
        LD      BC,06FFh
        LDIR
        LD      HL,2674h
        LD      DE,0C000h
        LD      BC,0020h
        CALL    0145h
        LD      A,85h
        LD      (0FFFFh),A
        LD      HL,9924h
        LD      DE,7892h
        LD      BC,1218h
        CALL    0193h
        LD      HL,9AD4h
        LD      DE,4000h
        CALL    0293h
        LD      A,82h
        LD      (0FFFFh),A
        LD      IX,0CF80h
        LD      B,03h
        LD      DE,0020h
L261A:  CALL    278Ah
        ADD     IX,DE
        DJNZ    L261A
        CALL    2694h
        EI
        CALL    02F6h
L2628:  LD      A,01h
        CALL    02E6h
        CALL    2694h
        LD      A,(0C093h)
        OR      A
        JR      Z,L2628
        XOR     A
        LD      (0C093h),A
        JP      L1FE9

L263D:  LD      HL,0C053h
        BIT     7,(HL)
        RET     Z
        RES     7,(HL)
        LD      DE,(0C058h)
        LD      BC,0204h
        JP      01C5h


; end

_LABEL_264F_36:
	ld   a, ($C054)
	or   a
	ret  z

	cp   $03
	ret  nc

	ld   hl, ($C05A)
	ld   a, h
	or   l
	jr   z, _LABEL_2663_37
	dec  hl
	ld   ($C05A), hl
	ret

_LABEL_2663_37:
	ld   a, $B2
	ld   ($C110), a
	xor  a
	ld   ($C054), a
	ld   a, $03
	ld   de, $C014
	; set sprite 0x04 colour to 0x03
	jp   _LABEL_13F_38


; Data from 2674 to 2693 (32 bytes)
.db $30, $00, $3F, $2A, $25, $0F, $03, $0B, $3C, $02, $00, $00, $00, $00, $00, $00
.db $30, $00, $3F, $2A, $25, $0F, $03, $0B, $3C, $02, $00, $00, $00, $00, $00, $00

_LABEL_2694_121:
	ld   hl, $C706
	ld   ($C009), hl
	ld   ix, ($C0F9)
	ld   a, ($C0F8)
	ld   b, a
_LABEL_26A2_144:
	ld   a, (ix+0)
	and  $7F
	jp   z, _LABEL_26C0_122
	push bc
	ld   hl, $2890
	rst  $20 ; this just returns?!
	ld   a, (ix+0)
	or   a
	jp   z, _LABEL_26BF_123
	call _LABEL_27D0_124 ; some sort of sanity checking of some pointers in mem
	call _LABEL_273A_128 ;presets/clears a large swathe of memory
	call _LABEL_26D7_131 ; similar
_LABEL_26BF_123:
	pop  bc
_LABEL_26C0_122:
	ld   de, $0020
	add  ix, de
	djnz _LABEL_26A2_144
	ld   hl, ($C009)
	ld   a, l
	cp   $40
	jr   c, _LABEL_26D4_145
	ld   l, $3F
	ld   ($C009), hl
_LABEL_26D4_145:
	ld   (hl), $D0
	ret

_LABEL_26D7_131:
	ld   a, (ix+0)
	or   a
	ret  z

	ld   a, (ix+9)
	or   (ix+10)
	jp   nz, _LABEL_283B_132
	ld   a, (ix+14)
	cp   $C0
	ret  nc

	ld   c, a
	ld   de, ($C009)
	push de
	ld   l, (ix+7)
	ld   h, (ix+8)
	ld   b, (hl)
	push bc
	inc  hl
	ld   a, (hl)
	ld   (ix+19), a
	inc  hl
_LABEL_26FF_134:
	ld   a, c
	add  a, (hl)
	cp   $D0
	jr   nz, _LABEL_2706_133
	dec  a
_LABEL_2706_133:
	ld   (de), a
	inc  e
	inc  hl
	djnz _LABEL_26FF_134
	ld   ($C009), de
	pop  bc
	pop  de
	sla  e
	set  7, e
	ld   c, (ix+12)
_LABEL_2718_138:
	ld   a, c
	add  a, (hl)
	bit  7, (hl)
	jp   z, _LABEL_2720_135
	ccf
_LABEL_2720_135:
	jp   nc, _LABEL_2731_136
	ld   a, $E0
	res  7, e
	srl  e
	ld   (de), a
	sla  e
	set  7, e
	jp   _LABEL_2732_137

_LABEL_2731_136:
	ld   (de), a
_LABEL_2732_137:
	inc  hl
	inc  e
	ldi
	inc  bc
	djnz _LABEL_2718_138
	ret

_LABEL_273A_128:
	ld   de, ($C0B9)
	ld   h, (ix+18)
	ld   l, (ix+17)
	or   a
	sbc  hl, de
	ret  z

	ex   de, hl
	ld   l, (ix+13)
	ld   h, (ix+14)
	add  hl, de
	bit  7, d
	jp   z, _LABEL_276C_129
	jp   c, _LABEL_2783_130
	bit  1, (ix+1)
	jp   nz, _LABEL_278A_127
	ld   a, h
	sub  $40
	ld   (ix+13), l
	ld   (ix+14), a
	dec  (ix+10)
	ret

_LABEL_276C_129:
	ld   a, h
	sub  $C0
	jp   c, _LABEL_2783_130
	bit  1, (ix+1)
	jp   nz, _LABEL_278A_127
	ld   (ix+13), l
	ld   (ix+14), a
	inc  (ix+10)
	ret

_LABEL_2783_130:
	ld   (ix+13), l
	ld   (ix+14), h
	ret

_LABEL_278A_127:
	push ix
	pop  hl
_LABEL_278D_115:
	xor  a
	ld   (hl), a
	inc  l
	ld   (hl), a
	inc  l
	ld   (hl), a
	inc  l
	ld   (hl), a
	inc  l
	ld   (hl), a
	inc  l
	ld   (hl), $01
	inc  l
	ld   (hl), a
	inc  l
	ld   (hl), a
	inc  l
	ld   (hl), a
	inc  l
	ld   (hl), a
	inc  l
	ld   (hl), a
	inc  l
	ld   (hl), a
	inc  l
	ld   (hl), a
	inc  l
	ld   (hl), a
	inc  l
	ld   (hl), a
	inc  l
	ld   (hl), a
	inc  l
	ld   (hl), a
	inc  l
	ld   (hl), a
	inc  l
	ld   (hl), a
	inc  l
	ld   (hl), a
	inc  l
	ld   (hl), a
	inc  l
	ld   (hl), a
	inc  l
	ld   (hl), a
	inc  l
	ld   (hl), a
	inc  l
	ld   (hl), a
	inc  l
	ld   (hl), a
	inc  l
	ld   (hl), a
	inc  l
	ld   (hl), a
	inc  l
	ld   (hl), a
	inc  l
	ld   (hl), a
	inc  l
	ld   (hl), a
	inc  l
	ld   (hl), a
	ld   c, a
	ret

_LABEL_27D0_124:
	ld   hl, ($C0AB)
	ld   d, (ix+16)
	ld   e, (ix+15)
	or   a
	adc  hl, de
	ret  z

	ex   de, hl
	ld   l, (ix+11)
	ld   h, (ix+12)
	add  hl, de
	bit  7, d
	jp   z, _LABEL_27FA_125
	jp   c, _LABEL_2807_126
	bit  1, (ix+1)
	jp   nz, _LABEL_278A_127
	inc  (ix+9)
	jp   _LABEL_2807_126

_LABEL_27FA_125:
	jp   nc, _LABEL_2807_126
	bit  1, (ix+1)
	jp   nz, _LABEL_278A_127
	dec  (ix+9)
_LABEL_2807_126:
	ld   (ix+11), l
	ld   (ix+12), h
	ret


; Data from 280E to 283A (45 bytes)
.db $56, $23, $DD, $7E, $04, $DD, $35, $05, $20, $0B, $DD, $5E, $06, $DD, $73, $05
.db $3C, $BA, $38, $01, $AF, $DD, $77, $04, $87, $5F, $16, $00, $19, $5E, $23, $66
.db $DD, $73, $07, $DD, $74, $08, $C9, $23, $DD, $7E, $04, $18, $EB

_LABEL_283B_132:
	inc  a
	or   (ix+9)
	ret  nz

	ld   a, (ix+14)
	cp   $A8
	ret  c

	ld   c, a
	ld   de, ($C009)
	push de
	ld   l, (ix+7)
	ld   h, (ix+8)
	ld   b, (hl)
	push bc
	inc  hl
	ld   a, (hl)
	ld   (ix+19), a
	inc  hl
_LABEL_285A_139:
	ld   a, c
	add  a, $40
	add  a, (hl)
	ld   (de), a
	inc  e
	inc  hl
	djnz _LABEL_285A_139
	ld   ($C009), de
	pop  bc
	pop  de
	sla  e
	set  7, e
	ld   c, (ix+12)
_LABEL_2870_143:
	ld   a, c
	add  a, (hl)
	bit  7, (hl)
	jp   z, _LABEL_2878_140
	ccf
_LABEL_2878_140:
	jp   nc, _LABEL_2889_141
	ld   a, $E0
	res  7, e
	srl  e
	ld   (de), a
	sla  e
	set  7, e
	jp   _LABEL_288A_142

_LABEL_2889_141:
	ld   (de), a
_LABEL_288A_142:
	inc  hl
	inc  e
	ldi
	inc  bc
	djnz _LABEL_2870_143
	ret


; Data from 2892 to 3FFF (5998 bytes)
.incbin "..\..\Projects\Alex Kidd\Alex Kidd in Miracle World.sms.dat.A"


.BANK 1 SLOT 1
.ORG $0000


; Data from 4000 to 41B2 (435 bytes)
.db $C9, $DD, $36, $1A, $13, $DD, $E5, $CD, $71, $66, $DD, $E1, $21, $C9, $C0, $CB
.db $C6, $3A, $0E, $C3, $FE, $08, $30, $06, $21, $00, $03, $22, $11, $C3, $21, $00
.db $03, $22, $B9, $C0, $C9, $21, $C9, $C0, $7E, $E6, $0F, $CA, $3D, $40, $0F, $DA
.db $CB, $40, $0F, $DA, $E0, $40, $0F, $DA, $90, $40, $C3, $AF, $40, $3A, $0E, $C3
.db $FE, $A8, $38, $1D, $3A, $14, $C3, $CB, $5F, $C2, $B6, $40, $CB, $7F, $CA, $D2
.db $40, $CB, $77, $C2, $B6, $40, $2A, $11, $C3, $7D, $B4, $CA, $D2, $40, $C3, $B6
.db $40, $3A, $1A, $C3, $06, $F0, $FE, $05, $20, $02, $06, $E8, $3A, $0C, $C3, $B8
.db $D8, $DD, $CB, $14, $4E, $C2, $97, $40, $CD, $20, $33, $21, $C9, $C0, $CB, $D6
.db $3A, $10, $C2, $FE, $05, $21, $C0, $FF, $20, $03, $21, $A0, $FF, $22, $0F, $C3
.db $21, $00, $04, $22, $AB, $C0, $C9, $CD, $20, $33, $21, $C9, $C0, $CB, $DE, $3A
.db $10, $C2, $FE, $05, $21, $40, $00, $20, $03, $21, $60, $00, $22, $0F, $C3, $21
.db $00, $FC, $22, $AB, $C0, $C9, $CD, $20, $33, $DD, $E5, $CD, $71, $66, $DD, $E1
.db $21, $C9, $C0, $CB, $C6, $21, $80, $00, $22, $11, $C3, $21, $00, $04, $22, $B9
.db $C0, $C9, $CD, $20, $33, $21, $C9, $C0, $CB, $CE, $21, $80, $FF, $22, $11, $C3
.db $21, $00, $FC, $22, $B9, $C0, $C9, $21, $C9, $C0, $7E, $E6, $03, $CA, $5E, $41
.db $3A, $0E, $C3, $DD, $CB, $12, $7E, $20, $21, $CB, $46, $28, $0F, $FE, $50, $D8
.db $3A, $0A, $C3, $B7, $C0, $2A, $11, $C3, $22, $B9, $C0, $C9, $FE, $A8, $D8, $21
.db $00, $00, $22, $11, $C3, $DD, $CB, $14, $A6, $C9, $C9, $FE, $04, $D0, $DD, $CB
.db $14, $FE, $18, $EB, $3A, $C9, $C0, $4F, $3A, $0C, $C3, $ED, $5B, $0F, $C3, $CB
.db $7A, $28, $19, $CB, $51, $20, $0A, $FE, $04, $D0, $CD, $56, $3B, $22, $AB, $C0
.db $C9, $B8, $D0, $AF, $67, $6F, $ED, $52, $22, $AB, $C0, $C9, $CB, $59, $20, $0A
.db $FE, $F4, $D8, $CD, $56, $3B, $22, $AB, $C0, $C9, $B8, $D8, $18, $E5, $3A, $1A
.db $C3, $FE, $07, $D8, $3A, $0E, $C3, $DD, $CB, $12, $7E, $20, $13, $3A, $0A, $C3
.db $B7, $C0, $FE, $A8, $D8, $21, $00, $00, $22, $11, $C3, $DD, $CB, $14, $A6, $C9
.db $FE, $04, $D0, $DD, $CB, $14, $FE, $18, $EC, $56, $23, $3A, $04, $C3, $DD, $35
.db $05, $20, $07, $DD, $5E, $06, $DD, $73, $05, $3C, $BA, $38, $01, $AF, $32, $04
.db $C3, $87, $5F, $16, $00, $19, $7E, $23, $66, $6F, $7E, $23, $32, $00, $C2, $22
.db $07, $C3, $C9

_LABEL_41B3_24:
	ld   hl, $C200
	ld   a, (hl)
	inc  hl
	cp   (hl)
	ret  z

	ld   (hl), a
	ld   hl, $C225
	ld   (hl), $01
_LABEL_41C0_117:
	add  a, a
	ld   c, a
	ld   b, $00
	ld   de, $6000
	rst  $8
_LABEL_41C8_118:
	ld   a, $84
	ld   ($FFFF), a
	ld   hl, $8000
	add  hl, bc
	ld   e, (hl)
	inc  hl
	ld   d, (hl)
	ex   de, hl
	ld   c, $BE
	ld   a, (hl)
	inc  hl
	ex   af, af'
	xor  a
	ex   af, af'
_LABEL_41DC_25:
	ld   e, (hl)
	inc  hl
	ld   d, (hl)
	inc  hl
	ex   de, hl
	ex   af, af'
	outi
	outi
	outi
	out  ($BE), a
	outi
	outi
	outi
	out  ($BE), a
	outi
	outi
	outi
	out  ($BE), a
	outi
	outi
	outi
	out  ($BE), a
	outi
	outi
	outi
	out  ($BE), a
	outi
	outi
	outi
	out  ($BE), a
	outi
	outi
	outi
	out  ($BE), a
	outi
	outi
	outi
	out  ($BE), a
	ex   af, af'
	ex   de, hl
	dec  a
	jp   nz, _LABEL_41DC_25
	ret


; Data from 4229 to 7FFF (15831 bytes)
.incbin "..\..\Projects\Alex Kidd\Alex Kidd in Miracle World.sms.dat.10"


.BANK 2 SLOT 2
.ORG $0000


; Data from 8000 to 984E (6223 bytes)
.incbin "..\..\Projects\Alex Kidd\Alex Kidd in Miracle World.sms.dat.20"

_LABEL_984F_43:
	call _LABEL_98AE_44
	call _LABEL_986C_47
	ld   ix, $C118
	ld   b, $07
_LABEL_985B_91:
	push bc
	bit  7, (ix+0)
	call nz, _LABEL_9ACC_52
	ld   de, $0020
	add  ix, de
	pop  bc
	djnz _LABEL_985B_91
	ret

_LABEL_986C_47:
	ld   a, ($C111)
	or   a
	jr   z, _LABEL_9897_48
	ld   a, ($C112)
	dec  a
	jr   z, _LABEL_987D_49
	ld   ($C112), a
	jr   _LABEL_9897_48

_LABEL_987D_49:
	ld   a, $1E
	ld   ($C112), a
	ld   a, ($C111)
	dec  a
	cp   $03
	jr   nz, _LABEL_988B_50
	xor  a
_LABEL_988B_50:
	ld   ($C111), a
	ld   ($C120), a
	ld   ($C140), a
	ld   ($C160), a
_LABEL_9897_48:
	ld   hl, $C1D8
	bit  7, (hl)
	ret  z

	inc  hl
	bit  5, (hl)
	jr   z, _LABEL_98A8_51
	ld   hl, $C178
	set  2, (hl)
	ret

_LABEL_98A8_51:
	ld   hl, $C158
	set  2, (hl)
	ret

_LABEL_98AE_44:
	ld   a, ($C110)
	bit  7, a
	jp   z, _LABEL_9DF3_45
	cp   $B4
	jp   nc, _LABEL_9DF3_45
	sub  $81
	; return if sign flag is set
	; i.e. if a is less than 0
	; if a is 0x81 or greater before now then we carry on and do the level load
	ret  m

	cp   $30
	jr   nc, _LABEL_98C5_46
	ld   ($C116), a
_LABEL_98C5_46:
	; breakpointed here
	; this only gets hit when we change to a new level or similar
	; must be a palette/tile/screen refresh thing?
	ld   c, a
	ld   b, $00
	ld   hl, $98DD
	add  hl, bc
	add  hl, bc
	ld   c, (hl)
	inc  hl
	ld   b, (hl)
	ld   de, $005F
	add  hl, de
	ld   a, (hl)
	inc  hl
	ld   h, (hl)
	ld   l, a
	ld   a, ($C113)
	ld   e, a
	jp   (hl)


; Data from 98DD to 9ACB (495 bytes)
.db $CD, $9E, $81, $9F, $BD, $A3, $7D, $A5, $57, $A7, $E0, $A8, $37, $A9, $D1, $AA
.db $56, $AC, $81, $AC, $9B, $AC, $B2, $AC, $C9, $AC, $E1, $AC, $02, $AD, $1E, $AD
.db $2C, $AD, $46, $AD, $8D, $AD, $A7, $AD, $CC, $AD, $59, $AE, $7F, $AE, $A3, $AE
.db $B3, $AE, $CC, $AE, $E3, $AE, $FA, $AE, $14, $AF, $36, $AF, $6D, $AF, $84, $AF
.db $BD, $AF, $CA, $AF, $E9, $AF, $34, $B0, $4D, $B0, $62, $B0, $76, $B0, $90, $B0
.db $AA, $B0, $BE, $B0, $DD, $B0, $F4, $B0, $1D, $B1, $6F, $B1, $89, $B1, $D4, $B1
.db $F0, $99, $F0, $99, $F0, $99, $F0, $99, $F0, $99, $F0, $99, $F0, $99, $F0, $99
.db $F0, $99, $7A, $9A, $7A, $9A, $7A, $9A, $F9, $99, $FC, $99, $FC, $99, $7D, $9A
.db $7A, $9A, $00, $9A, $8B, $9A, $8B, $9A, $04, $9A, $6D, $9A, $85, $9A, $85, $9A
.db $47, $9A, $7A, $9A, $1F, $9A, $81, $9A, $60, $9A, $24, $9A, $60, $9A, $24, $9A
.db $7A, $9A, $00, $9A, $F9, $99, $43, $9A, $7D, $9A, $89, $9A, $89, $9A, $7D, $9A
.db $89, $9A, $68, $9A, $68, $9A, $85, $9A, $7D, $9A, $7D, $9A, $F0, $99, $F0, $99
.db $A3, $99, $D3, $99, $BE, $99, $3A, $16, $C1, $FE, $13, $28, $03, $FE, $10, $C0
.db $AF, $32, $B8, $C1, $3E, $80, $32, $58, $C1, $21, $D8, $C1, $CB, $96, $C3, $C6
.db $9A, $3E, $0B, $32, $11, $C1, $3E, $1E, $32, $12, $C1, $AF, $32, $78, $C1, $3E
.db $FF, $D3, $7F, $C3, $C6, $9A, $AF, $32, $D8, $C1, $32, $14, $C1, $3E, $DF, $3E
.db $80, $32, $58, $C1, $D3, $7F, $3E, $C0, $32, $78, $C1, $21, $B8, $C1, $CB, $96
.db $C3, $C6, $9A, $CD, $F3, $9D, $11, $18, $C1, $C3, $A3, $9A, $AF, $18, $0A, $3E
.db $60, $18, $06, $3E, $70, $18, $02, $3E, $20, $BB, $DA, $C6, $9A, $21, $38, $C1
.db $CB, $D6, $21, $58, $C1, $CB, $D6, $21, $D8, $C1, $CB, $D6, $11, $98, $C1, $C3
.db $9D, $9A, $CD, $F3, $9D, $18, $1A, $3E, $70, $BB, $DA, $C6, $9A, $21, $38, $C1
.db $CB, $D6, $21, $58, $C1, $CB, $D6, $21, $78, $C1, $CB, $D6, $21, $D8, $C1, $CB
.db $D6, $11, $98, $C1, $18, $5A, $3E, $60, $18, $02, $3E, $40, $BB, $38, $7A, $21
.db $78, $C1, $CB, $D6, $21, $58, $C1, $CB, $D6, $21, $D8, $C1, $CB, $D6, $11, $B8
.db $C1, $18, $3D, $3A, $14, $C1, $B7, $20, $60, $18, $05, $3E, $80, $32, $14, $C1
.db $21, $B8, $C1, $CB, $D6, $CD, $0F, $9E, $11, $D8, $C1, $18, $29, $AF, $18, $0E
.db $3E, $60, $18, $0A, $3E, $70, $18, $06, $3E, $30, $18, $02, $3E, $20, $BB, $38
.db $38, $21, $58, $C1, $CB, $D6, $21, $D8, $C1, $CB, $D6, $11, $B8, $C1, $18, $00
.db $32, $13, $C1, $CD, $0F, $9E, $60, $69, $46, $23, $C5, $01, $09, $00, $ED, $B0
.db $3E, $20, $12, $13, $3E, $01, $12, $13, $AF, $12, $13, $12, $13, $12, $E5, $21
.db $12, $00, $19, $EB, $E1, $13, $C1, $10, $E1, $3E, $80, $32, $10, $C1, $C9

_LABEL_9ACC_52:
	ld   e, (ix+12)
	ld   d, (ix+13)
	inc  de
	ld   (ix+12), e
	ld   (ix+13), d
	ld   l, (ix+10)
	ld   h, (ix+11)
	or   a
	sbc  hl, de
	call z, _LABEL_9C39_53
	ld   e, (ix+16)
	ld   d, (ix+17)
	ld   a, e
	or   d
	jr   nz, _LABEL_9AF6_65
	ld   (ix+22), $0F
	jp   _LABEL_9BA0_66

_LABEL_9AF6_65:
	bit  5, (ix+0)
	jr   nz, _LABEL_9B21_68
	ld   a, (ix+6)
	or   a
	jr   nz, _LABEL_9B16_69
	ld   (ix+18), e
	ld   (ix+19), d
	jp   _LABEL_9B5E_70

_LABEL_9B0B_74:
	dec  a
	ld   c, a
	ld   b, $00
	add  hl, bc
	add  hl, bc
	ld   a, (hl)
	inc  hl
	ld   h, (hl)
	ld   l, a
	ret

_LABEL_9B16_69:
	ld   hl, $B28A
	call _LABEL_9B0B_74
	call _LABEL_9BF8_81
	jr   _LABEL_9B5E_70

_LABEL_9B21_68:
	push de
	ld   l, (ix+20)
	ld   h, (ix+21)
	or   a
	sbc  hl, de
	push af
	ld   a, l
	jp   p, _LABEL_9B32_85
	neg
_LABEL_9B32_85:
	ld   h, a
	ld   e, (ix+12)
	call _LABEL_9EAE_59
	ld   e, (ix+10)
	dec  e
	call _LABEL_9EBA_86
	ld   e, a
	ld   d, $00
	pop  af
	ld   a, e
	jp   p, _LABEL_9B4E_90
	neg
	jr   z, _LABEL_9B4E_90
	dec  d
	ld   e, a
_LABEL_9B4E_90:
	pop  hl
	add  hl, de
	ex   de, hl
	ld   (ix+18), e
	ld   (ix+19), d
	ld   a, (ix+6)
	or   a
	jp   nz, _LABEL_9B16_69
_LABEL_9B5E_70:
	ld   a, (ix+7)
	or   a
	jr   nz, _LABEL_9B6F_71
	ld   a, (ix+8)
	cpl
	and  $0F
	ld   (ix+22), a
	jr   _LABEL_9B78_72

_LABEL_9B6F_71:
	ld   hl, $B1F9
	call _LABEL_9B0B_74
	call _LABEL_9BB2_75
_LABEL_9B78_72:
	bit  6, (ix+0)
	jr   nz, _LABEL_9BA0_66
	ld   a, (ix+1)
	cp   $E0
	jr   nz, _LABEL_9B87_73
	ld   a, $C0
_LABEL_9B87_73:
	ld   c, a
	ld   a, (ix+18)
	and  $0F
	or   c
	call _LABEL_9DEB_67
	ld   a, (ix+18)
	and  $F0
	or   (ix+19)
	rrca
	rrca
	rrca
	rrca
	call _LABEL_9DEB_67
_LABEL_9BA0_66:
	ld   a, (ix+1)
	add  a, $10
	or   (ix+22)
	jp   _LABEL_9DEB_67


; Data from 9BAB to 9BAE (4 bytes)
.db $90, $B0, $D0, $F0

_LABEL_9BAF_77:
	ld   (ix+14), a
_LABEL_9BB2_75:
	push hl
	ld   a, (ix+14)
	srl  a
	push af
	ld   c, a
	ld   b, $00
	add  hl, bc
	pop  af
	ld   a, (hl)
	ex   de, hl
	pop  hl
	jr   c, _LABEL_9BE2_76
	rrca
	rrca
	rrca
	rrca
	or   a
	jr   z, _LABEL_9BAF_77
	cp   $10
	jr   nz, _LABEL_9BD3_78
	dec  (ix+14)
	jr   _LABEL_9BB2_75

_LABEL_9BD3_78:
	cp   $20
	jr   z, _LABEL_9BED_79
	cp   $30
	jr   nz, _LABEL_9BE2_76
	inc  de
	ld   a, (de)
	ld   (ix+14), a
	jr   _LABEL_9BB2_75

_LABEL_9BE2_76:
	inc  (ix+14)
	or   $F0
	add  a, (ix+8)
	inc  a
	jr   c, _LABEL_9BEE_80
_LABEL_9BED_79:
	xor  a
_LABEL_9BEE_80:
	cpl
	and  $0F
	ld   (ix+22), a
	ret

_LABEL_9BF5_83:
	ld   (ix+15), a
_LABEL_9BF8_81:
	push hl
	ld   a, (ix+15)
	srl  a
	push af
	ld   c, a
	ld   b, $00
	add  hl, bc
	pop  af
	ld   a, (hl)
	ld   c, l
	ld   b, h
	pop  hl
	jr   c, _LABEL_9C27_82
	rrca
	rrca
	rrca
	rrca
	or   a
	jp   z, _LABEL_9BF5_83
	cp   $10
	jr   nz, _LABEL_9C1B_84
	dec  (ix+15)
	jr   _LABEL_9BF8_81

_LABEL_9C1B_84:
	cp   $20
	ret  z

	cp   $30
	jr   nz, _LABEL_9C27_82
	inc  bc
	ld   a, (bc)
	ld   (ix+15), a
_LABEL_9C27_82:
	inc  (ix+15)
	cpl
	and  $0F
	ld   l, a
	ld   h, $00
	ex   de, hl
	add  hl, de
	ld   (ix+18), l
	ld   (ix+19), h
	ret

_LABEL_9C39_53:
	ld   e, (ix+3)
	ld   d, (ix+4)
	ld   a, (de)
	inc  de
	cp   $E0
	jp   nc, _LABEL_9CCD_54
	bit  3, (ix+0)
	jr   nz, _LABEL_9CAC_55
	or   a
	jp   p, _LABEL_9C88_56
	sub  $80
	jr   z, _LABEL_9C57_57
	add  a, (ix+5)
_LABEL_9C57_57:
	ld   hl, $9E1C
	ld   c, a
	ld   b, $00
	add  hl, bc
	add  hl, bc
	ld   a, (hl)
	ld   (ix+16), a
	inc  hl
	ld   a, (hl)
	ld   (ix+17), a
	bit  5, (ix+0)
	jr   z, _LABEL_9CC6_58
	ld   a, (de)
	inc  de
	sub  $80
	add  a, (ix+5)
	ld   hl, $9E1C
	ld   c, a
	ld   b, $00
	add  hl, bc
	add  hl, bc
	ld   a, (hl)
	ld   (ix+20), a
	inc  hl
	ld   a, (hl)
	ld   (ix+21), a
_LABEL_9C86_64:
	ld   a, (de)
_LABEL_9C87_62:
	inc  de
_LABEL_9C88_56:
	push de
	ld   h, a
	ld   e, (ix+2)
	call _LABEL_9EAE_59
	pop  de
	ld   (ix+10), l
	ld   (ix+11), h
_LABEL_9C97_63:
	xor  a
	ld   (ix+14), a
	ld   (ix+15), a
	ld   (ix+3), e
	ld   (ix+4), d
	xor  a
	ld   (ix+12), a
	ld   (ix+13), a
	ret

_LABEL_9CAC_55:
	ld   (ix+17), a
	ld   a, (de)
	inc  de
	ld   (ix+16), a
	bit  5, (ix+0)
	jr   z, _LABEL_9C86_64
	ld   a, (de)
	inc  de
	ld   (ix+21), a
	ld   a, (de)
	inc  de
	ld   (ix+20), a
	jr   _LABEL_9C86_64

_LABEL_9CC6_58:
	ld   a, (de)
	or   a
	jp   p, _LABEL_9C87_62
	jr   _LABEL_9C97_63

_LABEL_9CCD_54:
	ld   hl, $9CE0
	push hl
	and  $1F
	ld   hl, $9CE4
	ld   c, a
	ld   b, $00
	add  hl, bc
	add  hl, bc
	ld   a, (hl)
	inc  hl
	ld   h, (hl)
	ld   l, a
	jp   (hl)


; Data from 9CE0 to 9DEA (267 bytes)
.db $13, $C3, $3F, $9C, $1F, $9D, $24, $9D, $72, $9D, $29, $9D, $40, $9D, $4A, $9D
.db $50, $9D, $56, $9D, $5C, $9D, $62, $9D, $9E, $9D, $B9, $9D, $CC, $9D, $45, $9D
.db $17, $9D, $68, $9D, $6E, $9D, $08, $9D, $3A, $23, $C0, $FE, $10, $C8, $D5, $01
.db $BD, $A3, $CD, $F0, $99, $D1, $C9, $1A, $DD, $86, $05, $DD, $77, $05, $C9, $1A
.db $DD, $77, $02, $C9, $1A, $DD, $77, $08, $C9, $1A, $F6, $E0, $F5, $CD, $EB, $9D
.db $F1, $F6, $FC, $3C, $20, $05, $DD, $CB, $00, $B6, $C9, $DD, $CB, $00, $F6, $C9
.db $1A, $DD, $77, $07, $C9, $1A, $DD, $77, $06, $C9, $EB, $5E, $23, $56, $1B, $C9
.db $DD, $CB, $00, $EE, $1B, $C9, $DD, $CB, $00, $AE, $1B, $C9, $DD, $CB, $00, $DE
.db $1B, $C9, $DD, $CB, $00, $9E, $1B, $C9, $AF, $32, $14, $C1, $18, $08, $1A, $32
.db $15, $C1, $AF, $32, $13, $C1, $DD, $77, $00, $21, $38, $C1, $CB, $96, $21, $58
.db $C1, $CB, $96, $21, $78, $C1, $CB, $96, $21, $D8, $C1, $CB, $96, $3A, $B8, $C1
.db $CB, $7F, $20, $04, $3E, $E4, $D3, $7F, $CD, $E4, $9D, $E1, $E1, $C9, $1A, $4F
.db $13, $1A, $47, $C5, $DD, $E5, $E1, $DD, $35, $09, $DD, $4E, $09, $DD, $35, $09
.db $06, $00, $09, $72, $2B, $73, $D1, $1B, $C9, $DD, $E5, $E1, $DD, $4E, $09, $06
.db $00, $09, $5E, $23, $56, $DD, $34, $09, $DD, $34, $09, $C9, $1A, $13, $C6, $17
.db $4F, $06, $00, $DD, $E5, $E1, $09, $7E, $B7, $20, $02, $1A, $77, $13, $35, $C2
.db $4A, $9D, $13, $C9, $DD, $7E, $01, $C6, $10, $F6, $0F

_LABEL_9DEB_67:
	bit  2, (ix+0)
	ret  nz

	out  ($7F), a
	ret

_LABEL_9DF3_45:
	exx
	; memmove($c111, $c112, 0xe4)
	; 0xe4 = 228 = 1/4 of 32x28
	ld   hl, $C111
	ld   de, $C112
	ld   bc, $00E4
	ld   (hl), $00
	ldir
	exx
_LABEL_9E02_3:
	exx
	; $7F is sound output
	: copies 4 bytes from $9e18
	; bytes are 9F BF DF FF
	; this turns all 4 channels off
	ld   hl, $9E18
	ld   c, $7F
	ld   b, $04
	otir
	xor  a
	exx
	ret


; Data from 9E0F to 9EAD (159 bytes)
.db $3E, $DF, $D3, $7F, $3E, $FF, $D3, $7F, $C9, $9F, $BF, $DF, $FF, $00, $00, $FF
.db $03, $C7, $03, $90, $03, $5D, $03, $2D, $03, $FF, $02, $D4, $02, $AB, $02, $85
.db $02, $61, $02, $3F, $02, $1E, $02, $00, $02, $E3, $01, $C8, $01, $AF, $01, $96
.db $01, $80, $01, $6A, $01, $56, $01, $43, $01, $30, $01, $1F, $01, $0F, $01, $00
.db $01, $F2, $00, $E4, $00, $D7, $00, $CB, $00, $C0, $00, $B5, $00, $AB, $00, $A1
.db $00, $98, $00, $90, $00, $88, $00, $80, $00, $79, $00, $72, $00, $6C, $00, $66
.db $00, $60, $00, $5B, $00, $55, $00, $51, $00, $4C, $00, $48, $00, $44, $00, $40
.db $00, $3C, $00, $39, $00, $36, $00, $33, $00, $30, $00, $2D, $00, $2B, $00, $28
.db $00, $26, $00, $24, $00, $22, $00, $20, $00, $1E, $00, $1C, $00, $1B, $00, $19
.db $00, $18, $00, $16, $00, $15, $00, $14, $00, $13, $00, $12, $00, $11, $00

_LABEL_9EAE_59:
	ld   d, $00
	ld   l, d
	ld   b, $08
_LABEL_9EB3_61:
	add  hl, hl
	jr   nc, _LABEL_9EB7_60
	add  hl, de
_LABEL_9EB7_60:
	djnz _LABEL_9EB3_61
	ret

_LABEL_9EBA_86:
	ld   b, $08
_LABEL_9EBC_89:
	adc  hl, hl
	ld   a, h
	jr   c, _LABEL_9EC4_87
	cp   e
	jr   c, _LABEL_9EC7_88
_LABEL_9EC4_87:
	sub  e
	ld   h, a
	or   a
_LABEL_9EC7_88:
	djnz _LABEL_9EBC_89
	ld   a, l
	rla
	cpl
	ret


; Data from 9ECD to BFFF (8499 bytes)
.incbin "..\..\Projects\Alex Kidd\Alex Kidd in Miracle World.sms.dat.27"


.BANK 3
.ORG $0000


; Data from C000 to FFFF (16384 bytes)
.incbin "..\..\Projects\Alex Kidd\Alex Kidd in Miracle World.sms.dat.30"


.BANK 4
.ORG $0000


; Data from 10000 to 13FFF (16384 bytes)
.incbin "..\..\Projects\Alex Kidd\Alex Kidd in Miracle World.sms.dat.40"


.BANK 5
.ORG $0000


; Data from 14000 to 17FFF (16384 bytes)
.incbin "..\..\Projects\Alex Kidd\Alex Kidd in Miracle World.sms.dat.50"


.BANK 6
.ORG $0000


; Data from 18000 to 1BFFF (16384 bytes)
.incbin "..\..\Projects\Alex Kidd\Alex Kidd in Miracle World.sms.dat.60"


.BANK 7
.ORG $0000


; Data from 1C000 to 1FFFF (16384 bytes)
.incbin "..\..\Projects\Alex Kidd\Alex Kidd in Miracle World.sms.dat.70"

