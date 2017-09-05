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
	ld   sp, $DFF0
	jr   _LABEL_85_2

_LABEL_8_10:
	ld   a, e
	out  ($BF), a
	ld   a, d
	out  ($BF), a
	ret


; Data from F to 1A (12 bytes)
.db $FF, $87, $4F, $06, $00, $09, $7E, $23, $66, $6F, $C9, $FF

_LABEL_1B_39:
	bit  7, a
	ret  z

	and  $0F
_RST_20H:
	add  a, a
	ld   e, a
	ld   d, $00
	add  hl, de
	ld   a, (hl)
	inc  hl
	ld   h, (hl)
	ld   l, a
	jp   (hl)


; Data from 2A to 2F (6 bytes)
.db $FF, $FF, $FF, $FF, $FF, $FF

_RST_30H:
	rst  $8
	ld   c, $BE
_LABEL_33_112:
	outi
	jr   nz, _LABEL_33_112
	ret

; this gets called 140 times per second!!
; at $38 because we set interrupt mode to 1
_IRQ_HANDLER:
	jp   _LABEL_C0_13


; Data from 3B to 52 (24 bytes)
.db $6D, $07, $6D, $07, $E5, $09, $4F, $19, $CE, $18, $C9, $1B, $0C, $6C, $C9, $7D
.db $50, $16, $88, $0A, $88, $0A, $CD, $1F

_LABEL_53_93:
	xor  a
	ld   ($C01F), a
_LABEL_57_147:
	ld   hl, $C01F
	ld   a, (hl)
	and  $0F
	exx
	ld   hl, $003B
	rst  $20
	jp   _LABEL_57_147


; Data from 65 to 65 (1 bytes)
.db $FF

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

_LABEL_85_2:
	ld   a, $82
	ld   ($FFFF), a
	call _LABEL_9E02_3
	ld   hl, $C000
	ld   de, $C001
	ld   bc, $1FFF
	ld   (hl), l
	ldir
	call _LABEL_341_4
	call _LABEL_350_7
_LABEL_9F_14:
	ld   a, $82
	ld   ($FFFF), a
	ld   sp, $DFF0
	call _LABEL_9E02_3
	call _LABEL_26B_8
	ld   hl, $0000
	ld   de, $4000
	ld   bc, $3800
	call _LABEL_184_9
	ei
	call _LABEL_2F6_92
	jp   _LABEL_53_93

; interrupt handler
; called 140 times per second
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
	in   a, ($BF)
	in   a, ($DD)
	and  $10
	ld   hl, $C096
	ld   c, (hl)
	ld   (hl), a
	xor  c
	and  c
	jp   nz, _LABEL_9F_14
	ld   a, ($FFFF)
	push af
	ld   a, ($C008)
	rrca
	push af
	call c, _LABEL_1F7_15
	call _LABEL_41B3_24
	pop  af
	rrca
	push af
	call _LABEL_367_26
	call _LABEL_107C_35
	pop  af
	rrca
	push af
	call _LABEL_264F_36
	pop  af
	rrca
	ld   a, ($C01F)
	ld   hl, $0127
	call c, _LABEL_1B_39
	ld   a, $82
	ld   ($FFFF), a
	call _LABEL_984F_43
	xor  a
	ld   ($C008), a
	pop  af
	ld   ($FFFF), a
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
	ei
	ret


; Data from 127 to 13E (24 bytes)
.db $42, $08, $42, $08, $35, $0A, $01, $1A, $CD, $18, $EE, $1B, $AE, $6E, $29, $7F
.db $A6, $16, $B1, $0A, $B1, $0A, $E6, $1F

_LABEL_13F_38:
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
	ld   de, $7800
	ld   bc, $0700
	ld   l, $00
_LABEL_184_9:
	rst  $8
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
	push bc
	rst  $8
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
	ld   a, ($C01F)
	and  $0F
	cp   $02
	jr   c, _LABEL_208_16
	ld   hl, $C10D
	inc  (hl)
	bit  0, (hl)
	jr   z, _LABEL_224_17
_LABEL_208_16:
	ld   hl, $C700
	ld   de, $7F00
	ld   bc, $40BE
	rst  $8
_LABEL_212_18:
	outi
	jr   nz, _LABEL_212_18
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
	ld   hl, $C700
	ld   bc, $11BE
	ld   de, $7F00
	rst  $8
_LABEL_235_20:
	outi
	jr   nz, _LABEL_235_20
	ld   hl, ($C009)
	ld   a, l
	dec  l
	sub  $11
	ld   b, a
_LABEL_241_21:
	outd
	jr   nz, _LABEL_241_21
	ld   a, $D0
	out  ($BE), a
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
	dec  l
	dec  l
	outi
	outd
	jp   nz, _LABEL_261_23
	ret

_LABEL_26B_8:
	ld   hl, $027D
	ld   bc, $16BF
	otir
	xor  a
	out  ($BE), a
	ld   a, ($027F)
	ld   ($C004), a
	ret


; Data from 27D to 292 (22 bytes)
.db $26, $80, $A0, $81, $FF, $82, $FF, $83, $FF, $84, $FF, $85, $FF, $86, $00, $88
.db $00, $89, $00, $87, $10, $C0

_LABEL_293_104:
	ld   b, $04
_LABEL_295_108:
	push bc
	push de
	call _LABEL_2A0_105
	pop  de
	inc  de
	pop  bc
	djnz _LABEL_295_108
	ret

_LABEL_2A0_105:
	ld   a, (hl)
	inc  hl
	or   a
	ret  z

	ld   b, a
	ld   c, a
	res  7, b
_LABEL_2A8_107:
	ld   a, e
	out  ($BF), a
	ld   a, d
	out  ($BF), a
	ld   a, (hl)
	out  ($BE), a
	bit  7, c
	jp   z, _LABEL_2B7_106
	inc  hl
_LABEL_2B7_106:
	inc  de
	inc  de
	inc  de
	inc  de
	djnz _LABEL_2A8_107
	jp   nz, _LABEL_2A0_105
	inc  hl
	jp   _LABEL_2A0_105


; Data from 2C4 to 2E5 (34 bytes)
.db $CF, $1E, $08, $56, $CB, $22, $1F, $1D, $20, $FA, $D3, $BE, $23, $0B, $78, $B1
.db $20, $EF, $C9, $21, $00, $C7, $11, $01, $C7, $01, $BF, $00, $36, $E0, $ED, $B0
.db $3E, $01

_LABEL_2E6_99:
	ld   hl, $C008
	ld   (hl), a
_LABEL_2EA_100:
	ld   a, (hl)
	or   a
	jr   nz, _LABEL_2EA_100
	ret

_LABEL_2EF_97:
	ld   a, ($C004)
	and  $BF
	jr   _LABEL_2FB_98

_LABEL_2F6_92:
	ld   a, ($C004)
	or   $40
_LABEL_2FB_98:
	ld   ($C004), a
	ld   e, a
	ld   d, $81
	rst  $8
	ret


; Data from 303 to 310 (14 bytes)
.db $AF, $32, $BE, $C0, $32, $B0, $C0, $5F, $16, $89, $CF, $15, $CF, $C9

_LABEL_311_96:
	call _LABEL_2EF_97
	ld   hl, $0000
	ld   ($C0AF), hl
	ld   ($C0BD), hl
	ld   ($C0AB), hl
	ld   ($C0B9), hl
	ld   hl, $C700
	ld   de, $C701
	ld   bc, $00BF
	ld   (hl), $E0
	ldir
	ld   de, $8800
	rst  $8
	ld   d, $89
	rst  $8
	ei
	ld   a, $01
	call _LABEL_2E6_99
	di
	jp   _LABEL_17C_101

_LABEL_341_4:
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
	ld   de, $C020
	ld   hl, $C000
	ld   b, $03
	or   a
_LABEL_444_103:
	ld   a, (de)
	sbc  a, (hl)
	inc  hl
	inc  de
	djnz _LABEL_444_103
	ret  c

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
_LABEL_76D_94:
	exx
	bit  7, (hl)
	jp   nz, _LABEL_7EC_95
	set  7, (hl)
	xor  a
	ld   ($C10A), a
	call _LABEL_311_96
	ld   de, $6000
	ld   bc, $0020
	ld   l, $00
	call _LABEL_184_9
	ld   a, $82
	ld   ($FFFF), a
	call _LABEL_9DF3_45
	call _LABEL_43B_102
	ld   hl, $C020
	ld   de, $C021
	ld   bc, $1DDF
	ld   (hl), $00
	ldir
	ld   hl, $C226
	ld   (hl), $3C
	xor  a
	ld   ($C227), a
	ld   ($C228), a
	ld   a, $84
	ld   ($FFFF), a
	ld   hl, $B332
	ld   de, $4020
	call _LABEL_293_104
	ld   hl, $AD9E
	ld   de, $788E
	ld   bc, $061C
	call _LABEL_193_109
	ld   hl, $AE46
	ld   de, $79DA
	ld   bc, $071A
	call _LABEL_193_109
	ld   hl, $08C6
	ld   de, $C000
	ld   b, $20
	rst  $30
	call _LABEL_8F6_113
	call _LABEL_2F6_92
	ei
	ld   hl, $01D0
	ld   ($C103), hl
	ld   a, $81
	ld   ($C110), a
_LABEL_7EC_95:
	ld   a, $09
	call _LABEL_2E6_99
	call _LABEL_2694_121
	ld   a, ($C006)
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
_LABEL_842_40:
	ld   hl, $C226
	dec  (hl)
	ret  nz

	ld   (hl), $20
	inc  hl
	ld   a, (hl)
	cp   $06
	jr   c, _LABEL_866_41
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
	jp   _LABEL_13F_38

_LABEL_866_41:
	inc  (hl)
	ld   hl, $FFFF
	ld   (hl), $84
	ld   hl, $08E6
	jp   _RST_20H


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
	rst  $20
	ld   a, (ix+0)
	or   a
	jp   z, _LABEL_26BF_123
	call _LABEL_27D0_124
	call _LABEL_273A_128
	call _LABEL_26D7_131
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
	ret  m

	cp   $30
	jr   nc, _LABEL_98C5_46
	ld   ($C116), a
_LABEL_98C5_46:
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
	ld   hl, $C111
	ld   de, $C112
	ld   bc, $00E4
	ld   (hl), $00
	ldir
	exx
_LABEL_9E02_3:
	exx
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

