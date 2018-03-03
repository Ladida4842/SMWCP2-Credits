incsrc defines.asm

lorom
cleartable

org $008000
level:
		;JSL $7F8000
SEI
STZ $4200
STZ $420C
CLC : XCE
LDA #$80 : STA $2100
REP #$30
LDA #$01FF : TCS
		;REP #$20
		;LDX #$7E : STX $02
		;LDA #$8000 : STA $00
		;LDA #$0333
		;JSL $0FF900
		;INX : STX $02
		;LDA #$3000 : STA $00
		;LDA #$0334
		;JSL $0FF900
		;SEP #$20
LDX #$7FFE
-
LDA Upload,x
STA $7E8000,x
LDA #$0000
STA $7E0000,x
STA $7F0000,x
DEX #2 : BPL -

LDX #ENDGRAPHICS-GRAPHICS-1
-
LDA $028000,x
STA $7F3000,x
DEX #2 : BPL -

SEP #$20

LDX.w #STRIPE_DECOMP_END-STRIPE_DECOMP-1
-
LDA STRIPE_DECOMP,x
STA.l !stripedecomp,x
DEX : BPL -

SEP #$10
JML $7E8000



STRIPE_DECOMP:
base !stripedecomp
REP #$10
PLX : PLY : STY $00 : PHX
TDC : TAY
LDA #$7F : STA $4304 : STA $02
LDA #$18 : STA $4301
.loop
LDA [$00],y
BMI .end
STA $04
INY
LDA [$00],y
STA $03
INY
LDA [$00],y
BIT #$40
BNE .rle
ASL
LDA #$40
ROL
STA $2115
REP #$21
LDA $03 : STA $2116
LDA [$00],y
XBA
AND #$3FFF
INC
STA $4305
INY #2
TYA : TYX
ADC $4305
TAY : TXA
CLC : ADC $00
STA $4302
SEP #$20
LDA #$01 : STA $4300 : STA $420B
BRA .loop

.end
SEP #$10
RTS

.rle
ASL
LDA #$40
ROL
STA $05
STA $2115
REP #$21
LDA $03 : STA $2116
LDA [$00],y
XBA
AND #$3FFF
LSR : INC
STA $4305 : STA $06
INY #2
TYA
SEC : ADC $00
STA $4302
STA $08
LDA #$1908 : STA $4300
SEP #$20
LDA #$01 : STA $420B
LSR $05
TDC : ROL
STA $2115
REP #$21
LDA $03 : STA $2116
LDA $06 : STA $4305
INY #2
LDA $08
DEC
STA $4302
SEP #$20
LDA #$18 : STA $4301
LDA #$01 : STA $420B
JMP .loop
base off
STRIPE_DECOMP_END:



BRK:
SEP #$30
PHK : PLB
STZ $4200 : STZ $420C
PEA $2100 : PLD
STZ $30 : STZ $33 : STZ $2C : STZ $31 : STZ $21
LDA #$FF : STA $22 : LSR : STA $22
LDA #$0F : STA $00
EOR #$80 : BRA $FA

warnpc $00FFC0
org $00FFC0
db "SMWCP2 Credits BETAv2"	; ROM name 21 bytes total
db $20		; ROM layout
db $00		; Cartridge type
db $07		; ROM size
db $00		; SRAM size
db $00		; Country code
db $00		; Licensee code
db $00		; Version number
dw ~$0000 	; Checksum complement
dw $0000 	; Checksum

dw $FFFF,$FFFF	;[null]
dw $FFFF 	;	COP	(native)
dw BRK		;	BRK	(native)
dw $FFFF 	;	ABORT	(native)
dw $FFFF	;	NMI	(native)
dw $FFFF	;[null]	RESET	(native)
dw $FFFF	;	IRQ	(native)
dw $FFFF,$FFFF	;[null]
dw $FFFF	;	COP	(emulation)
dw $FFFF	;[null] BRK	(emulation)
dw $FFFF	;	ABORT	(emulation)
dw $FFFF	;	NMI	(emulation)
dw level	;	RESET	(emulation)
dw $FFFF	;	IRQ/BRK	(emulation)
warnpc $018000

org $018000

Upload:
base $7E8000
bank $7E
incsrc init.asm
bank auto
base off
warnpc $01C000

org $028000
base $7F3000
GRAPHICS:
incbin credits.bin
	orig_border:
		incbin stim/orig_border.stim
	orig_ground:
		incbin stim/orig_ground.stim
	orig_water:
		incbin stim/orig_water.stim

	bake_standard:
		incbin stim/bake_standard.stim
	bake_debug:
		incbin stim/bake_debug.stim

	mado_runes:
		incbin stim/mado_runes.stim

	arak_fish:
		incbin stim/arak_fish.stim
	arak_skyline:
		incbin stim/arak_skyline.stim

	hida_tone:
		incbin stim/hida_tone.stim

	mari_cake:
		incbin stim/mari_cake.stim
	mari_moon:
		incbin stim/mari_moon.stim
	mari_pyramid:
		incbin stim/mari_pyramid.stim

ENDGRAPHICS:
base off
warnpc $038000

org $03FFFF
db $00