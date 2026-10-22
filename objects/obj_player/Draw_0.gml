// ===== desenho do rato (sprites) =====
// Todos os sprites do rato têm a origem no centro da caixa de colisão (x+5, y+5).
var cx = x + 5, cy = y + 5;
var spr = spr_rato_parado, idx = 0, ang = 0, xs = face, al = 1, k = 1;
var fr = floor(tempo_anim * 12) % 2;

if (teleporte != undefined)
{
    var tt = teleporte.tempo;
    k = max(0.05, (tt < 0.25) ? 1 - tt / 0.25 : (tt - 0.25) / 0.25);
}
if (morto)
{
    spr = spr_rato_morto; xs = 1;
    ang = -tempo_morte * 8 * 180 / pi;
    al = max(0, 1.1 - tempo_morte);
}
else if (escalando != 0) { spr = spr_rato_escalando; xs = escalando; }
else if (roendo > 0) { spr = spr_rato_roendo; idx = fr; }
else if (!chao) spr = (velv < 0) ? spr_rato_pulo : spr_rato_queda;
else if (abs(velh) > 20) { spr = spr_rato_andando; idx = fr; }
if (escondido) al = 0.4;

draw_sprite_ext(spr, idx, cx, cy, xs * k, k, ang, c_white, al);
if (global.tem_chave && !morto && escalando == 0)
    draw_sprite_ext(spr_chave_boca, 0, cx + face * k * 8, y + h - 8 * k, face * k, k, 0, c_white, al);

