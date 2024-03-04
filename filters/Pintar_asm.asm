section .data
align 16
ocho: times 8 dw 8
unos: times 8 dw 0xFFFF
transparencia255: times 4 dd 0xFF000000 ;por la endiannes, revisar los de abajo
red: times 4 dd 0xFFFF0000	;para hacer tests
transparenciaVertical_1: dd 0xFF000000, 0xFF000000, 0xFFFFFFFF, 0xFFFFFFFF	;estan en red en vez de negro, para probar
transparenciaVertical_2: dd 0xFFFFFFFF, 0xFFFFFFFF, 0xFF000000, 0xFF000000



;void Pintar_asm(unsigned char *src,		rdi
;              unsigned char *dst,			rsi
;              int width,					rdx
;              int height,					rcx
;              int src_row_size,			r8
;              int dst_row_size);			r9
section .text
global Pintar_asm
Pintar_asm:
	;prologo
	push rbp
	mov rbp, rsp
	push r12
	push r13
	push r14
	push r15
	
	;cuerpo
	mov r14, r8 	;int src_row_size
	mov r15, r9 	;int dst_row_size)
	mov r8, rdx		;guardo copia de width
	mov r9, rcx		;guardo copia de height
	mov r12, 0		;uso r12 como offset
	mov r13, rsi	;me guardo copia del puntero a destination
	.filas:
		
		.columnas:						;como es todo una linea contigua de datos...
			movdqu xmm1, [rsi + r12]	;...es suficiente con un solo offset
			movdqu xmm1, [unos]			;pongo todo en 1

			movdqu [rsi + r12], xmm1
		add r12, 16
		sub rdx, 4
		cmp rdx, 0
		jne .columnas
	dec rcx
	cmp rcx, 0
	mov rdx, r8
	jne .filas

	;bordes en negro
	mov rdx, r8		;recupero width
	mov rcx, r9		;recupero heigth
	movdqu xmm0, [transparencia255]
	
	xor r12, r12
	mov rdi, 2				;uso rdi porque nunca usamos el puntero al source
	.bordesHorizontales1:	;bordes superiores
		
		.bordesH1:
			
			movdqu xmm1, [transparencia255]
			;movdqu xmm1, [red]

			movdqu [rsi + r12], xmm1
		add r12, 16
		sub rdx, 4
		cmp rdx, 0
		jne .bordesH1
	dec rdi
	cmp rdi, 0
	mov rdx, r8
	jne .bordesHorizontales1

	mov rdx, r15	;recupero dst_row_size
	mov rcx, r9		;recupero heigth
	mov rsi, r13	;reinicio el puntero
	
	mov rdi, rcx	;rdi = height
	sub rdi, 2		;rdi = height -2

	mov rax, rdi 	;(es necesario este mov porque mul hace 
	mul rdx			; rax := rax * registro)
	mov rdi, rax	;rdi = (rcx-2)*rdx = (height-2)*dst_row_size 
	add rsi, rdi	;(height-2)*dst_row_size 
	
	xor r12,r12
	mov rdi, 2	    ;uso rdi porque nunca usamos el puntero al source
	
	mov rdx, r8		;recupero width

	.bordesHorizontales2:	;bordes superiores	
		.bordesH2:
			
			movdqu xmm1, [transparencia255]
			;movdqu xmm1, [red]

			movdqu [rsi + r12], xmm1
		add r12, 16
		sub rdx, 4
		cmp rdx, 0
		jne .bordesH2
	dec rdi
	cmp rdi, 0
	mov rdx, r8
	jne .bordesHorizontales2

	mov rsi, r13		;reinicio el puntero
	add rsi, r14
	add rsi, r14
	sub rcx, 4
	movdqu xmm0, [transparenciaVertical_1]
	movdqu xmm1, [transparenciaVertical_2]
	.bordesVerticales1:								
		movdqu [rsi], xmm0				;pone los dos primeros pixeles de la fila en negro
		movdqu [rsi + (rdx*4)-16], xmm1	;pone los dos ultimos pixeles de la fila en negro
		add rsi, r14					;le agrego al puntero dst_row size para pasar a la siguiente fila

	loop .bordesVerticales1	;itera height =rcx-veces
	
	;epilogo
	pop r15
	pop r14
	pop r13
	pop r12
	pop rbp
	ret
	


