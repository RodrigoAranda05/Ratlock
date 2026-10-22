event_inherited();
// VARIÁVEIS DA ROOM (clique na instância na room e mude lá):
//   direcao: para onde a corrente se estende  (0 direita, 1 cima, 2 esquerda, 3 baixo)
//   puxa:    0 sopra (empurra para longe), 1 puxa (suga para a ventoinha). Para baixo só existe puxando.
// Dá para pôr quantas ventoinhas quiser, cada uma com a sua direção.
if (direcao == 3) puxa = 1;
simbolo = puxa ? ["r", "u", "y", "n"][direcao] : ["R", "U", "Y", "n"][direcao];
var _vertical = (direcao == 1 || direcao == 3);
if (puxa) sprite_index = _vertical ? spr_vent_suga_v : spr_vent_suga_h;
else sprite_index = _vertical ? spr_vent_sopra_v : spr_vent_sopra_h;
defasagem_anim = coluna + linha;

// marca no mapa de vento os tiles que a corrente alcança (para na primeira parede)
// chamado pelo obj_game quando a grade da fase já está pronta
prepara = function()
{
    var sentido = dir_ventoinha(simbolo);
    var alcance = (sentido[0] != 0) ? (puxa ? 7 : 6) : 10;
    for (var n = 1; n <= alcance; n++)
    {
        var tile_col = coluna + sentido[0] * n;
        var tile_lin = linha + sentido[1] * n;
        if (solido_rato(tile_col, tile_lin) || tile_lin >= GH) break;
        global.mapa_vento[tile_lin][tile_col] = simbolo;
        if (sentido[0] != 0)
        {
            // corrente horizontal também cobre os tiles de cima (1 se sopra, 3 se puxa)
            var largura = puxa ? 3 : 1;
            for (var k = 1; k <= largura; k++)
            {
                if (tile_lin - k > 0 && !solido_rato(tile_col, tile_lin - k) && global.mapa_vento[tile_lin - k][tile_col] == "")
                {
                    global.mapa_vento[tile_lin - k][tile_col] = simbolo;
                }
            }
        }
    }
}
