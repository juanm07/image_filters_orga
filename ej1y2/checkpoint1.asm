
section .text

global invertirQW_asm

; void invertirQW_asm(uint64_t* p)
;						rdi
invertirQW_asm:
	;prologo
	push rbp
	mov rbp, rsp
	;cuerpo
	movdqu xmm0, [rdi]
	pshufd xmm0, xmm0, 01001110b 	;01_00 es la parte mas baja,
									;11_10 es la parte alta
									;entonces los invierte
	movdqu [rdi], xmm0
	;epilogo
	pop rbp
	ret
