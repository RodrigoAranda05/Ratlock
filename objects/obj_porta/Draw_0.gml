// porta de 24x28 com 2 quadros: 0 fechada, 1 aberta (abre quando o rato chega com a chave, e fica aberta ao concluir)
var p = global.jogador;
var perto = global.tem_chave && abs(p.x + p.w / 2 - (coluna * TL + TL / 2)) < 24 && abs(p.y + p.h - (linha + 1) * TL) < 24;
var quadro = (global.estado == "clear" || perto) ? 1 : 0;
draw_sprite(spr_porta, quadro, coluna * TL + (TL - 24) / 2, (linha + 1) * TL - 28);
