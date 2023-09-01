
;---------------------------------------------------------------------
; Copy in a region of the level into the tilemap memory
; using DMA   
; 
; Required labels
;   tilemap             location of source tilemap data
;   START_OF_TILEMAP    location of tilemap display memory
;   MAPLOCATION.X       X offset for tilemap in bytes
;   MAPLOCATION.Y       Y offset for tilemap in rows
copyTilemapDma:
    ld HL,tilemapDmaProgram
.rowloop
	ld hl,tilemap
	ld DE, START_OF_TILEMAP
	ld a, (MAPLOCATION.Y)
	cp 0
	jr z,.copyRows			            ; we're done if Y is zero
.calcyoffset:
	add hl,160
	dec A 
	jr nz,.calcyoffset   ; hl now contains offset to tilemap row
.copyRows
    ; loop screen height times (32) to load tilemap rows
    ; calc x offset for each row
	ld bc,(MAPLOCATION.X)
	add hl,bc           ; hl now contains correct offset for row
    ld a,%1'00000'11 : out ($6b),a    ; WR6 - disable DMA
    ld a,%0'0'01'0'100 : out ($6b),a  ; WR1 - A incr., A=memory
    ld a,%0'0'01'0'000 : out ($6b),a  ; WR1 - B incr., A=memory

    ld a,%0'11'11'1'01 : out ($6b),a  ; WR0 - append length + port A address, A->B
    ld a,l : out ($6b),a : ld a,h : out ($6b),a
    ld a,80 : out ($6b),a : ld a,0 : out ($6b),a
    ld a,%1'01'0'11'01 : out ($6b),a  ; WR4 - continuous, append port B addres
    ld a,e : out ($6b),a : ld a,d : out ($6b),a
    ld a,%1'10011'11 : out ($6b),a  ; WR6 - load addresses into DMA counters
    ld a,%1'00001'11 : out ($6b),a  ; WR6 - enable DMA
    ld a,%1'00000'11 : out ($6b),a    ; WR6 - disable DMA

    ;ld a,%1'00001'11 : out ($6b),a  ; WR6 - enable DMA
    
ret



tilemapDmaProgram
    DB  %1'00000'11     ; WR6 - disable DMA
    DB  %0'11'11'1'01   ; WR0 - append length + port A address, A->B
.fromAddress
    DW  tilemap
    DW  64              ; transfer lenfth, 64 bytes - one row of tilemap`
    DB  %0'0'01'0'100   ; WR1 - A incr., A=memory
    DB  %0'0'01'0'000   ; WR2 - B incr., B=memory
    DB  %1'01'0'11'01   ; WR4 - continuous, append port B addres
.destAddress
    DW  $0000
    DB  %1'10011'11     ; WR6 - load addresses into DMA counters
    DB %1'00001'11      ; WR6 - enable DMA
;---------------------------------------------------------------------
; Copy tilemap from tilemap data that is wider than the screen
copyWideTileMap:
	ld hl,tilemap
	ld DE, START_OF_TILEMAP
	ld a, (MAPLOCATION.Y)
	cp 0
	jr z,.copyRows			; we're done if Y is zero
.offset:
	add hl,160
	dec A 
	jr nz,.offset
.copyRows
	ld a,10
.copyRow
	push hl
	ld bc,(MAPLOCATION.X)
	add hl,bc
	ld bc,80
	ldir
	pop hl
	add hl,160
	dec a
	jr nz,.copyRow
	ret
