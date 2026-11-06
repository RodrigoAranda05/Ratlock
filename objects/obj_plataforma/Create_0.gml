// ===== obj_plataforma: plataforma de mão única (como nos jogos 2D clássicos) =====
// Dá para atravessar de baixo para cima (pulando) e ficar em pé em cima dela.
// Para descer: S + pulo, ou segurar S um instante. O desenho escolhe o quadro pelas plataformas vizinhas.
event_inherited();
simbolo = "=";

liga = function()
{
    image_index = quadro_plataforma(tile_em(coluna - 1, linha) == "=", tile_em(coluna + 1, linha) == "=",
        tile_em(coluna - 1, linha) == "S", tile_em(coluna + 1, linha) == "S");
    global.plat_span[linha][coluna] = span_plataforma(image_index);     // só a parte com barra segura o rato
}
