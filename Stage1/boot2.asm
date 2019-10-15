; Real-Mode Part of the Boot Loader
;
; When the PC starts, the processor is essentially emulating an 8086 processor, i.e. 
; a 16-bit processor.  So our initial boot loader code is 16-bit code that will 
; eventually switch the processor into 32-bit mode.

BITS 16

; Tell the assembler that we will be loaded at 9000h.
ORG 9000h

; The below code is for the Stage 1 section of the first assignment.

; **********************************
; *     PRIMARY FUNCTION CALLS     *
; **********************************

call	SetVideoMode	; set the video mode of the BIOS

; The below code performs the same function to the below pseudo code:
; function drawline(x0, y0, x1, y1, colour)
; The following registers store the values:
; ax - x0
; bx - y0
; cx - x1
; dx - y1
; si - colour
mov 	ax, 50
mov 	bx, 60
mov 	cx, 120
mov 	dx, 100
mov 	si, 15
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

; plot a pixel at a specified row and column. they are set up in the algorithm code below.
PlotPixel:
	mov		ah, 0Ch		
	mov		bh, 0		
	int		10h			
	ret		

; **********************************************************************
; *     BRESENHAM'S LINE DRAWING ALGORITHM IN X86 ASSEMBLY BEGIN!!     *
; **********************************************************************

; use Bresenham's line drawing algorithm to plot a line between two points
DrawLine:
	; The paramaters for this functions are all set up here
	mov 	[x0], ax 	
	mov 	[y0], bx 
	mov 	[x1], cx 
	mov 	[y1], dx 
	mov 	[colour], si

	; this section sets up the dx variable
	; This corresponds to this line of pseudo-code:
	; dx := abs(x1 - x0)
	mov 	ax, [x1]
	sub		ax, [x0]			; subtract the two values and save the result in the ax register for the AbsoluteValue function
	call	AbsoluteValue		; get the absolute value of the result
	mov		[dxVariable], ax	; save the result in the dxvariable

	; this section sets up the dy variable
	; corresponding to this line of pseudo-code:
	; dy := abs(y1 - y0)
	mov		ax, [y1]			
	sub		ax, [y0]				; move the result into the ax register ready for the absolutevalue function
	call	AbsoluteValue		; get the absolute value of the result
	mov		[dyVariable], ax	; save the result in the dyvariable

	; this section sets the sx variable.
	; Corresponding to this line of ther pseudocode:
	; if x0 < x1 then sx := 1 else sx := -1
	mov		ax, [x0]
	cmp		ax, [x1] 		
	jl		SetSXToOne	
	mov		word [sx], -1		
	jmp		SetSY		
SetSXToOne:	
	mov		word [sx], 1		

	; and this section sets the sy variable
	; again, corresponding to this line of pseudocode:
	; if y0 < y1 then sy := 1 else sy := -1
SetSY:
	mov		ax, [y0]
	cmp 	ax, [y1]		
	jl		SetSYToOne	
	mov 	word [sy], -1		
	jmp 	SetErr 
SetSYToOne:	
	mov		word [sy], 1		

	; this section sets the err variable - corresponding to this pseudocode:
	;err := dx - dy
SetErr:
	mov		ax, [dxVariable]		
	sub		ax, [dyVariable]				
	mov		[err], ax


; ******************************
; *     START OF MAIN LOOP     *
; ******************************
;The algorithm below performs the main loop as written in the pseudo-code.
;the corresponding pseudocode instructions are written above the assembley code.

	; this is where the bulk of the algorithm happens
MainLoopBegin:
	; set up the PlotPixel function and then call it
	;	setPixel(x0, y0, colour)
	mov		al, [colour]	
	mov		cx, [x0]		
	mov		dx, [y0]		
	call	PlotPixel	

	; determine if we should exit the loop and halt the program
	; if x0 = x1 and y0 = y1 exit loop
	mov		ax, [x0]
	cmp 	ax, [x1]
	je		ExitProgram
	mov		ax, [y0]
	cmp 	ax, [y1]
	je 		ExitProgram
	jmp		Continue

ExitProgram: 
	ret

Continue:
	; set e2 variable up
	; e2 := 2 * err
	mov 	ax, [err]
	add 	ax, ax
	mov 	[e2], ax

	; determine if err and x0 variables should be changed (first if statement)
	;	if e2 > -dy then
	;		err := err - dy
	;		x0 := x0 + sx
	;	end if
	mov		ax, [dyVariable]
	neg 	ax
	cmp		[e2], ax
	jg		FirstIFLogic
	jmp		NextIFStatement
FirstIFLogic:
	mov		ax, [err]
	sub		ax, [dyVariable]
	mov		[err], ax
	mov		ax, [x0]
	add		ax, [sx]
	mov		[x0], ax

	; now determine if the err and y0 variables should be changed (second if statement)
	;	if e2 < dx then
	;		err := err + dx
	;		y0 := y0 + sy
	;	end if
	;end loop
NextIFStatement:
	mov		ax, [e2]
	cmp		ax, [dxVariable]
	jl		SecondIFLogic
	jmp		FinalStatement
SecondIFLogic:
	mov		ax, [err]
	add		ax, [dxVariable]
	mov		[err], ax
	mov		ax, [y0]
	add		ax, [sy]
	mov		[y0], ax

	; jump to the beginning of the main loop
FinalStatement:
	jmp MainLoopBegin 

; *******************************
; *     ABSOLUTE VALUE CODE     *
; *******************************

; Checks the value that is in the AH register against 0.
; if it is more than zero then just return.
; if it is less than zero, negate the value and then return.
; (using the JL function to jump to the NegateValue section
; and negate the value if the result is less than 0).
AbsoluteValue:
	cmp 	ax, 0
	jl 		NegateValue
	ret

; negates the value that is stored in AH (using the NEG function)
NegateValue:
	neg ax
	ret

; Data section - defining the variables to be used as paramaters and additional variables to hold the data.

x0			dw	0 	 
y0			dw	0	 
x1			dw	0
y1			dw	0
colour		dw	0	 
dxVariable	dw	0
dyVariable	dw	0
sx			dw	0
sy			dw	0
err			dw	0
e2			dw	0
