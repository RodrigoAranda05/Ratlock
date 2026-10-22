if (pego) exit;
var p = global.jogador;
if (secreto && point_distance(x, y, p.x + 5, p.y + 5) > 48) exit;
var yy = round(y + sin(global.tempo_jogo * 3 + x) * 1.5);
desenha_brilho(round(x), yy, 20, 0.3);
draw_sprite(spr_queijo, 0, round(x), yy);
