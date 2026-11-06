// ===== obj_cano: cano / vinha (segundo plano, o rato escala) =====
// Não bloqueia ninguém. Os canos vizinhos se emendam: reto, curva, T e cruz.
event_inherited();
simbolo = "#";

liga = function()
{
    image_index = quadro_cano(tile_escalavel(coluna, linha - 1), tile_escalavel(coluna, linha + 1),
        tile_escalavel(coluna - 1, linha), tile_escalavel(coluna + 1, linha),
        tile_em(coluna - 1, linha) == "S", tile_em(coluna + 1, linha) == "S",
        tile_em(coluna, linha - 1) == "S", tile_em(coluna, linha + 1) == "S");
}
