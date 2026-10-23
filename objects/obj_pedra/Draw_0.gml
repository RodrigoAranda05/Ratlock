// pedra com realce de luz nas bordas que ficam expostas (acima, abaixo, esquerda, direita)
draw_self();
if (tile_em(coluna, linha - 1) != "S") draw_sprite(spr_pedra_borda, 0, x, y);
if (tile_em(coluna, linha + 1) != "S") draw_sprite(spr_pedra_borda, 1, x, y);
if (tile_em(coluna - 1, linha) != "S") draw_sprite(spr_pedra_borda, 2, x, y);
if (tile_em(coluna + 1, linha) != "S") draw_sprite(spr_pedra_borda, 3, x, y);
