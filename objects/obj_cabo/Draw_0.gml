// fio no teto ligando as lâmpadas até o cabo
var xmin = x, xmax = x;
for (var k = 0; k < array_length(global.lampadas); k++)
{
    xmin = min(xmin, global.lampadas[k].x);
    xmax = max(xmax, global.lampadas[k].x);
}
desenha_rect(xmin, 19, xmax - xmin + 1, 2, 0x0b0908);
desenha_rect(x - 1, 19, 2, y - 25, 0x0b0908);
desenha_rect(xmin, 19, xmax - xmin + 1, 1, global.luz_ligada ? 0xb88a2f : 0x3a3a3a);
draw_sprite(spr_cabo, roido ? 1 : 0, x, y);
if (!roido) draw_sprite_ext(spr_cabo_brilho, 0, x, y, 1, 1, 0, c_white, 0.4 + 0.4 * sin(global.tempo_jogo * 6));
