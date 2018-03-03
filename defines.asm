;-----RAM DEFINES------------------------------------------

;$00-$0F		RESERVED FOR TEMP RAM

!event = $10		;current game mode
!subevent = $11		;current sub game mode
!brightness = $12	;mirror of $2100
!frame = $13		;frame counter, increases each frame
!highframe = $14	;frame counter, high byte

!fadetimer = $15	;generic address, mainly used as timer

!layer1x = $16		;mirror of $210D
!layer1y = $18		;mirror of $210E
!layer2x = $1A		;mirror of $210F
!layer2y = $1C		;mirror of $2110
!layer3x = $1E		;mirror of $2111
!layer3y = $20		;mirror of $2112
!layer4x = $22		;mirror of $2113
!layer4y = $24		;mirror of $2114

!layer2xoff = $26	;added to layer2x
!layer2yoff = $28	;added to layer2y
!layer3xoff = $2A	;added to layer3x
!layer3yoff = $2C	;added to layer3y

!mainscr = $2E		;mirror of $212C
!subscr = $2F		;mirror of $212D
!hdmareg = $30		;mirror of $420C
!cgwsel = $31		;mirror of $2130. bit 1 gets set in NMI
!cgadsub = $32		;mirror of $2131. bits 4 & 5 get set in NMI

!tilesize = $33		;semi-mirror of $2105; lower 4 bits are ignored/cleared
!mosaic = $34		;mirror of $2106

!marioframe = $35	;alternates between 2, 1, and 0

!credits = $36		;2 bytes, location of credits_names

!subpoint = $38		;3 bytes, used by subroutine pointer. 3rd byte is always $7E

!kirbyframe = $3B
!kirbytimer = $3C
!kirbypointer = $3D
!kirbyxpos = $3E
!kirbyhighx = $3F

;$40-$46		EMPTY

!layer12gfx = $47	;mirror of $210B
!layer34gfx = $48	;mirror of $210C

!layer1map = $49	;mirror of $2107
!layer2map = $4A	;mirror of $2108
!layer3map = $4B	;mirror of $2109
!layer4map = $4C	;mirror of $210A

!bgcolor = $4D		;2 bytes, fixed color in BGR555. converted to $2132 in NMI

!lineclear_start = $4F	;1 byte, 0 = skip, 1 = 1 addr, 2 = 2 addrs , 3 = 3 addrs
!lineclear_addr1 = $50	;2 bytes, 1st VRAM address to write 32 zero-bytes to
!lineclear_addr2 = $52	;2 bytes, 2nd VRAM address to write 32 zero-bytes to
!lineclear_addr3 = $54	;2 bytes, 3rd VRAM address to write 32 zero-bytes to
!lineclear_end1 = $56	;2 bytes, 1st VRAM address to stop writing zero-bytes to
!lineclear_end2 = $58	;2 bytes, 2nd VRAM address to stop writing zero-bytes to
!lineclear_end3 = $5A	;2 bytes, 3rd VRAM address to stop writing zero-bytes to

!lightxpos = $5C	;x position of light sprite from madoka scene
!lightypos = $5D	;y position of light sprite from madoka scene (and y pos of pantsu)

!randgen1 = $5E		;used by random number generator
!randgen2 = $5F		;used by random number generator

!windowtable = $60	;10 bytes, HDMA window table used in animation intermission

;$70-$8F		EMPTY

!wine_to_DMA = $90	;32 bytes, semicopy of !line_to_DMA, used during hidamari scene

!prop_to_DMA = $B0	;32 bytes, the property bytes for !line_to_DMA

!line_to_DMA = $D0	;32 bytes, bytes to DMA. Sometimes only 1st byte is used

;$F0-$F8		EMPTY

!renderingname = $F9	;1 byte, length of name currently uploading
!character_to_DMA = $FA	;1 byte, misleading define. acts as a sort of flag
!location_to_DMA = $FB	;2 bytes, location in VRAM to DMA name to
!start_creditDMA = $FD	;1 byte, 0 = dont upload, 1 = upload, neg = clear screen
!creditsindex = $FE	;2 bytes, index to list of names



;$0100-$01FF		RESERVED FOR STACK

!sincostable = $0200	;257 bytes, but last byte is overwritten/not needed

!orig_grad = $0300	;256 bytes, gradient from first scene. reused in arakawa scene

!color = $0400		;512 bytes, entire palette. uploaded to CGRAM in NMI

!scrolltable = $0600	;256 bytes reserved, HDMA scroll table used in madoka scene

!oam = $0700		;512 bytes reserved, unofficial OAM table. no high table reserved
!oamx = !oam+0
!oamy = !oam+1
!oamt = !oam+2
!oamp = !oam+3

!hida_table = $0900	;256 bytes reserved, HDMA color table used in hidamari scene
!hida_table2 = $0A00	;256 bytes reserved, HDMA color table used in hidamari scene

!mari_table = $0B00	;256 bytes reserved, HDMA gradient used in maria holic scene

;$0C00-$1EFF		EMPTY

!SPC0 = $1DF9
!SPC1 = $1DFA
!SPC2 = $1DFB
!SPC3 = $1DFC

!stripedecomp = $1F00	;256 bytes reserved, stripe image uploader