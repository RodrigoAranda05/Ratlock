var lado = face;
var fr = floor(global.tempo_jogo * 6) % 2;
var xm = x + w / 2;                       // centro do corpo
var cima = y - 4;                         // altura dos balões (! e ?)

if (tipo == "T")
{
    var cx = x + 8, fy = y + 24;
    if (ativo)
    {
        desenha_rect_alfa(cx - 176, fy - 48, 176, 48, 0xff3c28, 0.25);
        desenha_rect(cx - 176, fy - 48, 176, 1, 0xff5a4a);
    }
    else if (avisando && fr == 1) desenha_rect_alfa(cx - 176, fy - 48, 176, 48, 0xffbe28, 0.15);
    draw_sprite(spr_sentinela, cego ? 3 : (ativo ? 2 : (avisando ? 1 : 0)), round(x), round(y));
    if (cego) draw_sprite(spr_duvida, 0, x + 6, y - 14);
    exit;
}
if (tipo == "C")
{
    draw_sprite_ext(spr_cao, fr, round(x) + 8, round(y) + 10, lado, 1, 0, c_white, 1);
    if (alerta != 0) draw_sprite(spr_alerta, 0, x + 7, y - 16);
    exit;
}
if (tipo == "H")
{
    draw_sprite_ext(spr_cacador, (velh != 0 && fr == 1) ? 1 : 0, round(x) + 7, round(y) + 9, lado, 1, 0, c_white, 1);
    if (alerta != 0) draw_sprite(spr_alerta, 0, x + 6, y - 16);
    exit;
}
draw_sprite_ext(sprite_index, (velh != 0 && fr == 1) ? 1 : 0, round(x) + 6, round(y) + 22, lado, 1, 0, c_white, 1);
if (tipo == "F" && reparo > 0 && floor(global.tempo_jogo * 10) % 2 == 1) draw_sprite(spr_reparo, 0, x + 3, y - 16);
if (cego || no_escuro) draw_sprite(spr_duvida, 0, x + 4, y - 14);
else if (alerta != 0) draw_sprite(spr_alerta, 0, x + 5, y - 14);
