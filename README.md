# Image filters

Together with my colleagues Lautaro Serpa and Rodrigo Arispe we implemented two image filters using SIMD instructions in x86 assembly language.

This was for our course Organizacion del computador 2 

## Testing


From root directory run 

1. ``` make clean && make ```


From tests folder run


2. ``` python3 1_generar_imagenes.py ``` and ``` python3 2_test_diff_cat_asm.py ```


For memory check run 


3. ``` ./correr_test_mem.sh ```
