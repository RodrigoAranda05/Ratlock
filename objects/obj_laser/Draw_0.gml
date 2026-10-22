var quadro = 0;                                      // 0 apagado pela luz, 1 feixe, 2 aviso, 3 sem energia
if (ligado) quadro = 1;
else if (aviso && floor(global.tempo_jogo * 16) % 2 == 1) quadro = 2;
else if (!global.luz_ligada) quadro = 3;
draw_sprite(spr_laser, quadro_base * 4 + quadro, coluna * TL, linha * TL);
var horizontal = (vetor[0] != 0);
if (ligado && tamanho > 0)
{
    if (horizontal) desenha_rect_alfa(feixe.x, feixe.y - 2, feixe.w, feixe.h + 4, 0xff2a40, 0.28);
    else desenha_rect_alfa(feixe.x - 2, feixe.y, feixe.w + 4, feixe.h, 0xff2a40, 0.28);
    desenha_rect(feixe.x, feixe.y, feixe.w, feixe.h, 0xff5a6a);
    if (horizontal) desenha_rect(feixe.x, feixe.y + 1, feixe.w, 2, 0xffffff);
    else desenha_rect(feixe.x + 1, feixe.y, 2, feixe.h, 0xffffff);
}
else if (aviso && tamanho > 0 && floor(global.tempo_jogo * 16) % 2 == 1)
{
    if (horizontal) desenha_rect_alfa(feixe.x, feixe.y + 1, feixe.w, 2, 0xffb020, 0.35);
    else desenha_rect_alfa(feixe.x + 1, feixe.y, 2, feixe.h, 0xffb020, 0.35);
}
