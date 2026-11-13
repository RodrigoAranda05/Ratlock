// o quadro espelhado (solta junto da parede da direita) desenha para a esquerda a partir de x + TL
draw_sprite_ext(sprite_index, image_index, x + (espelha ? TL : 0), y, espelha ? -1 : 1, 1, 0, c_white, 1);
