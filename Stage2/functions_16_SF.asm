; Various sub-routines that will be useful to the boot loader code	

; Output Carriage-Return/Line-Feed (CRLF) sequence to screen using BIOS

Console_Write_CRLF:
	push	ax
	mov 	ah, 0Eh						; Output CR
    mov 	al, 0Dh
    int 	10h
    mov 	al, 0Ah						; Output LF
    int 	10h
	pop		ax
    ret

; Write to the console using BIOS.
; 
; The address of the string to display is passed on the stack

Console_Write_16:
	push 	bp
	mov		bp, sp
	push	si
	push	ax
	mov		si, [bp + 4];				; Get the address of the string to print
	mov 	ah, 0Eh						; BIOS call to output value in AL to screen

Console_Write_16_Repeat:
	mov		al, [si]					; Load byte at SI into AL and increment SI
	inc 	si
    test 	al, al						; If the byte is 0, we are done
	je 		Console_Write_16_Done
	int 	10h							; Output character to screen
	jmp 	Console_Write_16_Repeat

	Console_Write_16_Done:
	pop		ax
	pop		si
	mov		sp, bp
	pop		bp
    ret		2

; Write string to the console using BIOS followed by CRLF
; 
; Input: SI points to a null-terminated string

Console_WriteLine_16:
	push 	bp
	mov		bp, sp
	push	word [bp + 4]
	call 	Console_Write_16
	call 	Console_Write_CRLF
	mov		sp, bp
	pop		bp
	ret		2

; Console_Write_Int(short num)
	
Console_Write_Int:
	push	bp
	mov		bp, sp
	sub		sp, 6						; Allocate a 6 byte buffer on the stack
	push	ax
	push 	cx
	push	dx
	push	si
	mov 	si, bp						; Get pointer to last byte of buffer
	dec 	si							
	xor		ax, ax						; and set it to 0 to terminate the string
	mov		[si], al					
	dec 	si							; Now point to byte before null terminator
	mov		ax, [bp + 4]
	
GetDigit:
	xor		dx, dx						; Get last digit in integer
	mov		cx, 10
	div		cx
	add		dl, 48						; Convert to ASCII
	mov		[si], dl					; and store in buffer
	dec		si
	cmp		ax, 0						; Have we converted all of the digits yet?
	jne		GetDigit
	inc		si							; Get pointer to first digit in ASCII string
	push	si
	call	Console_Write_16			; and display it
	pop		si
	pop		dx
	pop		cx
	pop		ax
	mov		sp, bp
	pop		bp
	ret		2
	


HexChars	db '0123456789ABCDEF'	
	
; Console_Write_Int_Base(short num, short base)
;
; Output the specified number in the specified base.   We assume that parameters have
; been passed in right-to-left.
	
Console_Write_Int_Base:
	push	bp
	mov		bp, sp
	sub		sp, 18						; Allocate a 18 byte buffer on the stack (allow for displaying in binary)
	push	ax
	push 	cx
	push	dx
	push	si
	push	di
	mov 	si, bp						; Get pointer to last byte of buffer
	dec 	si							
	xor		ax, ax						; and set it to 0 to terminate the string
	mov		[si], al					
	dec 	si							; Now point to byte before null terminator
	mov		ax, [bp + 6]
		
GetDigitBase:
	xor		dx, dx						; Get last digit in integer
	mov		cx, [bp + 4]				; Get base we are converting 2
	div		cx							; and divide by that number, leaving the remainder in DL
	mov		di, dx						; Convert to ASCII
	mov		dl, [di + HexChars]
	mov		[si], dl					; and store in buffer
	dec		si
	cmp		ax, 0						; Have we converted all of the digits yet?
	jne		GetDigitBase
	inc		si							; Get pointer to first digit in ASCII string
	push	si
	call	Console_Write_16			; and display it
	pop 	di
	pop		si
	pop		dx
	pop		cx
	pop		ax
	mov		sp, bp
	pop		bp
	ret		4
	
;  	short miscfunc(short a, short b)
;	{
;		int x;
;		int y;
;
;		x = a + b;
;		y = x + 10;
;		return x;
;	}

;	Constant definitions for the offsets to the parameters and variables

%assign a	6
%assign b 	4

%assign x	4
%assign y	2

miscfunc:
	push 	bp	
	mov		bp, sp
	sub		sp, 4				; Reserve space for local variables
	mov		ax, [bp + a]		; x = a + b
	add		ax, [bp + b]
	mov		[bp - x], ax
	mov		ax, [bp - x]		; y = x + 10			Note this line is not needed, since ax already contains x
	add		ax, 10
	mov		[bp - y], ax
	mov		ax, [bp - x]		; return y 				The return value is returned in ax
	mov 	sp, bp
	pop		bp
	ret		4
	
	







