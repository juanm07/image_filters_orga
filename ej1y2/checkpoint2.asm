
%define OFFSET_B 16
%define OFFSET_C 32
%define OFFSET_C2 48
%define OFFSET_ABC 64
section .rodata
ocho: times 8 dw 8
unos: times 16 db 0xFF

section .text
global checksum_asm

; uint8_t checksum_asm(void* array, uint32_t n)
;						rdi,		esi

checksum_asm:
	;prologo
	push rbp
	mov rbp, rsp
	;cuerpo
	xor rax,rax
	mov rax, 1		;empiezo asumiendo que todo el arreglo cumple
	movdqu xmm0, [ocho]		;xmm0 = 8|8|8|8|8|8|8|8
	movdqu xmm6, [unos]		;xmm6 = F|F|F|F|F|F|F|F|F|F|F|F|F|F|F|F

	.ciclo:
		movdqu xmm1, [rdi]				;xmm1= A7|A6|A5|A4|A3|A2|A1|A0
		movdqu xmm2, [rdi + OFFSET_B]	;xmm2= B7|B6|B5|B4|B3|B2|B1|B0
		movdqu xmm3, [rdi + OFFSET_C]	;xmm3= C3|C2|C1|C0
		movdqu xmm4, [rdi + OFFSET_C2]	;xmm4= C7|C6|C5|C4

		paddw xmm1, xmm2		;xmm1= A7+B7|A6+B6|A5+B5|A4+B4|A3+B3|A2+B2|A1+B1|A0+B0
		movdqu xmm2, xmm1		;xmm2=xmm1

		;multiplicar *8
		pmulhw xmm1, xmm0		;xmm1= high AB7*8|AB6*8|AB5*8|AB4*8|AB3*8|AB2*8|AB1*8|AB0*8
		pmullw xmm2, xmm0		;xmm2= low  AB7*8|AB6*8|AB5*8|AB4*8|AB3*8|AB2*8|AB1*8|AB0*8

		movdqu xmm5, xmm2		;xmm5=xmm2
		punpcklwd xmm2, xmm1	;xmm2= AB3*8|AB2*8|AB1*8|AB0*8	;revisar estos unpacks
		punpckhwd xmm5, xmm1	;xmm5= AB7*8|AB6*8|AB5*8|AB4*8

		pcmpeqd xmm2,xmm3		;comparo AB_x*8= C_x , con 0 < x < 3 
		pcmpeqd xmm5,xmm4		;comparo AB_x*8= C_x , con 4 < x < 7 

		pcmpeqq xmm2, xmm6		;comparo el resultado de la comparacion anterior con todos unos...
		pcmpeqq xmm5, xmm6		;y si en algun lugar hubo un 0, toda una mitad se pone en 0

		pextrq rcx, xmm2, 0		;extraigo la parte baja de la comparación de la parte baja
		xor rax, rax			;xor ACTUALIZA flags, por eso lo hago antes del cmp
		cmp rcx, 0xFFFFFFFF
		jne .fin
		mov rax, 1

		pextrq rcx, xmm2, 1		;extraigo la parte alta de la comparación de la parte baja
		xor rax, rax
		cmp rcx, 0xFFFFFFFF
		jne .fin
		mov rax, 1

		pextrq rcx, xmm5, 0		;extraigo la parte baja de la comparación de la parte alta
		xor rax, rax
		cmp rcx, 0xFFFFFFFF
		jne .fin
		mov rax, 1

		pextrq rcx, xmm5, 1		;extraigo la parte alta de la comparación de la parte alta
		xor rax, rax
		cmp rcx, 0xFFFFFFFF
		jne .fin
		mov rax, 1 

	dec esi
	cmp esi, 0	
	jnz .ciclo
	.fin:
	;epilogo
	pop rbp
	ret

