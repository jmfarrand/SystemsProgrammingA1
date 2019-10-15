; Real-Mode Part of the Boot Loader
;
; When the PC starts, the processor is essentially emulating an 8086 processor, i.e. 
; a 16-bit processor.  So our initial boot loader code is 16-bit code that will 
; eventually switch the processor into 32-bit mode.

BITS 16

; Tell the assembler that we will be loaded at 9000h.
ORG 9000h

; The below code is for the Stage 2 section of the first assignment.

; **********************************
; *     PRIMARY FUNCTION CALLS     *
; **********************************

call	SetVideoMode	; set the video mode of the BIOS

; The below code performs the same function to the below pseudo code:
; function drawline(x0, y0, x1, y1, colour)

push	word 15 	; colour
push	word 100 	; y1
push	word 120 	; x1
push	word 60 	; y0
push	word 50 	; x0

call 	DrawLine

hlt		; Now that we are finished, halt the program.


; *****************************
; *     CHANGE VIDEO MODE     *
; *****************************

; Change the video mode of the graphics adapter
SetVideoMode:
	mov		ah, 0		
	mov		al, 13h		
	int		10h			
	ret		

; *********************
; *     PLOT PIXEL    *
; *********************
; constant definitions for the plot pixel paramaters:
%assign x0		4
%assign y0		6
%assign colour	8

; 	plot a pixel at a specified row and column. they are set up in the algorithm code below.
;	setPixel(x0, y0, colour)
PlotPixel:
	;set up stack frame and save the values of the registers.
	push bp
	mov bp, sp
	push dx
	push cx
	push bx
	;perform the plotpixel function as normal using the values on the stack instead of the registers.
	mov		ah, 0Ch		
	mov		al, [bp + colour]	; pixel colour
	mov		bh, 0		
	mov		cx, [bp + x0]		; x0
	mov		dx, [bp + y0]		; y0
	int		10h	
	;return the registers back, clean up the stack and return to the main loop.
	pop 	bx
	pop 	cx
	pop 	dx	
	mov		sp, bp	
	pop 	bp
	ret		6

; **********************************************************************
; *     BRESENHAM'S LINE DRAWING ALGORITHM IN X86 ASSEMBLY BEGIN!!     *
; **********************************************************************
; constant values for offsets to paramaters and variables
%assign x0		4
%assign y0		6
%assign x1		8
%assign y1		10
%assign colour	12

%assign dxVariable		2
%assign dyVariable		4
%assign sx				6
%assign sy				8
%assign err				10
%assign e2				12


; use Bresenham's line drawing algorithm to plot a line between two points
DrawLine:
	;SETTING STACK FRAME UP
	push	bp			;push BP onto the stack
	mov		bp, sp		;save SP in BP
	sub		sp, 14		;allocates a 14 byte buffer onto the stack
	push 	ax			; save the ax register since this is the only register that is modified

	; this section sets up the dx variable
	; This corresponds to this line of pseudo-code:
	; dx := abs(x1 - x0)
	mov 	ax, [bp + x1]
	sub		ax, [bp + x0]		
	call	AbsoluteValue			; get the absolute value of the result
	mov		[bp - dxVariable], ax	; save the result in the dxvariable (2 bytes down the stack)

	; this section sets up the dy variable
	; corresponding to this line of pseudo-code:
	; dy := abs(y1 - y0)
	mov		ax, [bp + y1]				
	sub		ax, [bp + y0]				; move the result into the ax register ready for the absolutevalue function
	call	AbsoluteValue			; get the absolute value of the result
	mov		[bp - dyVariable], ax	; save the result in the dyvariable (4 bytes down the stack)

	; this section sets the sx variable.
	; Corresponding to this line of ther pseudocode:
	; if x0 < x1 then sx := 1 else sx := -1
	mov		ax, [bp + x0]
	cmp		ax, [bp + x1] 		
	jl		SetSXToOne	
	mov		word [bp - sx], -1		
	jmp		SetSY		
SetSXToOne:	
	mov		word [bp - sx], 1		

	; and this section sets the sy variable
	; again, corresponding to this line of pseudocode:
	; if y0 < y1 then sy := 1 else sy := -1
SetSY:
	mov		ax, [bp + y0]
	cmp 	ax, [bp + y1]		
	jl		SetSYToOne	
	mov 	word [bp - sy], -1		
	jmp 	SetErr 
SetSYToOne:	
	mov		word [bp - sy], 1		

	; this section sets the err variable - corresponding to this pseudocode:
	;err := dx - dy
SetErr:
	mov		ax, [bp - dxVariable]		
	sub		ax, [bp - dyVariable]				
	mov		[bp - err], ax

; ******************************
; *     START OF MAIN LOOP     *
; ******************************
;The algorithm below performs the main loop as written in the pseudo-code.
;the corresponding pseudocode instructions are written above the assembley code.

	; this is where the bulk of the algorithm happens
MainLoopBegin:
	; set up the PlotPixel function (push the paramaters onto the stack) and then call it
	;	setPixel(x0, y0, colour)

	push word [bp + colour]
	push word [bp + y0]
	push word [bp + x0]
	call	PlotPixel	

	; determine if we should exit the loop and halt the program
	; if x0 = x1 and y0 = y1 exit loop
	mov		ax, [bp + x0]
	cmp 	ax, [bp + x1]
	je		ExitProgram
	mov		ax, [bp + y0]
	cmp 	ax, [bp + y1]
	je 		ExitProgram
	jmp		Continue

ExitProgram: 
	; pop all of the saved registers
	pop 	ax
	; move the old value of BP back into SP
	mov		sp, bp
	pop 	bp
	; then return with a value of 10 since there
	; were 10 bytes worth of paramaters
	ret		10

Continue:
	; set e2 variable up
	; e2 := 2 * err
	mov 	ax, [bp - err]
	add 	ax, ax
	mov 	[bp - e2], ax

	; determine if err and x0 variables should be changed (first if statement)
	;	if e2 > -dy then
	;		err := err - dy
	;		x0 := x0 + sx
	;	end if
	mov		ax, [bp - dyVariable]
	neg 	ax
	cmp		[bp - e2], ax
	jg		FirstIFLogic
	jmp		NextIFStatement
FirstIFLogic:
	mov		ax, [bp - err]
	sub		ax, [bp - dyVariable]
	mov		[bp - err], ax
	mov		ax, [bp + x0]
	add		ax, [bp - sx]
	mov		[bp + x0], ax

	; now determine if the err and y0 variables should be changed (second if statement)
	;	if e2 < dx then
	;		err := err + dx
	;		y0 := y0 + sy
	;	end if
	;end loop
NextIFStatement:
	mov		ax, [bp - e2]
	cmp		ax, [bp - dxVariable]
	jl		SecondIFLogic
	jmp		FinalStatement
SecondIFLogic:
	mov		ax, [bp - err]
	add		ax, [bp - dxVariable]
	mov		[bp - err], ax
	mov		ax, [bp + y0]
	add		ax, [bp - sy]
	mov		[bp + y0], ax

	; jump to the beginning of the main loop
FinalStatement:
	jmp MainLoopBegin 

; *******************************
; *     ABSOLUTE VALUE CODE     *
; *******************************

; Checks the value that is in the first location in the stack against 0.
; if it is more than zero then just return.
; if it is less than zero, negate the value and then return.
; (using the JL function to jump to the NegateValue section
; and negate the value if the result is less than 0).

AbsoluteValue:
	cmp 	ax, 0
	jl 		NegateValue
	ret

; negates the value that is stored in AX (using the NEG function)
NegateValue:
	neg ax
	ret
