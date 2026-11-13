// emissor: aceso com o feixe ligado (e piscando no aviso), apagado sem energia
var aceso = ligado || (aviso && floor(global.tempo_jogo * 16) % 2 == 1);
draw_sprite(spr_laser, quadro_emissor + (aceso ? 0 : 4), coluna * TL, linha * TL);
// feixe: o quadro do feixe repetido de 16 em 16 px até a parede
if ((ligado || (aviso && floor(global.tempo_jogo * 16) % 2 == 1)) && tamanho > 0)
{
    var alfa = ligado ? 1 : 0.35;
    var ini_x = coluna * TL + 8 + vetor[0] * 8;
    var ini_y = linha * TL + 8 + vetor[1] * 8;
    for (var d = 0; d < tamanho; d += TL)
    {
        var seg = min(TL, tamanho - d);
        if (vetor[0] > 0) draw_sprite_part_ext(spr_laser, 8, 0, 0, seg, TL, ini_x + d, linha * TL, 1, 1, c_white, alfa);
        else if (vetor[0] < 0) draw_sprite_part_ext(spr_laser, 8, TL - seg, 0, seg, TL, ini_x - d - seg, linha * TL, 1, 1, c_white, alfa);
        else if (vetor[1] > 0) draw_sprite_part_ext(spr_laser, 9, 0, 0, TL, seg, coluna * TL, ini_y + d, 1, 1, c_white, alfa);
        else draw_sprite_part_ext(spr_laser, 9, 0, TL - seg, TL, seg, coluna * TL, ini_y - d - seg, 1, 1, c_white, alfa);
    }
}
