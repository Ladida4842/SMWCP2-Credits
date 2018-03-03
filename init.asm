;---------------------------------------------------------------------------
; INIT
;---------------------------------------------------------------------------

	.init
		PHK : PLB
		PEA $2100 : PLD
		LDA #$02 : STA $01
		STZ $05
		STZ $25
		STZ $33
		REP #$20
		STZ $23
		STZ $02
		LDX #$E1 : LDY #$00	;Y position = xE1
		-
		STX $04
		INY : BNE -
		LSR : BCC -
		SEP #$20
		PEA $0000 : PLD

	.sincos_gen
		LDX #$81
		-
		LDA sincostable,y
		STA !sincostable,y
		STA !sincostable+$7F,x
		INY : DEX : BNE -

	.orig_grad_gen
		TXY
		-
		LDA orig_grad,y
		STA !orig_grad,x
		BEQ +
		REP #$21
		STZ !orig_grad+1,x
		LDA orig_grad+1,y
		STA !orig_grad+3,x
		SEP #$20
		INY #3
		TXA : ADC #$05 : TAX
		BRA -
		+

	.hdma_hidamari_grad_gen
		TAX : TAY
		-
		LDA EV_HIDA_hdmatable,y
		BEQ +
		LDA #$10 : STA !hida_table,x : STA !hida_table2,x
		REP #$21
		LDA #$0200 : STA !hida_table+1,x
		LDA #$2200 : STA !hida_table2+1,x
		LDA EV_HIDA_hdmatable,y
		STA !hida_table+3,x
		STA !hida_table2+3,x
		SEP #$20
		INY #2
		TXA : ADC #$05 : TAX
		BRA -
		+
		STA !hida_table,x : STA !hida_table2,x

	.hdma_mariaholic_grad_gen
		LDA #$80
		STA !mari_table : STA !mari_table+1
		XBA : LDA #$01 : TAX : LDY #$20
		-
		STA !mari_table+1,x
		XBA : STA !mari_table+2,x
		INC : XBA : EOR #$03
		INX #2
		DEY : BNE -
		STZ !mari_table+1,x

	.ROTATE_90DEG			;clockwise
		PHB : PEA $307F : PLB	;src =  $7F3000
		PHY : TYX
		REP #$10	
		---
		LDY #$0007
		BRA +
		--
		DEX #8
		+
		LDA #$07 : STA $02
		LDA ($01,s),y
		-
		ASL : ROL $0000,x	;dest = $7F0000
		INX : DEC $02 : BPL -
		DEY : BPL --
		REP #$21
		PLA : ADC #$0008 : PHA
		SEP #$20 
		CPX #$1000 : BCC ---	;length = $1000
		PLX
		SEP #$10
		PLB

	;init VRAM
		PHD : PEA $420B : PLD
		LDA #$7F : STA $F9		;$4304
		LDA #$18 : STA $F6		;$4301
		LDY #$01
		-
		LDA .uploadtbl,x
		BEQ .bg_gen
		DEC
		STA $002115
		LDA .uploadtbl+1,x : STA $F5	;$4300
		REP #$20
		LDA .uploadtbl+2,x : STA $002116
		LDA .uploadtbl+4,x : STA $F7	;$4302
		LDA .uploadtbl+6,x : STA $FA	;$4305
		SEP #$21
		STY $00				;$420B
		TXA : ADC #$07 : TAX
		BRA -

		.uploadtbl
		; 2115  43x0     2116  43x2  43x5
		db $81,$09 : dw $0000,$3000,$0000	;clear VRAM
		db $01,$00 : dw $6000,$3000,$1000	;1bpp graphics (text)
		db $81,$01 : dw $7000,$5000,$2000	;2bpp graphics
		db $81,$01 : dw $4800,$4000,$1000	;backgrounds (2bpp)
		db $81,$01 : dw $4400,$7000,$0800	;extra 2bpp graphics
		db $01,$00 : dw $5000,$0000,$1000	;1bpp graphics (rotated)
		db $81,$01 : dw $4000,$7800,$0800	;4bpp graphics (sprites)
		db $00

	.bg_gen

		PLD
		PHA : PLB
		STZ $2115
		STZ $00
		REP #$20
		LDA #$3000 : STA $2116
		PHA
		SEP #$20
		PHB : PHK : PLB
		---
		LDX #$03
		--
		LDY #$1F
		-
		STA $002118
		AND #$77
		INC A
		AND #$77
		.lbl2
		NOP #2
		DEY : BPL -
		CLC : ADC #$10
		.lbl3
		BPL --
		.lbl1
		LDA #$00
		DEX : BPL --
		LDA $00
		BEQ +
		LSR : BEQ ++
		BCS +++
		LDA #$88 : STA .lbl2+1
		BRA ++++
		+
		LDA #$09 : STA .lbl2
		DEC : STA .lbl2+1
		BRA ++++
		++
		LDA #$30 : STA .lbl3
		LDA #$80 : STA .lbl2+1
		++++
		STA .lbl1+1
		INC $00
		BRA ---
		+++
		PLB
		LDA #$80 : STA $2115
		REP #$30
		PLA : STA $2116
		SEP #$21
		LDX #$0FFF
		ROL
		-
		STA $2119
		DEX : BPL -
		LDX #credits_names : STX !credits
		SEP #$10
		LDA #$7E : STA !subpoint+2

;---------------------------------------------------------------------------
; MAIN
;---------------------------------------------------------------------------

MAIN_LOOP:
	PHB : PHK : PLB
	REP #$20
	INC !frame
	SEP #$20
	LDA !frame
	AND #$07
	BNE +
	DEC !marioframe
	BPL +
	LDA #$02
	STA !marioframe
	+
	JSR main_code
	PLB

;pseudo-NMI
	BIT $4210 : BPL $FB : LDA $4210
	LDA #$80 : STA $2100
	JSR .mirrorupload
	JSR nmi_code
	LDA !hdmareg : STA $420C
	LDA !brightness : STA $2100
	BRA MAIN_LOOP

.mirrorupload
	LDA !layer1x : STA $210D
	LDA !layer1x+1 : STA $210D
	LDA !layer1y : STA $210E
	LDA !layer1y+1 : STA $210E
	LDA !layer2x : CLC : ADC !layer2xoff : STA $210F
	LDA !layer2x+1 : ADC !layer2xoff+1 : STA $210F
	LDA !layer2y : CLC : ADC !layer2yoff : STA $2110
	LDA !layer2y+1 : ADC !layer2yoff+1 : STA $2110
	LDA !layer3x : CLC : ADC !layer3xoff : STA $2111
	LDA !layer3x+1 : ADC !layer3xoff+1 : STA $2111
	LDA !layer3y : CLC : ADC !layer3yoff : STA $2112
	LDA !layer3y+1 : ADC !layer3yoff+1 : STA $2112
	LDA !layer4x : STA $2113
	LDA !layer4x+1 : STA $2113
	LDA !layer4y : STA $2114
	LDA !layer4y+1 : STA $2114

	REP #$20 : LDA !bgcolor : ASL #3
	SEP #$21 : ROR #3 : XBA
	ORA #$40 : STA $2132
	LDA !bgcolor+1 : LSR
	SEC : ROR : STA $2132
	XBA : STA $2132

	REP #$20
	LDA !tilesize : AND #$FFF0 : STA $2105
	LDA !layer1map : STA $2107
	LDA !layer3map : STA $2109
	LDA !layer12gfx : STA $210B
	LDA !mainscr : STA $212C
	LDA !cgwsel : ORA #$3002 : STA $2130

	LDA #!color : STA $4312
	LDA #$00D0 : STA $4315
	LDA #$2202 : STA $4310
	SEP #$20
	STZ $4314
	STZ $2121
	STA $420B
INTERNATIONAL_RETURN:
	RTS

;---------------------------------------------------------------------------
; SCENES (all, except 1st, based off of shinbo-directed shaft shows)
;---------------------------------------------------------------------------

nmi_code:
	LDA !event
	JSR EXECUTEPTR
	dw NMI_EV_ORIG
	dw NMI_EV_SZS1
	dw NMI_EV_BAKE
	dw NMI_EV_SZS2
	dw NMI_EV_MADO
	dw NMI_EV_SZS3
	dw NMI_EV_ARAK
	dw NMI_EV_SZS4
	dw NMI_EV_HIDA
	dw NMI_EV_SZS5
	dw NMI_EV_MARI
	dw NMI_EV_SZS6

main_code:
	LDA !event
	JSR EXECUTEPTR
	dw EV_ORIG	;homage to original SMWCP credits
	dw EV_SZS1	;1st intermission, zetsubo-sensei's pseudo-1st OP
	dw EV_BAKE	;bakemonogatari's title cards, ssb melee's debug menu
	dw EV_SZS2	;2nd intermission, zetsubo-sensei's 2nd OP (scene after horiz lines)
	dw EV_MADO	;madoka magica's real ED (ep3+)
	dw EV_SZS3	;3rd intermission, zetsubo-sensei's kumeta animation
	dw EV_ARAK	;arakawa under the bridge's 1st OP
	dw EV_SZS4	;4th intermission, zetsubo-sensei's 1st OP (hanging scene)
	dw EV_HIDA	;hidamari sketch's 1st OP
	dw EV_SZS5	;5th intermission, zetsubo-sensei's title cards
	dw EV_MARI	;maria holic's 1st ED, homage to SMW credits
	dw EV_SZS6	;6th intermission, same as 1st intermission

;---------------------------------------------------------------------------

NMI_EV_ORIG:
	JSR EXECUTESUBEV
	dw .init
	dw .fade
	dw .main
	dw INTERNATIONAL_RETURN

	.init
		STZ $2121
		STZ $4314
		REP #$20
		LDA #!color : STA $4312
		LDA #$0180 : STA $4315
		LDA #$2202 : STA $4310
		TAY : STY $420B
		LDA #$2103 : STA $4350
		LDA #!orig_grad : STA $4352
		SEP #$20
		STZ $4354
		LDA #$20 : STA !hdmareg
		PEA.w orig_border
		JSR !stripedecomp
		PEA.w orig_ground
		JSR !stripedecomp
		PEA.w orig_water
		JSR !stripedecomp
		INC !subevent
		LDX #$78 : LDY #$51
		JMP MARIO_ANI_INIT

	.fade
		LDA !frame
		LSR : BCC ++
		LDA !brightness
		INC A
		CMP #$0F
		BCC +
		INC !subevent
		LDX #$01 : STX !fadetimer
		DEX : STX !character_to_DMA
		DEX : STX !renderingname
		+
		STA !brightness
		++
		RTS

	.main
		LDX #$78 : LDY #$51
		JSR MARIO_ANI_MAIN
		JMP NMI_EV_ORIG_NAMES

EV_ORIG:
	JSR EXECUTESUBEV
	dw .init
	dw INTERNATIONAL_RETURN
	dw .main
	dw .prepare

	.init
		REP #$30
		LDA #$1100 : STA !layer1map
		LDA #$3421 : STA !layer3map
		LDA #$4666 : STA !layer12gfx
		LDA #$0817 : STA !mainscr
		LDX #$017E
		-
		LDA ORIG_PAL,x
		STA !color,x
		DEX #2 : BPL -
		LDA !color+(2*$60)
		STA !bgcolor
		SEP #$30
		LDA #$0F : STA !mosaic
		STZ !brightness
		RTS

	.main
		REP #$20
		LDA !frame
		LSR : BCS +
		INC !layer2x
		BIT #$0003
		BNE +
		INC !layer3x
		+
		SEP #$20
		JMP EV_ORIG_NAMES

	.prepare
		LDA #$10
		TRB !mainscr
		JMP MOSAIC_FADEOUT

;---------------------------------------------------------------------------

NMI_EV_SZS1:
	JSR EXECUTESUBEV
	dw .init
	dw INTERNATIONAL_RETURN
	dw .main
	dw INTERNATIONAL_RETURN

	.main
		JSR LINE_CLEAR
		DEC !fadetimer
		BNE .return
		LDA !character_to_DMA
		-
		STA !fadetimer
		LDX !renderingname : STX $01
		LDA.l .strings,x
		BEQ .end
		BMI .change
		TAY
		SEC : ADC !renderingname
		STA !renderingname
		TYA
		SEC : SBC #$18
		EOR #$FF : INC
		LSR
		STA !location_to_DMA
		STZ !location_to_DMA+1
		STZ $2115
		LDA #$7E : STA $4314
		STZ $00
		REP #$21
		LDA #$29A4 : STA $2116
		LDA #$1808 : STA $4310
		STZ $4312
		LDA #$0018 : STA $4315
		LDX #$02 : STX $420B
		XBA : STA $4310
		LDA #$29A4 : CLC : ADC !location_to_DMA : STA $2116
		LDA $00 : XBA : ADC #.strings+1 : STA $4312
		TYA : STA $4315
		SEP #$20
		STX $420B
	.init
		STZ !hdmareg
		RTS
	.end
		INC !subevent
	.return
		RTS
	.change
		REP #$21
		PEA !color+(2*$68) : JSR COLOR_UPLOAD
		SEP #$20
		LDA #$20 : STA !character_to_DMA
		INC !renderingname
		BRL -

	.strings
		table ascii.tbl
		db 23,"Did you enjoy the hack?"
		db 12,"You didn't?!",$80
		db 03,"BAN"
		db 07,"BAN BAN"
		db 15,"BAN BAN BAN BAN"
		db 01," ",$00
		cleartable

EV_SZS1:
	JSR EXECUTESUBEV
	dw .init
	dw MOSAIC_FADEIN
	dw .main
	dw MOSAIC_FADEOUT

	.init
		LDA #$03 : STA !lineclear_start
		REP #$20
		STZ !layer3x
		STZ !lineclear_addr1
		LDA #$0400 : STA !lineclear_end1
		ASL #2 : STA !lineclear_addr2
		ASL : STA !lineclear_addr3
		LDA #$1800 : STA !lineclear_end2
		LDA #$2800 : STA !lineclear_end3
		PEA !color+(2*$64) : JSR COLOR_UPLOAD
		LDA #$3C28 : STA !layer3map
		LDA #$1804 : STA !layer1map
		LDA #$0C02 : STA !mainscr
		SEP #$21
		STA !cgadsub
		INC !subevent
		DEC : STA !fadetimer
		STZ !renderingname
		ROR : STA !character_to_DMA
		RTS

	.main
		LDA !frame
		AND #$01
		STA !layer3yoff
		LDX #$03
		JSR RANDOM
		ASL : TAX
		REP #$21
		LDA .randcolor,x
		STA !color
		SEP #$20
		JSR TRUERANDOM
		LDA !layer2x
		ADC !randgen1
		STA !layer2x
		RTS

	.randcolor
		dw $0821,$0421,$0021,$0000	;$0421,$0842,$0C63,$0000

;---------------------------------------------------------------------------

NMI_EV_BAKE:
	JSR EXECUTESUBEV
	dw .init
	dw .init2
	dw INTERNATIONAL_RETURN
	dw NMI_EV_BAKE_NAMES
	dw .main2
	dw INTERNATIONAL_RETURN

	.init
		LDX #$2C : LDY #$B5
		JSR MARIO_ANI_INIT
		PEA.w bake_standard
		BRA +
	.init2
		PEA.w bake_debug
		+
		JSR !stripedecomp
		RTS

	.main2
		LDX #$2C : LDY #$B5
		JSR MARIO_ANI_MAIN
		JSR NMI_EV_BAKE_NAMES
		REP #$20
		PHD : LDA #$2100 : TCD
		TAX : STX $15
		LDA #$1527 : STA $16
		LDA.w !frame
		JSR HEXDEC_LONG
		PHX : PHY
		JSR HEXDEC_LONG
		SEP #$20
		ORA #$30 : STA $18
		TYA : ORA #$30 : STA $18
		TXA : ORA #$30 : STA $18
		PLA : ORA #$30 : STA $18
		PLA : ORA #$30 : STA $18
		LDY #$02
		STZ $4314
		REP #$20
		LDA #$1461 : STA $16
		LDA #$1800 : STA $4310
		LDA #$FFC0 : STA $4312
		LDA #$000B : STA $4315
		STY $420B
		STA $4315
		LDA #$FFCB : STA $4312
		LDA #$1481 : STA $16
		STY $420B
		LDA #$14A3 : STA $16
		SEP #$20
		LDA $FFDF : JSR HEX_TO_TEXT
		STA $18 : XBA : STA $18
		LDA $FFDE : JSR HEX_TO_TEXT
		STA $18 : XBA : STA $18
		LDA #$7E : STA $18
		LDA $FFDD : JSR HEX_TO_TEXT
		STA $18 : XBA : STA $18
		LDA $FFDC : JSR HEX_TO_TEXT
		STA $18 : XBA : STA $18
		LDX #$A9 : STX $16
		LDY #$16 : STY $17
		LDA.w !marioframe : JSR HEX_TO_TEXT
		STA $18 : XBA : STA $18
		PLD : RTS

EV_BAKE:
	JSR EXECUTESUBEV
	dw .init
	dw .init2
	dw MOSAIC_FADEIN
	dw .main
	dw .main2
	dw .prepare

	.init
		LDA #$10 : STA !layer2map
		REP #$21
		STZ !layer2x
		LDA #$3820 : STA !layer3map
		LDA #$7FFF : STA !color
		PEA !color+(2*$6C) : JSR COLOR_UPLOAD
		LDA !color+(2*$20) : STA !color+(2*$21)
		LDA !color+(2*$24) : STA !color+(2*$25)
		LDA #$0802 : STA !mainscr
		SEP #$20
		LDA #$84 : STA !cgadsub
		LDA #$55 : STA !layer12gfx
		LDA #$01
		STA !fadetimer
		STZ !start_creditDMA
	.init2
		INC !subevent
		RTS
	.main2
		LDA #$16 : STA !mainscr
		LDA #$14 : STA !layer2map
	.main
		LDA !frame
		AND #$01
		DEC
		STA !layer3xoff
		STA !layer3yoff
		JMP EV_BAKE_NAMES
	.prepare
		LDA #$10 : TRB !mainscr
		JMP MOSAIC_FADEOUT

;---------------------------------------------------------------------------

NMI_EV_SZS2:
	JSR EXECUTESUBEV
	dw INTERNATIONAL_RETURN
	dw INTERNATIONAL_RETURN
	dw LINE_CLEAR
	dw INTERNATIONAL_RETURN

EV_SZS2:
	JSR EXECUTESUBEV
	dw .init
	dw MOSAIC_FADEIN
	dw .main
	dw MOSAIC_FADEOUT

	.init
		LDA #$3C : STA !layer4map
		LDA #$65 : STA !layer12gfx
		LDA #$02 : STA !lineclear_start
		REP #$20
		LDA #$1804 : STA !layer1map
		LDA #$1000 : STA !lineclear_addr1
		ASL : STA !lineclear_addr2
		LDA #$1800 : STA !lineclear_end1
		LDA #$2400 : STA !lineclear_end2
		LDA #$0902 : STA !mainscr
		STZ !color
		PEA !color+(2*$70) : JSR COLOR_UPLOAD
		LDA !color+(2*$20) : STA !color+(2*$01)
		SEP #$20
		LDA #$02 : STA !cgadsub
		LDA #$80
		STA !fadetimer
		INC !subevent
		RTS

	.main
		LDA !frame
		LSR : BCS +
		DEC !fadetimer
		BNE +
		INC !subevent
		+
		REP #$21
		LDA !layer3yoff
		ADC #$0100
		STA !layer1y
		SEP #$20
		JMP EV_SZS1_main

;---------------------------------------------------------------------------

NMI_EV_MADO:
	JSR EXECUTESUBEV
	dw .init
	dw .fade
	dw .main
	dw .main
	dw INTERNATIONAL_RETURN

	.init
		LDA #$C1 : STA $2121
		LDA !color+(2*$81) : STA $2122
		LDA !color+(2*$81+1) : STA $2122
		PEA.w mado_runes
		JSR !stripedecomp
		RTS
	.fade
	.main
		JSR NMI_EV_MADO_NAMES
		STZ $4314
		REP #$20
		STZ $2102
		LDA #$0400 : STA $4310
		LDA #!oam : STA $4312
		LDA #$0154 : STA $4315
		LDX #$02 : STX $420B
		LDA #$0100 : STA $2102
		LDA #!oam+$0160 : STA $4312
		LDA #$0020 : STA $4315
		STX $420B
		SEP #$20
		RTS

EV_MADO:
	JSR EXECUTESUBEV
	dw .init
	dw .fade
	dw .main
	dw .main2
	dw .prepare

	.init
		LDA #$20 : STA !tilesize
		LDA #$01 : STA !character_to_DMA
		REP #$21
		LDA #$1000 : STA !layer1map
		LDA #$3034 : STA !layer3map
		LDA #$4466 : STA !layer12gfx
		STZ !layer2x
		LDA #$03C0 : STA !location_to_DMA
		PEA !color+(2*$74) : JSR COLOR_UPLOAD
		PEA !color+(2*$78) : PEA !color+(2*$40) : SEC : JSR COLOR_UPLOAD
		LDA !color+(2*$78) : STA !color
		STZ !color+(2*$21)
		LDA !color+(2*$03) : STA !color+(2*$01)
		LDA #$0A15 : STA !mainscr
		SEP #$20
		LDA #$84 : STA !cgadsub
		LDA #$FF : STA !fadetimer
		STZ !start_creditDMA
		INC !subevent
		RTS
	.fade
		JSR MOSAIC_FADEIN
	.main
		JSR EV_MADO_NAMES
		JSR .lightgenerator
		REP #$20
		LDA !frame
		BIT #$0001
		BEQ +
		INC !layer2x
		INC !layer3yoff
		BIT #$0002
		BEQ ++
		DEC !layer2xoff
		BRA ++
		+
		DEC !layer2x
		++
		ASL
		ADC !frame
		STA $04
		SEP #$20
		LDA #$C0 : STA $06
		JSR CIRCLEX
		STZ !layer3xoff+1
		LDA $07 : STA !layer3xoff
		LDA !frame
		BIT #$01
		BNE +
		INC !layer4x
		+
		BIT #$03
		BNE +
		INC !layer1y
		+
		BIT #$07
		BNE +
		DEC !layer4y
		+
		LDA !frame : STA $04
		LDA !highframe : STA $05
		LDA #$27 : STA $06
		JSR CIRCLEY
		STZ !layer2yoff+1
		LDA $08
		BPL +
		INC !layer2yoff+1
		+
		STA !layer2yoff
		JMP HDMA_SCROLL
	.prepare
		LDA #$10 : TRB !mainscr
		STZ !hdmareg
		JMP MOSAIC_FADEOUT
	.main2
		LDA !frame
		AND #$03
		BNE .main
		DEC !fadetimer
		BNE .main
		INC !subevent
		REP #$20
		INC !creditsindex
		SEP #$20
		RTS

	.lightgenerator
		REP #$20
		LDA !frame
		STA $04
		SEP #$20
		LDA #$20 : STA $06
		JSR CIRCLEX
		LDA #$08 : STA $06
		JSR CIRCLEY
		LDA !frame
		AND #$01
		CLC : ADC #$80
		CLC : ADC $07
		STA !lightxpos
		LDA !frame
		AND #$01
		CLC : ADC #$40
		CLC : ADC $08
		STA !lightypos

		LDX #$00 : LDY #$00
		LDA !lightypos : STA $01
		REP #$10
		-
		LDA .lighttilemap,x
		BMI .end
		CLC : ADC !lightxpos
		STA $00
		INX
		--
		LDA .lighttilemap,x
		BMI .endrow
		STA !oamt,y
		LDA #$08
		STA !oamp,y
		LDA $00 : STA !oamx,y
		LDA $01 : STA !oamy,y
		INX : INY #4
		LDA $00 : CLC : ADC #$08 : STA $00
		BRA --
		.endrow
		LDA $01 : CLC : ADC #$08 : STA $01
		INX
		BRA -
		.end
		SEP #$10
		RTS

	.lighttilemap
		table light.tbl
		db $28,     "101 "
		db $18,   "112121 "
		db $08, "112232321 "
		db $00,"1123444432 "
		db $08, "1233444431 "
		db $00,"123444443211 "
		db $00,"12334443431 "
		db $08, "123344432 "
		db $10,  "12223321 "
		db $20,    "12121 "
		db $28,     "11 "
		db $FF
		cleartable

;---------------------------------------------------------------------------

NMI_EV_SZS3:
	JSR EXECUTESUBEV
	dw .init
	dw .fade
	dw .main
	dw .main2
	dw .main3
	dw .prepare

	.init
		LDX #$09
		-
		LDA.l .windowtable,x
		STA !windowtable,x
		DEX : BPL -
		STZ $4334
		REP #$20
		LDA #%0000001100110011 : STA $2123
		LDA #$2601 : STA $4330
		LDA.w #!windowtable : STA $4332
		SEP #$20
		LDA #$08 : STA !hdmareg
		BRA .main3
	.main2
		JSR .uploadpantsu
		LDA #%00100000 : STA $2125
		BRA .prepare
	.main
		JSR LINE_CLEAR
	.main3
		STZ $2125
	.prepare
		REP #$20
		LDA !mainscr : STA $212E
		SEP #$20
		RTS
	.fade
		PHD : PEA $2100 : PLD
		LDA #$02
		REP #$20
		STZ $02
		LDX #$E1 : LDY #$00	;OAM stuff (Ypos = $E1)
		-
		STX $04			;OAM write
		INY : BNE -
		LSR : BCC -
		PLD
		BRA .prepare

	.uploadpantsu
		PHD : PEA $2100 : PLD
		REP #$20
		STZ $02
		SEP #$20
		LDA #$74 : STA $04
		LDY.w !lightypos : STY $04
		LDA #$21 : STA $04
		LDX #$20 : STX $04
		LDA #$7C : STA $04
		STY $04
		LDA #$22 : STA $04
		STX $04
		REP #$20
		LDA #$0100 : STA $02
		SEP #$20
		LDA #$0A : STA $04
		PLD : RTS

	.windowtable
		db $01,$00,$FF
		db $00,$40,$C0
		db $01,$FF,$01
		db $00

EV_SZS3:
	JSR EXECUTESUBEV
	dw .init
	dw MOSAIC_FADEIN
	dw .main
	dw .main2
	dw .main3
	dw MOSAIC_FADEOUT

	.init
		STZ !tilesize
		LDA #$02 : STA !lineclear_start
		REP #$20
		LDA #$3C38 : STA !layer3map
		STZ !layer1y
		STZ !layer2xoff
		STZ !layer2yoff
		STZ !layer3x : STZ !layer3xoff
		STZ !layer3y : STZ !layer3yoff
		STZ !layer4x
		STZ !layer4y
		STZ !lineclear_addr1
		LDA #$0800 : STA !lineclear_end1
		ASL : STA !lineclear_addr2
		LDA #$1800 : STA !lineclear_end2
		LDA #$7FFF : STA !color+($01*2)
		STZ !color
		PEA !color+($90*2) : JSR COLOR_UPLOAD
		PEA !color+($94*2) : PEA !color+($40*2) : SEC : JSR COLOR_UPLOAD
		LDA !color+($08*2) : STA !color+($22*2)
		LDA !color+($09*2) : STA !color+($23*2)
		LDA !color+($0C*2) : STA !color+($26*2)
		LDA !color+($0D*2) : STA !color+($27*2)
		STZ !color+($09*2) : STZ !color+($25*2)
		SEP #$21
		STZ !cgadsub
		INC !subevent
		LDA #$80 : STA !fadetimer
		LDA #$08 : STA !subscr
		LDA #$76 : STA !lightypos
		BRA .main
	.main3
		STZ !cgwsel
		LDA #$66 : STA !layer12gfx
		LDA #$80 : STA !layer1y
		LDA #$5F : STA !windowtable
		LDA #$20 : STA !windowtable+3
		STZ !layer1x
		REP #$20 : STZ !color : SEP #$20
	.main
		LDA #$08 : STA !layer1map
		LDA #$01 : STA !mainscr
		DEC !fadetimer
		BNE +
		INC !subevent
		+
		RTS
	.main2
		LDA #$40 : STA !cgwsel
		REP #$20 : LDA #$7FFF : STA !color : SEP #$20
		LDA #$2F : STA !windowtable
		LDA #$80 : STA !windowtable+3
		LDA #$FF : STA !windowtable+1
		STZ !windowtable+2
		LDA #$44 : STA !layer12gfx
		LDA #$0C : STA !layer1map : STA !layer2map
		LDA #$17 : STA !mainscr
		LDA #$20 : STA !layer1x
		LDA #$D0 : STA !layer1y : STA !layer2y
		LDA #$A0 : STA !layer2x
		LDA !fadetimer
		SEC : SBC #$20
		CMP #$60
		BCS +
		LDA !frame
		AND #$03
		BNE +
		INC !lightypos
		+
		DEC !fadetimer
		BNE +
		INC !subevent
		LDA #$80 : STA !fadetimer
		BRA .main3
		+
		RTS

;---------------------------------------------------------------------------

NMI_EV_ARAK:
	JSR EXECUTESUBEV
	dw .init
	dw INTERNATIONAL_RETURN
	dw NMI_EV_ARAK_NAMES
	dw NMI_EV_ARAK_NAMES
	dw INTERNATIONAL_RETURN

	.init
		STZ !hdmareg
		REP #$20
		STZ $2123
		STZ $212E
		SEP #$20
		PEA.w arak_fish
		JSR !stripedecomp
		PEA.w arak_skyline
		JSR !stripedecomp
		RTS

EV_ARAK:
	JSR EXECUTESUBEV
	dw .init
	dw MOSAIC_FADEIN
	dw .main
	dw .main2
	dw MOSAIC_FADEOUT

	.init
		REP #$21
		LDA #$1001 : STA !layer1map
		LDA #$1424 : STA !layer3map
		LDA #$6665 : STA !layer12gfx
		STZ !layer1y
		STZ !layer2y
		STZ !color+($41*2)
		PEA !color+(2*$7C) : JSR COLOR_UPLOAD
		LDA #$0018 : STA !bgcolor
		LDA #$041F : STA !location_to_DMA
		SEP #$20
		STZ !renderingname
		LDA #$90/2 : STA !fadetimer
		LDA #$20 : STA !hdmareg
		LDA #$0F : STA !mainscr
		STZ !subscr
		INC !subevent
	.main
		JSR EV_ARAK_NAMES
		LDA !frame
		LSR : BCS +
		INC !layer2x
		;AND #$01 : BEQ +
		REP #$20
		DEC !layer1x
		SEP #$20
		+
		LDA #$6C
		ADC #$00
		STA !orig_grad
		RTS
	.main2
		LDA !frame
		AND #$07 : BNE +
		DEC !fadetimer
		BNE +
		INC !subevent
		REP #$20
		INC !creditsindex
		SEP #$20
		RTS
		+
		BRA .main

;---------------------------------------------------------------------------

NMI_EV_SZS4:
	JSR EXECUTESUBEV
	dw INTERNATIONAL_RETURN
	dw INTERNATIONAL_RETURN
	dw .main
	dw .main2
	dw INTERNATIONAL_RETURN

	.main
		JSR LINE_CLEAR
		STZ $2115
		LDX #$7E : STX $4314
		LDY #$02
		REP #$30
		LDA #$29A7 : STA $2116
		LDA #$1800 : STA $4310
		LDA #.script :  STA $4312
		LDX #$0012 : STX $4315
		SEP #$10
		STY $420B
		REP #$10
		LDA #$29C7 : STA $2116
		LDA #.script+18 : STA $4312
		STX $4315
		SEP #$30
		STY $420B
		RTS
	.main2
		JSR LINE_CLEAR
		STZ $2115 : STZ $00
		LDX #$7E : STX $4314
		LDY #$02
		REP #$30
		LDA #$29A7 : STA $2116
		LDA #$1808 : STA $4310
		STZ $4312
		LDX #$0012 : STX $4315
		SEP #$10
		STY $420B
		REP #$10
		LDA #$29C7 : STA $2116
		STZ $4312
		STX $4315
		SEP #$30
		STY $420B
		RTS

	.script
		db "And now, a message"
		db " from Nintendo... "

EV_SZS4:
	JSR EXECUTESUBEV
	dw .init
	dw MOSAIC_FADEIN
	dw .main
	dw .main2
	dw MOSAIC_FADEOUT

	.init
		STZ !hdmareg
		LDA #$03 : STA !lineclear_start
		REP #$21
		STZ !lineclear_addr1
		LDA #$0800 : STA !lineclear_end1
		ASL : STA !lineclear_addr2
		ASL : STA !lineclear_addr3
		LDA #$1800 : STA !lineclear_end2
		LDA #$2800 : STA !lineclear_end3
		LDA #$4666 : STA !layer12gfx
		LDA #$1800 : STA !layer1map
		LDA #$3028 : STA !layer3map
		LDA #$0C02 : STA !mainscr
		PEA !color+($94*2) : JSR COLOR_UPLOAD
		PEA !color+($8C*2) : PEA !color+($44*2) : SEC : JSR COLOR_UPLOAD
		SEP #$20
		LDA #$02 : STA !cgadsub
		LDA #$C0 : STA !fadetimer
		INC !subevent
	.main
		JSR EV_SZS1_main
		DEC !fadetimer
		BNE +
		INC !subevent
		LDA #$2C : STA !layer3map
		STZ !mainscr
		LDA #$04 : STA !subscr
		STZ !color : STZ !color+1
		+
		RTS

	.main2
		JSR EV_SZS1_main
		DEC !fadetimer
		BNE +
		INC !subevent
		+
		RTS

;---------------------------------------------------------------------------

NMI_EV_HIDA:
	JSR EXECUTESUBEV
	dw .init
	dw INTERNATIONAL_RETURN
	dw NMI_EV_HIDA_NAMES
	dw NMI_EV_HIDA_NAMES
	dw INTERNATIONAL_RETURN

	.init
		PEA.w hida_tone
		JSR !stripedecomp
		REP #$20
		LDA #$2103 : STA $4360 : STA $4370
		LDA #!hida_table : STA $4362
		LDA #!hida_table2 : STA $4372
		SEP #$20
		STZ $4364 : STZ $4374
		LDA #$C0 : STA !hdmareg
		RTS

EV_HIDA:
	JSR EXECUTESUBEV
	dw .init
	dw MOSAIC_FADEIN
	dw .main
	dw .main2
	dw MOSAIC_FADEOUT

	.init
		REP #$20
		LDA #$0400 : STA !layer1map
		LDA #$1410 : STA !layer3map
		STZ !layer1y
		STZ !layer1x
		STZ !layer2x
		STZ !layer2y
		STZ !color+2
		STZ !color+3
		LDA #$0E01 : STA !mainscr
		LDA #$7FFF : STA !bgcolor
		STA !color+($41*2)
		LDA !color+($04*2) : STA !color+($03*2) : STA !color+($23*2)
		LDA #$0380 : STA !location_to_DMA
		SEP #$20
		STZ !renderingname
		INC !subevent
		LDA #$40 : STA !cgadsub
		LDA #$90/2 : STA !fadetimer
		RTS
	.main
		JSR EV_HIDA_NAMES
		LDA !frame
		AND #$01
		STA !layer3xoff
		STA !layer3yoff
		LDA !frame
		LSR : BCC ++
		INC !layer1y
		INC !layer2y
		LDA !hida_table
		DEC A
		BNE +
		TAX : LDY #$1D
		REP #$20
		LDA !hida_table+3 : PHA
		-
		LDA !hida_table+8,x
		STA !hida_table+3,x : STA !hida_table2+3,x
		INX #5
		DEY : BPL -
		PLA : STA !hida_table+3,x : STA !hida_table2+3,x
		SEP #$20
		LDA #$10
		+
		STA !hida_table
		STA !hida_table2
		++
		RTS
	.main2
		LDA !frame
		AND #$07 : BNE +
		DEC !fadetimer
		BNE +
		INC !subevent
		REP #$20
		INC !creditsindex
		SEP #$20
		RTS
		+
		BRA .main

		.hdmatable
			dw $18DD,$0D1D,$099E,$061E,$069E,$031F,$037F,$03DF
			dw $07BB,$0B98,$0F55,$0F33,$12EF,$16CC,$1E89,$2244
			dw $31E2,$4182,$5521,$68C1,$7861,$7445,$6C48,$642C
			dw $5C30,$5813,$5015,$4837,$3C3A,$305C,$249D
			db $00

;---------------------------------------------------------------------------

NMI_EV_SZS5:
	JSR EXECUTESUBEV
	dw INTERNATIONAL_RETURN
	dw INTERNATIONAL_RETURN
	dw .main
	dw INTERNATIONAL_RETURN

	.main
		JSR LINE_CLEAR

	.linegen
		STZ $2115
		LDA #$7E : STA $4314
		STZ $00

		LDY #$02
		REP #$20
		LDA #$2983 : STA $2116
		LDA #$1808 : STA $4310
		STZ $4312
		LDA #$001A : STA $4315
		STY $420B
		STA $4315
		LDA #$29A3 : STA $2116
		STY $420B
		SEP #$20

		STZ $4310

		LDA !fadetimer
		BEQ .end
		CMP #$C0
		BCS .line1
		CMP #$80
		BCS .line2

		.line3
		LDA #$01 : TSB !mainscr
		REP #$20
		LDA #$2985 : STA $2116
		LDA #.script3 : STA $4312
		LDA #$0016 : STA $4315
		STY $420B
		STA $4315
		LDA #$29A5 : STA $2116
		LDA #.script3+22 : STA $4312
		STY $420B
		SEP #$20
		BRA .skip

		.line2
		REP #$20
		LDA #$29A8 : STA $2116
		LDA #.script2 : STA $4312
		LDA #$000F : STA $4315
		STY $420B
		SEP #$20
		BRA .skip

		.line1
		REP #$20
		LDA #$29A3 : STA $2116
		LDA #.script1 : STA $4312
		LDA #$001A : STA $4315
		STY $420B
		SEP #$20
		BRA .skip

		.end
		INC !subevent

		.skip
		RTS


		table ascii.tbl
	.script1
		db "PEACH WAS NOT IN THE HACK!"
	.script2
		db "THIS IS HERESY!"
	.script3
		db "Here, enjoy her before"
		db "Lightvayne finds this."
		cleartable

EV_SZS5:
	JSR EXECUTESUBEV
	dw .init
	dw MOSAIC_FADEIN
	dw .main
	dw MOSAIC_FADEOUT

	.init
		STZ !hdmareg
		LDA #$03 : STA !lineclear_start
		REP #$21
		STZ !lineclear_addr1
		LDA #$0800 : STA !lineclear_end1
		ASL : STA !lineclear_addr2
		ASL : STA !lineclear_addr3
		LDA #$1800 : STA !lineclear_end2
		LDA #$2800 : STA !lineclear_end3
		LDA #$4664 : STA !layer12gfx
		LDA #$181C : STA !layer1map
		LDA #$3428 : STA !layer3map
		LDA #$0C02 : STA !mainscr
		STZ !layer1y
		STZ !layer3xoff
		STZ !layer3yoff
		PEA !color+($98*2) : JSR COLOR_UPLOAD
		LDA #$7FFF : STA !color+($01*2)
		SEP #$20
		LDA #$02 : STA !cgadsub
		LDA #$FF : STA !fadetimer
		INC !subevent
	.main
		JSR EV_SZS1_main
		LDA !frame
		AND #$01
		STA !layer1y
		LSR : BCS +
		DEC !fadetimer
		+
		RTS

;---------------------------------------------------------------------------

NMI_EV_MARI:
	JSR EXECUTESUBEV
	dw .init
	dw .fade
	dw .main
	dw .main
	dw INTERNATIONAL_RETURN

	.init
		REP #$20
		LDA #$0F42 : STA $4330
		LDA #.layer2xtable : STA $4332

		LDA #$3200 : STA $4320
		LDA #!mari_table : STA $4322
		SEP #$20
		LDA #$7E : STA $4324 : STA $4334 : STA $4337
		LDA #$0C : STA !hdmareg
		PEA.w mari_cake
		JSR !stripedecomp
		PEA.w mari_moon
		JSR !stripedecomp
		PEA.w mari_pyramid
		JSR !stripedecomp
	.fade
	.main
		JSR NMI_EV_MARI_NAMES
		LDA !frame
		LSR
		LDA #$7F
		ADC #$00
		STA !mari_table

	.spriteupload
		STZ $4314
		REP #$20
		STZ $2102
		LDA #$0400 : STA $4310
		LDA #!oam : STA $4312
		LDA #$0038 : STA $4315
		LDX #$02 : STX $420B
		LDA #$0100 : STA $2102
		LDA #!oam+$0100 : STA $4312
		LDA #$0004 : STA $4315
		STX $420B
		SEP #$20
		RTS

	.layer2xtable
		db $40 : dw .layer2xtable+6
		db $01 : dw !layer2x
		db $00

EV_MARI:
	JSR EXECUTESUBEV
	dw .init
	dw MOSAIC_FADEIN
	dw .main
	dw .main2
	dw MOSAIC_FADEOUT

	.init
		STZ !cgadsub
		REP #$21
		STZ !layer1x : STZ !layer1x
		STZ !layer2x : STZ !layer2y
		STZ !layer2xoff : STZ !layer2yoff
		STZ !layer3x : STZ !layer3y
		STZ !layer3xoff : STZ !layer3yoff
		STZ !layer4x : STZ !layer4y
		LDA #$6666 : STA !layer12gfx
		LDA #$1001 : STA !layer1map
		LDA #$1421 : STA !layer3map
		LDA #$0817 : STA !mainscr

		PEA !color+($8C*2) : JSR COLOR_UPLOAD
		SEC : PEA !color+($A4*2) : PEA !color+($20*2) : JSR COLOR_UPLOAD
		SEC : PEA !color+($A8*2) : PEA !color+($24*2) : JSR COLOR_UPLOAD
		SEC : PEA !color+($A0*2) : PEA !color+($28*2) : JSR COLOR_UPLOAD
		SEC : PEA !color+($9C*2) : PEA !color+($40*2) : JSR COLOR_UPLOAD
		SEC : PEA !color+($AC*2) : PEA !color+($44*2) : JSR COLOR_UPLOAD
		SEC : PEA !color+($83*2) : PEA !color+($64*2) : JSR COLOR_UPLOAD
		STZ !color : STZ !bgcolor
		LDA #$010F : STA !kirbyxpos
		LDA #$00FF : STA !kirbytimer
		SEP #$20
		STZ !kirbyframe
		INC !subevent
	.main
		JSR EV_MARI_NAMES
		LDA !frame
		AND #$03 : BNE +
		REP #$20
		INC !layer1x
		SEP #$20
		+
		-
		LDA !frame
		LSR : BCS +
		INC !layer2x
		REP #$20
		DEC !kirbyxpos
		SEP #$20
		AND #$03 : BNE +
		REP #$20
		INC !layer3x
		SEP #$20
		+
		JSR .spritetest
		RTS
	.main2
		DEC !fadetimer
		BNE -
		LDA #$10 : TRB !mainscr
		INC !subevent
		RTS

	.spritetest

	;mario values
		LDA !marioframe : TAX
		LSR : EOR #$FF
		SEC : ADC #$88
		STA .spriteY
		CLC : ADC #$10
		STA .spriteY+1
		TXA : INC #2 : ASL
		STA .spriteT+1

	;yoshi values
		LDA !frame
		LSR #4
		PHP
		LDA #$88
		ADC #$00
		STA .spriteY+4
		CLC : ADC #$10
		STA .spriteY+5
		PLP
		TDC : ROL #2
		ADC #$2A
		STA .spriteT+5

	;peach values
		LDA .spriteY
		SEC : SBC #$06
		STA .spriteY+2
		CLC : ADC #$10
		STA .spriteY+3

	;mario, peach, yoshi upload
		LDY #$00 : TYX
		LDA #$05 : STA $00
		-
		LDA .spriteX,x
		STA !oamx,y
		LDA .spriteY,x
		STA !oamy,y
		LDA .spriteT,x
		STA !oamt,y
		LDA .spriteP,x
		STA !oamp,y
		INY #4 : INX
		DEC $00 : BPL -

	;eggs upload
		LDA #$05 : STA $00
		LDA !marioframe
		AND #$02
		STA $01
		LDX #$90
		-
		TXA : STA !oamx,y
		SEC : SBC #$12 : TAX
		LDA #$97
		CLC : ADC $01
		STA !oamy,y
		LDA $01 : EOR #$02 : STA $01
		LDA #$2E : STA !oamt,y
		LDA #$36 : STA !oamp,y
		INY #4 : DEC $00 : BPL -

		LDA #$97 : STA $00
		LDA !kirbypointer
		LSR : BEQ +
		BCC .mov

		.ded
		LDA #$E1 : STA $00
		BRA +

		.mov
		CMP #$02 : BEQ .ded
		TXA : STA $02
		LDA !frame : LSR
		LDA !layer2x
		EOR #$FF
		ADC $02
		ADC #$14
		TAX
		STZ $01

		+
		TXA : STA !oamx,y
		LDA $00
		CLC : ADC $01
		STA !oamy,y
		LDA #$2E : STA !oamt,y
		LDA #$36 : STA !oamp,y
		INY #4

	;kirby upload
		LDA !kirbypointer
		LSR : BEQ +
		BCC .state3
		BRA .state4
		+
		BCS .state2

		.state1
		LDX #$10
		BRA .kirbywait

		.state2
		REP #$20
		INC !kirbyxpos
		SEP #$20
		LDX #$10
		BRA .kirbywait

		.state3
		CMP #$02 : BEQ .state5
		LDA #$01 : STA !kirbyframe
		LDX #$30
		BRA .kirbywait

		.state4
		LDA #$02 : STA !kirbyframe
		LDX #$00
		BRA .kirbywait

		.state5
		LDA #$E1 : STA !oamy,y
		RTS

		.kirbygfx
		LDA !kirbyxpos
		STA !oamx,y
		LDA #$98 : STA !oamy,y
		LDA !kirbyframe : ASL
		ADC #$0A : STA !oamt,y
		LDA #$20 : STA !oamp,y

	;owari
		REP #$20
		LDA #$AAAA
		STA !oam+$100
		STA !oam+$102
		SEP #$20
		LDA !kirbyhighx
		AND #$01
		ASL #2
		ORA #$AA
		STA !oam+$103
		RTS

		.kirbywait
		LDA !frame
		LSR : BCS +
		DEC !fadetimer
		BNE +
		STX !fadetimer
		INC !kirbypointer
		+
		BRA .kirbygfx

	.spriteX
		db $D0,$D0			;mario
		db $A4,$A4			;peach
		db $B2,$A8			;yoshi
	.spriteY
		db $88,$98			;mario
		db $82,$92			;peach
		db $88,$98			;yoshi
	.spriteT
		db $02,$04			;mario
		db $24,$26			;peach
		db $28,$2A			;yoshi
	.spriteP
		db $30,$30			;mario
		db $36,$36			;peach
		db $36,$36			;yoshi

;---------------------------------------------------------------------------

NMI_EV_SZS6:
	JSR EXECUTESUBEV
	dw INTERNATIONAL_RETURN
	dw INTERNATIONAL_RETURN
	dw .main

	.main
		STZ $2115
		STZ $00
		LDA #$7E : STA $4314
		LDY #$02
		REP #$20
		LDA #$1800 : STA $4310 : TAX
		LDA #$29A5 : STA $2116
		LDA #.script : STA $4312
		LDA #$0016 : STA $4315

		LDA !frame : BPL +
		DEC !frame
		LDX #$08 : STX $4310
		STZ $4312
		STY $420B

		LDX #$00 : STX $4310
		INX : STX $2115
		LDA #$28CF : STA $2116
		LDA #.scripttop : STA $4312
		LDA #$0010 : STA $4315
		STY $420B

		STA $4315
		LDA #$28D0 : STA $2116
		LDA #.scriptbottom : STA $4312

		+
		STY $420B
		SEP #$20
		RTS

	.script
		table ascii.tbl
		db "Thank you for playing!"
		cleartable
	.scripttop
		db $EE,$FE,$00,$00,$84,$85,$88,$89,$00,$00,$8C,$8D,$00,$00,$EE,$FE
	.scriptbottom
		db $EF,$FF,$00,$00,$86,$87,$8A,$8B,$00,$00,$8E,$8F,$00,$00,$EF,$FF

EV_SZS6:
	JSR EXECUTESUBEV
	dw .init
	dw MOSAIC_FADEIN
	dw EV_SZS1_main

	.init
		STZ !hdmareg
		REP #$21
		LDA #$4664 : STA !layer12gfx
		LDA #$181C : STA !layer1map
		LDA #$3C28 : STA !layer3map
		LDA #$0C02 : STA !mainscr
		STZ !layer3x
		LDA !color+($1C*2) : STA !bgcolor
		LDA !color+($2C*2) : STA !color+($61*2)
		LDA !color+($3C*2) : STA !color+($62*2)
		LDA !color+($4C*2) : STA !color+($63*2)
		LDA #$7FFF : STA !color+($41*2)
		SEP #$20
		LDA #$02 : STA !cgadsub
		INC !subevent
		RTS

;---------------------------------------------------------------------------
; SUBROUTINES
;---------------------------------------------------------------------------
	
	COLOR_UPLOAD:		;PEA src, dest. Carry clear: layer 4, dest not needed
		PLA : STA $00
		LDY #$06
		BCS +
		-
		LDA ($01,s),y
		STA !color+(2*$60),y
		DEY #2 : BNE -
		STA !bgcolor
		--
		PLA : PEI ($00) : RTS
		+
		-
		LDA ($03,s),y
		STA ($01,s),y
		DEY #2 : BNE -
		PLA : BRA --

	MARIO_ANI_INIT:		;input: X = Xpos, Y = Ypos
		PHD : PEA $2100 : PLD
		STZ $02
		STZ $03
		STX $04
		STY $04
		LDA #$02 : STA $04
		LDA #$20 : STA $04
		STX $04
		TYA : CLC : ADC #$10 : STA $04
		LDA #$08 : STA $04
		LDA #$20 : STA $04
		STZ $02
		LDA #$01 : STA $03
		LDA #$0A : STA $04
		PLD : RTS

	MARIO_ANI_MAIN:
		PHD : PEA $2100 : PLD
		STZ $02
		STZ $03
		STX $04
		LDA.w !marioframe
		CMP #$02 : BNE +
		DEY
		+
		STY $04
		LDA #$02 : STA $04
		LDA #$20 : STA $04
		STX $04
		TYA : CLC : ADC #$10 : STA $04
		LDA.w !marioframe
		INC #2 : ASL
		STA $04
		LDA #$20 : STA $04
		PLD : RTS

	EXECUTESUBEV:
	LDA !subevent
	EXECUTEPTR:
		;ASL : TAX
		;REP #$20
		;PLA : INC
		;STA .lbl+1
		;SEP #$20
		;.lbl
		;JMP ($0000,x)
		;ASL : TAY : INY : REP #$20
		;LDA ($01,s),y : DEC : STA $01,s
		;SEP #$20 : RTS

		ASL : TAY : INY
		REP #$20
		PLA : STA !subpoint
		LDA [!subpoint],y
		DEC : PHK : PHA
		SEP #$20
		RTL

	MOSAIC_FADEIN:
		LDA !frame
		LSR : BCC ++
		LDA !mosaic
		SBC #$10
		CMP #$10
		BCS +
		INC !subevent
		+
		STA !mosaic
		++
		RTS

	MOSAIC_FADEOUT:
		LDA !frame
		LSR : BCC ++
		LDA !mosaic
		ADC #$0F
		CMP #$F0
		BCC +
		INC !event
		STZ !subevent
		+
		STA !mosaic
		++
		RTS

	RANDOM:		;X must have values-1, will return with random in A
		PHB : TDC : PHA : PLB
		JSR TRUERANDOM
		CPX #$FF
		BNE +
		LDA !randgen1
		BRA ++
		+
		INX
		LDA !randgen1
		STA $211B
		STZ $211B
		STX $211C
		LDA $2135
		++
		PLB : RTS

	TRUERANDOM:
		LDA $002137
		LDA $00213F
		LDA $00213C
		ADC !frame
		ADC !randgen1
		EOR !randgen1
		ADC $00
		STA !randgen1
		ORA !frame
		EOR !randgen1
		ADC !randgen2
		STA !randgen2
		RTS

	LINE_CLEAR:
		LDA !lineclear_start
		BEQ .end
		DEC : ASL : TAX
		LDA #$80 : STA $2115
		STZ $4314
		STZ $00
		REP #$21
		LDA !lineclear_addr1,x : STA $2116
		LDA #$1809 : STA $4310
		STZ $4312
		LDA #$0040 : STA $4315
		LDY #$02 : STY $420B
		LDA !lineclear_addr1,x
		ADC #$0020
		CMP !lineclear_end1,x
		BCC +
		DEC !lineclear_start
		+
		STA !lineclear_addr1,x
		SEP #$20
		.end
		RTS

	HEXDEC_LONG:	;in: 16bit A | out: ones in X, tens in Y, rest in A
		PHD : PEA $4200 : PLD
		STA $04
		LDY #$0A
		STY $06
		JSR +
		LDX $16
		LDA $14
		STA $04
		STY $06
		JSR +
		LDY $16
		LDA $14
		PLD : RTS
		+ JSR +
		+ RTS

	HEX_TO_TEXT:	;in: 8bit A | out: low nibble in B, high nibble in A (I:1F, O:F|1)
		PHA
		AND #$0F
		CMP #$0A
		BCC +
		ADC #$06
		+
		ADC #$30
		XBA : PLA
		LSR #4
		CMP #$0A
		BCC +
		ADC #$06
		+
		ADC #$30
		RTS

	CIRCLEY:
		LDA $05 : LSR
		LDX $04
		LDA !sincostable,x
		STA $00211B
		TDC
		STA $00211B
		LDA $06
		STA $00211C
		LDA $002135
		BCC +
		EOR #$FF : INC A
		+
		STA $08
		RTS

	CIRCLEX:
		LDA $04
		CLC : ADC #$80
		TAX
		LDA $05
		ADC #$00 : LSR
		LDA !sincostable,x
		STA $00211B
		TDC
		STA $00211B
		LDA $06
		STA $00211C
		LDA $002135
		BCC +
		EOR #$FF : INC A
		+
		STA $07
		RTS

	HDMA_SCROLL:
		LDX #$00 : TXY
		REP #$20
		LDA #$1303
		STA $004340
		LDA #!scrolltable
		STA $004342
		SEP #$20
		LDA #$7E : STA $004344
		LDA #$10 : STA !hdmareg

		LDA !frame
		LSR #2
		STA $00

		.loop
			LDA #$06
			STA !scrolltable,x
			TYA
			ADC $00
			AND #$0F
			PHY : TAY

			LDA .wavetable,y
			CLC : ADC !layer4x
			STA !scrolltable+1,x
			LDA !layer4x+1
			ADC #$00
			STA !scrolltable+2,x

			LDA .wavetable,y
			CLC : ADC !layer4y
			STA !scrolltable+3,x
			LDA !layer4y+1
			ADC #$00
			STA !scrolltable+4,x

			PLY
			CPY #$25
			BPL .end
			INX #5
			INY
			BRA .loop

		.end
			STZ !scrolltable+5,x
			RTS

		.wavetable
			db $00,$01,$02,$03,$04,$05,$06,$07
			db $07,$06,$05,$04,$03,$02,$01

;---------------------------------------------------------------------------
; TABLES
;---------------------------------------------------------------------------

	ORIG_PAL:
		incbin creditspal.bin:0-180
	orig_grad:
		db $2D : dw $290C
		db $02 : dw $2D0C
		db $03 : dw $2D2C
		db $02 : dw $312C
		db $01 : dw $312B
		db $01 : dw $314B
		db $05 : dw $354B
		db $03 : dw $396B
		db $01 : dw $396A
		db $02 : dw $3D6A
		db $03 : dw $3D8A
		db $02 : dw $418A
		db $01 : dw $41AA
		db $01 : dw $41A9
		db $04 : dw $45A9
		db $01 : dw $45C9
		db $04 : dw $49C9
		db $01 : dw $4DC9
		db $04 : dw $4DE8
		db $02 : dw $51E8
		db $02 : dw $5208
		db $01 : dw $5608
		db $03 : dw $5607
		db $04 : dw $5A27
		db $02 : dw $5E27
		db $01 : dw $5E47
		db $02 : dw $5E46
		db $01 : dw $6B5A
		db $01 : dw $5310
		db $01 : dw $4F10
		db $01 : dw $4F0F
		db $01 : dw $4AEF
		db $01 : dw $4AEE
		db $01 : dw $4AED
		db $01 : dw $46CD
		db $01 : dw $46CC
		db $02 : dw $42AB
		db $01 : dw $3E8A
		db $01 : dw $3E69
		db $01 : dw $3A69
		db $01 : dw $3A48
		db $02 : dw $3627
		db $03 : dw $3606
		db $02 : dw $31E6
		db $02 : dw $31C5
		db $02 : dw $31A5
		db $01 : dw $3185
		db $01 : dw $2D85
		db $01 : dw $2D84
		db $02 : dw $2D64
		db $02 : dw $2D44

	sincostable:
		db $00,$03,$06,$09,$0C,$0F,$12,$15,$19,$1C,$1F,$22,$25,$28,$2B,$2E
		db $31,$35,$38,$3B,$3E,$41,$44,$47,$4A,$4D,$50,$53,$56,$59,$5C,$5F
		db $61,$64,$67,$6A,$6D,$70,$73,$75,$78,$7B,$7E,$80,$83,$86,$88,$8B
		db $8E,$90,$93,$95,$98,$9B,$9D,$9F,$A2,$A4,$A7,$A9,$AB,$AE,$B0,$B2
		db $B5,$B7,$B9,$BB,$BD,$BF,$C1,$C3,$C5,$C7,$C9,$CB,$CD,$CF,$D1,$D3
		db $D4,$D6,$D8,$D9,$DB,$DD,$DE,$E0,$E1,$E3,$E4,$E6,$E7,$E8,$EA,$EB
		db $EC,$ED,$EE,$EF,$F1,$F2,$F3,$F4,$F4,$F5,$F6,$F7,$F8,$F9,$F9,$FA
		db $FB,$FB,$FC,$FC,$FD,$FD,$FE,$FE,$FE,$FF,$FF,$FF,$FF,$FF,$FF,$FF
		db $FF

	credits_names:
		incsrc text.asm

;---------------------------------------------------------------------------
; CREDITS
;---------------------------------------------------------------------------

EV_ORIG_NAMES:
	REP #$10
	LDY !creditsindex
	LDA !renderingname
	BPL .renderingname
	LDA (!credits),y
	BEQ .linebreak
	CMP #$50
	BCC .tinyletters

	LDA !character_to_DMA
	BEQ .linebreak
	STZ !character_to_DMA
	LDA (!credits),y
	SEC : SBC #$50
	STA !renderingname
	ASL
	CMP #$21 : BCC +
	LDA #$20
	+
	BRA +
	.tinyletters
	STA !renderingname
	+
	SEC : SBC #$20
	EOR #$FF : INC
	LSR
	ADC #$00
	REP #$21
	AND #$00FF
	ADC !location_to_DMA
	STA !location_to_DMA
	SEP #$20

	.renderingname
	INY
	DEC !renderingname
	BMI .prereturn
	LDA (!credits),y
	STA !line_to_DMA
	INC !start_creditDMA
	BRA .return

	.linebreak
	DEC !fadetimer
	BNE .return
	LDA #$30 : STA !fadetimer
	STA !character_to_DMA
	REP #$20
	LDA #$0280 : STA !location_to_DMA
	SEP #$20
	LDA #$80 : STA !start_creditDMA
	LDA (!credits),y
	BNE +
	INC !subevent
	INY
	+
	BRA .return

	.prereturn
	REP #$21
	LDA !location_to_DMA
	AND #$FFE0
	ADC #$0020
	STA !location_to_DMA
	SEP #$20
	DEY
	LDA (!credits),y
	INY
	CMP #$30 : BCC +
	REP #$21
	LDA !location_to_DMA
	ADC #$0020
	STA !location_to_DMA
	SEP #$20
	+

	.return
	STY !creditsindex
	SEP #$10
	RTS

NMI_EV_ORIG_NAMES:
	LDA !start_creditDMA
	BEQ .dontDMA
	BMI .clear
	STZ $2115
	REP #$20
	LDA !location_to_DMA : STA $2116
	LDX !line_to_DMA
	CPX #$99 : BEQ .underline
	STX $2118
	CPX #$30 : BCC .notbigletter
	CPX #$A0 : BCS .number
	INX : STX $2118
	ADC #$0020 : STA $2116
	INX : STX $2118
	INX : STX $2118
	INC !location_to_DMA
	.notbigletter
	INC !location_to_DMA
	SEP #$20
	STZ !start_creditDMA
	BRA .dontDMA
	.clear
	STZ $00 : STZ $2115
	REP #$20
	LDA !location_to_DMA : STA $2116
	LDA #$1808 : STA $4310
	STZ $4312
	LDX #$7E : STX $4314
	LDA #$0100 : STA $4315
	SEP #$20
	LDA #$02 : STA $420B
	STZ !start_creditDMA
	.dontDMA
	RTS

	.underline
	LDY #$00 : STY $2118
	CLC : ADC #$0020 : STA $2116
	BRA +

	.number
	CLC : ADC #$0020 : STA $2116
	TXA : CLC : ADC #$0010 : TAX
	+
	STX $2118
	BRA .notbigletter


EV_BAKE_NAMES:
	DEC !fadetimer
	BNE .lbl+1
	INC !start_creditDMA
	LDA #$72 : STA !fadetimer

	LDX #$00
	REP #$10
	STX $01
	LDA #$20 : STA $00
	.lbl
	LDY #$1160
	LDA !subevent
	CMP #$03
	BEQ +
	INC $02
	LDA #$1C : STA $00
	LDY #$141B
	+
	STY !location_to_DMA
	LDY !creditsindex
	.loop
	LDA (!credits),y
	BEQ .linebreak
	CMP #$50
	BCC .name

	.title
	CPX #$0000 : BEQ +
	JSR DEX_SIX
	STX !renderingname
	BRA .endupdate
	+
	SBC #$50
	.name
	STA !wine_to_DMA+4,x
	STZ !wine_to_DMA+5,x

	LDA $02 : BNE .vertical

	JSR MARI_BAKE_SHARED_1
	BRA .loop

	.vertical
	JSR MARI_BAKE_SHARED_3
	ASL #5
	ADC !location_to_DMA
	STA !wine_to_DMA,x
	DEC !location_to_DMA
	CPX #$0000 : BNE +
	DEC !location_to_DMA
	+
	JSR MARI_BAKE_SHARED_2
	BRA .loop

	.endupdate
	STY !creditsindex
	SEP #$10
	.noupdate
	RTS

	.linebreak
	CPX #$0000 : BEQ +
	JSR DEX_SIX : STX !renderingname
	BRA .endupdate
	+
	INY
	LDA #$D7 : STA !fadetimer
	INC $02
	LDA #$1C : STA $00
	REP #$20
	LDA #$141B
	STA !location_to_DMA
	SEP #$20
	INC !subevent
	LDA !subevent
	CMP #$04
	BNE .endupdate
	BRA .loop

NMI_EV_BAKE_NAMES:
	LDA !start_creditDMA
	BEQ .noupload
	STZ $00
	STZ $2115
	LDA #$7E : STA $4314
	REP #$20
	LDY #$02
	LDA #$1808 : STA $4310
	STZ $4312
	LDX !subevent
	CPX #$03
	BEQ +
	LDX #$01 : STX $2115
	LDX #$05
	LDA #$141B
	-
	STA $2116
	PHA
	LDA #$001C
	STA $4315
	PLA
	STY $420B
	DEC : DEX : BPL -
	BRA ++
	+
	LDA #$1160 : STA $2116
	LDA #$0100 : STA $4315
	STY $420B
	++
	LDX !renderingname
	-
	LDA !wine_to_DMA,x : STA $2116
	LDA #$1800 : STA $4310
	LDA !wine_to_DMA+2,x : STA $4312
	LDA !wine_to_DMA+4,x : STA $4315
	STY $420B
	JSR DEX_SIX : BPL -
	SEP #$20
	STZ !start_creditDMA
	.noupload
	RTS


EV_MADO_NAMES:
	LDA !layer1y
	AND #$07
	BNE .nonupdate
	LDA !renderingname
	BNE .noupdate
	INC !renderingname
	INC !start_creditDMA
	TDC
	LDX #$1F
	-
	STZ !line_to_DMA,x
	DEX : BPL -
	DEC !character_to_DMA
	BNE .noupdate
	REP #$10
	LDY !creditsindex
	LDA (!credits),y
	BEQ .linebreak
	BMI +
	CMP #$50
	BCC .worlds
	BRA ++
	+
	INC !character_to_DMA
	SEC : SBC #$50
	++
	INC !character_to_DMA
	SBC #$50
	.worlds
	INC !character_to_DMA
	SEC : SBC #$20
	EOR #$FF : DEC
	TAX
	INY
	-
	LDA (!credits),y
	STA !line_to_DMA,x
	INY : INX : CPX #$001E : BCC -
	LDA (!credits),y
	BMI +
	CMP #$50 : BCS ++
	BRA +++
	+
	INC !character_to_DMA
	++
	INC !character_to_DMA
	CPY #$0A87
	BCS +++
	INC !character_to_DMA : INC !character_to_DMA
	+++
	-
	STY !creditsindex
	SEP #$10
	.noupdate
	RTS
	.linebreak
	LDA #$03
	STA !subevent
	STZ !renderingname
	LDA #$FF : STA !character_to_DMA
	BRA -
	.nonupdate
	STZ !renderingname
	BRA .noupdate

NMI_EV_MADO_NAMES:
	LDA !start_creditDMA
	BEQ .dontDMA
	STZ $2115 : STZ $4314
	REP #$21
	LDA !location_to_DMA : STA $2116
	LDA #$1800 : STA $4310
	LDA.w #!line_to_DMA : STA $4312
	LDA #$0020 : STA $4315
	LDX #$02 : STX $420B

	LDA !location_to_DMA
	ADC #$0020
	AND #$03FF
	STA !location_to_DMA
	SEP #$20

	STZ !start_creditDMA
	.dontDMA
	RTS


EV_ARAK_NAMES:
	LDA !layer1x
	AND #$07
	BNE .noupdate
	LDA !frame
	AND #$03
	BNE .noupdate
	INC !start_creditDMA
	LDA !renderingname
	BNE .DMAupdatee
	INC !renderingname

	TDC
	LDX #$1F
	-
	STZ !line_to_DMA,x
	DEX : BPL -

	LDX #$02
	REP #$10
	LDY !creditsindex
	LDA (!credits),y
	BEQ .linebreak
	BMI .title
	CMP #$50
	BCC .name
	BRA .subtitle

	.title
	JSR .subtractlength

	.subtitle
	JSR .subtractlength

	.name
	INC !renderingname
	STA $00
	INY
	-
	LDA (!credits),y
	STA !line_to_DMA,x
	INY : INX : DEC $00 : BNE -
	JSR .DMAupdate

	.return
	STY !creditsindex
	SEP #$10

	.noupdate
	RTS

	.linebreak
	INC !subevent
	LDA #$FF : STA !renderingname
	JSR .DMAupdate
	BRA .return

	.DMAupdatee
	DEC !renderingname
	.DMAupdate
	REP #$20
	LDA !location_to_DMA
	DEC
	AND #$041F
	STA !location_to_DMA
	SEP #$20
	RTS

	.subtractlength
	INX
	SEC : SBC #$50
	INC !renderingname : INC !renderingname
	RTS

NMI_EV_ARAK_NAMES:
	LDA !start_creditDMA
	BEQ .return

	STA $2115
	STZ $4314
	STZ $00

	REP #$20
	STZ $4312
	LDA !location_to_DMA : STA $2116
	LDA #$1808 : STA $4310
	LDX !renderingname
	BNE +

	LDX #$00 : STX $4310
	LDA.w #!line_to_DMA : STA $4312

	+
	LDA #$001C : STA $4315
	LDY #$02 : STY $420B
	SEP #$20
	STZ !start_creditDMA

	.return
	RTS


EV_HIDA_NAMES:
	LDA !layer1y
	AND #$07
	BNE .noupdate
	LDA !frame
	LSR : BCS .noupdate
	INC !start_creditDMA
	LDA !renderingname
	BNE .DMAupdatee
	INC !renderingname

	TDC
	LDX #$1F
	-
	LDA #$A8
	STA !line_to_DMA,x
	LDA #$03
	STA !prop_to_DMA,x
	DEX : BPL -

	REP #$10
	LDY !creditsindex
	LDA (!credits),y
	BEQ .linebreak

	INC !renderingname
	STA $00
	SEC : SBC #$20
	EOR #$FF : INC : LSR
	TAX
	INY
	REP #$20
	LDA #$A6A7 : STA !line_to_DMA-3,x
	LDA #$4343 : STA !prop_to_DMA-3,x
	SEP #$20
	STZ !line_to_DMA-1,x
	LDA #$01 : STA !prop_to_DMA-1,x
	-
	LDA (!credits),y
	STA !line_to_DMA,x
	LDA #$01 : STA !prop_to_DMA,x
	INY : INX : DEC $00 : BNE -
	STZ !line_to_DMA,x
	STA !prop_to_DMA,x
	REP #$20
	LDA #$A7A6 : STA !line_to_DMA+1,x
	LDA #$0303 : STA !prop_to_DMA+1,x
	SEP #$20
	JSR .updatelayer2
	JSR .DMAupdate

	.return
	STY !creditsindex
	SEP #$10

	.noupdate
	RTS

	.linebreak
	INC !subevent
	LDA #$FF : STA !renderingname
	JSR .DMAupdate
	BRA .return

	.DMAupdatee
	DEC !renderingname
	.DMAupdate
	REP #$21
	LDA !location_to_DMA
	ADC #$0020
	AND #$03FF
	STA !location_to_DMA
	SEP #$20
	RTS

	.updatelayer2
	LDX #$001F
	-
	LDA !line_to_DMA,x
	CMP #$A0 : BCC +
	ADC #$0F
	+
	STA !wine_to_DMA,x
	DEX : BPL -
	-
	RTS

NMI_EV_HIDA_NAMES:
	LDA !start_creditDMA
	BEQ -

	STZ $2115
	STZ $4314
	STZ $00
	STA $01
	LDY #$02

	REP #$21
	LDA #$1800 : STA $4310
	LDA.w #!line_to_DMA : STA $02
	LDA.w #!prop_to_DMA : STA $04
	LDA.w #!wine_to_DMA : STA $06

	LDX !renderingname
	BEQ +
	STZ $02 : STZ $06
	TDC : INC : STA $04
	LDX #$08 : STX $4310
	+

	LDA !location_to_DMA : STA $2116
	LDX #$18 : STX $4311
	LDA $02 : STA $4312
	LDA #$0020 : STA $4315 : PHA
	STY $420B
	LDX #$80 : STX $2115
	LDA !location_to_DMA : STA $2116
	LDX #$19 : STX $4311
	LDA $04 : STA $4312
	LDA $01,s : STA $4315
	STY $420B

	STA $4315
	LDA $04 : STA $4312
	LDA !location_to_DMA : ADC #$0400 : STA $2116
	STY $420B
	STZ $2115
	STA $2116
	DEX : STX $4311
	LDA $06 : STA $4312
	PLA : STA $4315
	STY $420B

	SEP #$20
	STZ !start_creditDMA

	.return
	RTS


EV_MARI_NAMES:
	LDA !layer1x
	BNE .noupdate
	LDA !frame
	AND #$03
	BNE .noupdate
	INC !start_creditDMA
	LDX #$00
	STZ $01
	LDA #$20 : STA $00
	LDA !layer1x+1
	AND #$01
	EOR #$01
	ASL #2
	STA !location_to_DMA+1
	LDA #$A0 : STA !location_to_DMA
	REP #$10
	LDY !creditsindex
	.loop
	LDA (!credits),y
	BEQ .linebreak
	BPL .name

	.title
	CPX #$0000 : BEQ +
	JSR DEX_SIX
	STX !renderingname
	BRA .endupdate
	+
	SBC #$A0
	.name
	STA !wine_to_DMA+4,x
	STZ !wine_to_DMA+5,x
	JSR MARI_BAKE_SHARED_1
	BRA .loop

	.endupdate
	STY !creditsindex
	SEP #$10
	.noupdate
	RTS

	.linebreak
	JSR DEX_SIX : STX !renderingname
	LDA !fadetimer : BNE +
	LDA #$FF : STA !fadetimer
	BRA .endupdate
	+
	STZ !start_creditDMA
	INC !subevent
	BRA .endupdate

NMI_EV_MARI_NAMES:
	LDA !start_creditDMA
	BEQ .noupload
	STZ $00
	STZ $2115
	LDA #$7E : STA $4314
	LDY #$02
	LDX !renderingname
	REP #$20

	LDA !layer1x
	AND #$0100
	EOR #$0100
	ASL #2
	CLC : ADC #$00A0
	STA $2116
	LDA #$1808 : STA $4310
	STZ $4312
	LDA #$0200 : STA $4315
	STY $420B

	-
	LDA !wine_to_DMA,x : STA $2116
	LDA #$1800 : STA $4310
	LDA !wine_to_DMA+2,x : STA $4312
	LDA !wine_to_DMA+4,x : STA $4315
	STY $420B
	JSR DEX_SIX : BPL -
	SEP #$20
	STZ !start_creditDMA
	.noupload
	RTS


DEX_SIX:
	DEX #6 : RTS

MARI_BAKE_SHARED_1:
	JSR MARI_BAKE_SHARED_3
	CLC : ADC !location_to_DMA
	STA !wine_to_DMA,x
	LDA !location_to_DMA
	CLC : ADC #$0020
	CPX #$0000 : BNE +
	ADC #$001F
	+
	STA !location_to_DMA

MARI_BAKE_SHARED_2:
	TYA
	CLC : ADC !wine_to_DMA+4,x
	TAY
	INX #6
	SEP #$20
	RTS

MARI_BAKE_SHARED_3:
	REP #$21
	INY
	TYA : ADC !credits
	STA !wine_to_DMA+2,x
	LDA !wine_to_DMA+4,x
	SEC : SBC $00
	EOR #$FFFF : INC
	LSR
	RTS
