if (pego) exit;
var p = global.jogador;
var yy = round(y - 1 + sin(global.tempo_jogo * 3 + x) * 1.2);   // sobe e desce sem entrar no chão
desenha_brilho(round(x), yy, 20, 0.3);
draw_sprite(spr_queijo, 0, round(x), yy);
