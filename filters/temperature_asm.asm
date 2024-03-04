

section .data
align 16
mascara_transp_cero: times 4 dd 0x00FFFFFF ;(A, R, G, B)
mascara_transp_255 : times 2 dq 0x00FF000000000000
solo_Red           : times 4 dd 0x00FF0000
solo_Green         : times 4 dd 0x0000FF00
solo_Blue          : times 4 dd 0x000000FF
div_3              : times 2 dq 3.0
num_31             : times 2 dq 0x1F
num_95             : times 2 dq 0x5F
num_159            : times 2 dq 0x9F
num_223            : times 2 dq 0xDF
unos               : times 4 dd 0xFFFFFFFF
ceros              : times 4 dd 0x00000000

num_128            : times 2 dq 0x80
num_32             : times 2 dq 0x20
num_96             : times 2 dq 0x60
num_160            : times 2 dq 0xA0
num_224            : times 2 dq 0xE0
num_255            : times 2 dq 0xFF

;void temperature_asm(unsigned char *src,      rdi
;              unsigned char *dst,             rsi
;              int width,                      rdx
;              int height,                     rcx
;              int src_row_size,               r8
;              int dst_row_size);              r9
section .text
global temperature_asm
temperature_asm:
    ;prologo
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    push r15
    ;sub rsp,8

    ;cuerpo
    mov r12, rdi    ;me hago copia del puntero a src
    mov r13, rsi    ;me hago copia del puntero a dst

    mov rax, rcx
    mul r8          ;rax = rcx * r8 = height * src_row_size
    mov rcx, rax    
    xor rax, rax
    
    movdqu xmm8,  [solo_Red]
    movdqu xmm9,  [solo_Green]
    movdqu xmm10, [solo_Blue]
    
    
    .ciclo:
        movdqu xmm11, [div_3]
        ;cvtdq2pd xmm11, xmm11     ;convierto a double
        movdqu xmm12, [num_31]
        movdqu xmm13, [num_95]
        movdqu xmm14, [num_159]
        movdqu xmm15, [num_223]
 
        movdqu xmm0,  [mascara_transp_cero]
        movq xmm1, [r12 + rax]          ;Solo paso dos pixeles
        pand xmm1, xmm0                 ;pongo en 0 los bytes de transparencia de cada uno de los pixeles
        movdqu xmm2, xmm1   
        movdqu xmm3, xmm1   

        pand xmm1, xmm8    
        psrld xmm1, 16          ;xmm1 = xx|xx|R_1|R_0         corri 16 bits porque sino quedaban los GB en 00
        pand xmm2, xmm9    
        psrld xmm2, 8           ;xmm2 = xx|xx|G_1|G_0         corri 8 bits porque sino quedaba B en 00
        pand xmm3, xmm10        ;xmm3 = xx|xx|B_1|B_0

        pmovzxbw xmm1, xmm1     ;xmm1 = R_1|R_0
        pmovzxbw xmm2, xmm2     ;xmm2 = G_1|G_0
        pmovzxbw xmm3, xmm3     ;xmm3 = B_1|B_0

        paddusw xmm1, xmm2
        paddusw xmm1, xmm3      ;xmm1 = R_1+G_1+B_1 |R_0+G_0+B_0

        pshufd xmm1, xmm1, 11011000_b   ;(necesario que tenga esta forma xx|xx|algo|algo => algo_double|algo_double)
        cvtdq2pd xmm1, xmm1     ;convierto en double para poder hacer la division
        divpd xmm1, xmm11       ;xmm1 = (R+G+B)/3_1 |(R+G+B)/3_0
        
        
        cvttpd2pi mm0, xmm1             ;vuelvo a integer
        movdqu xmm1, [ceros]
        movq r14, mm0
        movq xmm1, r14
        pshufd xmm1, xmm1, 11011000_b   ;xmm1 = 00 | (R+G+B)/3_1 | 00 |(R+G+B)/3_0
                                        ;xmm1 = (R+G+B)/3_1 | (R+G+B)/3_0
                                        ;xmm1 = t_1 | t_0
        
        ;ARMADO DE MASCARAS
        movdqu xmm0, [unos]
        movdqu xmm2, xmm1               

        pcmpgtq xmm2, xmm12             ;xmm2 > 31 <=> xmm1 >= 32
        movdqu xmm3, xmm2

        pandn xmm2, xmm0                ;pandn := NOT(dest) AND src
                                        ;en xmm2 queda la mascara para CASO 1

        movdqu xmm4, xmm1               ;recupero el t original

        pcmpgtq xmm4, xmm13             ;xmm4 > 95 <=> xmm1 >= 96
        movdqu xmm5, xmm4
        movdqu xmm11, xmm4

        pandn xmm11, xmm0                ;NOT(mayores a 95) <=> menores o iguales a 95
        pand xmm3, xmm11                 ;en xmm3 queda la mascara para CASO 2

        movdqu xmm5, xmm1               ;recupero el t original

        pcmpgtq xmm5, xmm14             ;xmm5 > 159 <=> xmm1 >= 160
        movdqu xmm6, xmm5

        pandn xmm6, xmm0                ;NOT(mayores a 159) <=> menores o iguales a 159
        pand xmm4, xmm6                 ;en xmm4 queda la mascara para CASO 3

        movdqu xmm6, xmm1               ;recupero el t original
        
        pcmpgtq xmm6, xmm15             ;xmm6 > 223 <=> xmm1 >= 224
        movdqu xmm7, xmm6

        pandn xmm7, xmm0                ;NOT(mayores a 223) <=> menores o iguales a 223
        pand xmm5, xmm7                 ;en xmm5 queda la mascara para CASO 4   ;ERROR EN ALGUNA DE LAS MASCARAS
                                        ;en xmm6 queda la mascara para CASO 5

        ;RESOLUCION
        movdqu xmm7, xmm1
        movdqu xmm11, xmm1
        movdqu xmm12, xmm1
        movdqu xmm13, xmm1
        movdqu xmm14, [num_255]
        movdqu xmm15, [num_255]

        psllq xmm11, 2          ;xmm11 = t*4
        paddq xmm11, [num_128]    ;xmm11 = (t*4)+128      CASO 1

        psubq xmm12, [num_32]
        psllq xmm12, 2          ;xmm12 = (t-32)*4       CASO 2

        psubq xmm13, [num_96]
        psllq xmm13, 2          ;xmm13 = (t-96)*4       CASO 3

        psubq xmm14, xmm13      ;xmm14 = 255-(t-96)*4   CASO 3

        psubq xmm7, [num_160]
        psllq xmm7, 2
        psubq xmm15, xmm7       ;xmm15 = 255-(t-160)*4  CASO 4

        movdqu xmm7, [num_255]
        psubq xmm1, [num_224]
        psllq xmm1, 2
        psubq xmm7, xmm1        ;xmm7 = 255-(t-224)*4   CASO 5


        ;transformarlos en formato del pixel
                                ;xmm11 ya cumple con el formato del pixel (A, 0, 0, t*4+128)
        psllq xmm12, 16
        por xmm12, [num_255]      ;xmm12 = (A, R, (t-32)*4, 255)

        psllq xmm13, 16
        por xmm13, [num_255]
        psllq xmm13, 16
        por xmm14, xmm13        ;xmm14 = (A, (t-96)*4, 255, 255-(t-96)*4)

        movdqu xmm13, [num_255]
        psllq xmm13, 16
        por xmm15, xmm13
        psllq xmm15, 16          ;xmm15 = (A, 255, 255-(t-160)*4, 0)

        psllq xmm7, 32          ;xmm7 = (A, 255- (t-224)*4, 0 , 0)

        
        ;falta aplicarle las mascaras y convertirlos de 8 a 4 bytes y luego finalmente pasarlos a dst
        ;LAS MASCARAS
        movdqu xmm0, [mascara_transp_255]
        por xmm11, xmm0    ;agrego la transparencia en 255 para ambos pixeles
        por xmm12, xmm0
        por xmm14, xmm0
        por xmm15, xmm0
        por xmm7,  xmm0

        pand xmm2, xmm11
        pand xmm3, xmm12
        pand xmm4, xmm14
        pand xmm5, xmm15
        pand xmm6, xmm7
        ;convertir pixeles de 64 a 32 bits
        movdqu xmm0, [ceros]    ;ceros para llenar la parte alta, igualmente no se van a pasar
        packuswb xmm2, xmm0
        packuswb xmm3, xmm0
        packuswb xmm4, xmm0
        packuswb xmm5, xmm0
        packuswb xmm6, xmm0

        ;unificar todos los casos
        por xmm2, xmm3
        por xmm2, xmm4
        por xmm2, xmm5
        por xmm2, xmm6

        movq [r13 + rax], xmm2
        
    add rax, 8
	sub rcx, 8
	cmp rcx, 0
    jne .ciclo
            

    
    ;Extendemos los bytes a words (con ceros) para poder sumar y no haya overflow
    ;de esta forma, los primeros 4 pixeles que agarramos van a quedar guardados en dos xmmm (dos pixeles en c/u)
    ;Hacemos copias de cada uno por cada color y luego sumamos (deberiamos de usar 6 registros xmm en total) y dividimos con truncamiento (VER COMO RESOLVER)
    ;Luego armamos 5 mascaras para cada uno de los casos y usamos pcmp (importante que los numeros extendidos hayan sido con 0).
    ;una vez hechas las mascaras, las aplicamos a cada xmm correspondiente.
    ;Finalmente unimos todos los resultados de las mascaras y los pasamos a dst e iteramos
    
    ;epilogo
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    ret
