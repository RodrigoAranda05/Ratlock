var quadro = (global.estado == "clear") ? 2 : (global.tem_chave ? 1 : 0);
draw_sprite(spr_porta, quadro, coluna * TL - 2, (linha + 1) * TL - 30);
