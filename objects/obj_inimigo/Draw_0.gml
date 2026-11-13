var lado = face;
var fr = floor(global.tempo_jogo * 6) % 2;
var xm = x + w / 2;                       // centro do corpo
var cima = y - 4;                         // altura dos balões (! e ?)

if (tipo == "C")
{
    draw_sprite_ext(spr_cao, fr, round(x) + 8, round(y) + 10, lado, 1, 0, c_white, 1);
    if (alerta != 0) draw_sprite(spr_alerta, 0, x + 7, y - 16);
    exit;
}
draw_sprite_ext(sprite_index, (velh != 0 && fr == 1) ? 1 : 0, round(x) + 6, round(y) + 22, lado, 1, 0, c_white, 1);

// iluminação em volta do guarda com lanterna (L): só aparece quando a luz da fase está apagada
if (tipo == "L" && !global.luz_ligada)
{
    var cx0 = round(x) + 6;
    var cy0 = round(y) + 12;
    desenha_brilho(cx0, cy0, 44, 0.42 + 0.06 * sin(global.tempo_jogo * 3));
    desenha_brilho(cx0, cy0, 26, 0.55);
}

if (tipo == "F" && reparo > 0 && floor(global.tempo_jogo * 10) % 2 == 1) draw_sprite(spr_reparo, 0, x + 3, y - 16);
if (cego || no_escuro) draw_sprite(spr_duvida, 0, x + 4, y - 14);
else if (alerta != 0) draw_sprite(spr_alerta, 0, x + 5, y - 14);
