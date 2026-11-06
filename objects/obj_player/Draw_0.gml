// ===== desenho do rato (sprites) =====
// Todos os sprites do rato têm a origem no centro-baixo da célula: desenhamos no centro da caixa de colisão
// (x + w/2) com os pés no fundo dela (y + h). O rato de pé é mais alto que a caixa; a cabeça passa por cima.
var cx = x + w / 2, cy = y + h;
var spr = spr_rato_parado, idx = 0, xs = face, al = 1, k = 1;
var fr = floor(tempo_anim * 12) % 2;

// tempo no ar, só para escolher o quadro do pulo/queda
if (chao || escalando != 0 || morto) tempo_ar = 0;
else tempo_ar += delta_time / 1000000;
if (velv >= 0 && tempo_ar > 0) tempo_queda += delta_time / 1000000;
else tempo_queda = 0;

if (teleporte != undefined)
{
    var tt = teleporte.tempo;
    k = max(0.05, (tt < 0.25) ? 1 - tt / 0.25 : (tt - 0.25) / 0.25);
}
if (morto)
{
    spr = spr_rato_morto; xs = face;
    idx = min(7, floor(tempo_morte * 12));              // 8 quadros: cai e fica no chão
    al = min(1, (0.9 - tempo_morte) / 0.25 + 0.2);
}
else if (escalando != 0) { spr = spr_rato_escalando; xs = face; idx = (tecla_cima || tecla_baixo) ? floor(tempo_anim * 8) % 2 : 0; }
else if (roendo > 0) { spr = spr_rato_roendo; idx = floor(tempo_anim * 10) % 5; }
else if (!chao)
{
    if (velv < 0)
    {
        // pulo: 0 e 1 agachar, 2 impulso, 3 ponto mais alto (a subida passa rápido pelos 3 primeiros)
        spr = spr_rato_pulo;
        idx = min(3, floor(tempo_ar / 0.05));
    }
    else
    {
        spr = spr_rato_queda;
        idx = min(3, floor(tempo_queda / 0.08));
    }
}
else if (abs(velh) > 20) { spr = spr_rato_andando; idx = floor(tempo_anim * 10) % 4; }
else idx = floor(global.tempo_jogo * 2.5) % 2;      // parado: respira
if (escondido) al = 0.4;

draw_sprite_ext(spr, idx, cx, cy, xs * k, k, 0, c_white, al);
if (global.tem_chave && !morto && escalando == 0)
    draw_sprite_ext(spr_chave_boca, 0, cx + face * k * 8, cy - 11 * k, face * k, k, 0, c_white, al);
