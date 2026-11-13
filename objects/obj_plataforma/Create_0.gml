// ===== obj_plataforma: plataforma de mão única (como nos jogos 2D clássicos) =====
// Dá para atravessar de baixo para cima (pulando) e ficar em pé em cima dela.
// Para descer: S + pulo, ou segurar S um instante. O desenho escolhe o quadro pelas plataformas vizinhas.
event_inherited();
simbolo = "=";

espelha = false;

liga = function()
{
    var pe = (tile_em(coluna - 1, linha) == "=");
    var pd = (tile_em(coluna + 1, linha) == "=");
    var we = (tile_em(coluna - 1, linha) == "S");
    var wd = (tile_em(coluna + 1, linha) == "S");
    image_index = quadro_plataforma(pe, pd, we, wd);
    espelha = plataforma_espelha(pe, pd, we, wd);
    global.plat_span[linha][coluna] = span_plataforma(image_index, espelha);     // só a parte com barra segura o rato
}
