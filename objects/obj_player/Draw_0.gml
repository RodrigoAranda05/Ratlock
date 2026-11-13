// ===== desenho do rato (sprites) =====
// Todos os sprites do rato têm a origem no centro-baixo da célula: desenhamos no centro da caixa de colisão
// (x + w/2) com os pés no fundo dela (y + h). O rato de pé é mais alto que a caixa; a cabeça passa por cima.
if (!variable_instance_exists(id, "esc_x")) { esc_x = 1; esc_y = 1; }
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
    // estilo celeste: flash branco curto no centro + estilhaços voando; o rato em si não aparece
    var cx_m = x + w / 2, cy_m = y + h / 2;
    if (tempo_morte < 0.08)
    {
        draw_set_alpha(1 - tempo_morte / 0.08);
        draw_set_colour(c_white);
        var rr = 10 + tempo_morte * 220;
        draw_circle(cx_m, cy_m, rr, false);
        draw_set_alpha(1);
        draw_set_colour(c_white);
    }
    if (!variable_instance_exists(id, "morte_particulas")) morte_particulas = [];
    for (var _q = 0; _q < array_length(morte_particulas); _q++)
    {
        var _p = morte_particulas[_q];
        if (_p.vida <= 0) continue;
        var _al = min(1, (_p.vida / _p.vida_max) * 1.6);
        var _tam = max(1, round(_p.tam * (_p.vida / _p.vida_max)));
        var _px = round(_p.x), _py = round(_p.y);
        // sombra escura fina + pixel central (duas camadas para sair o contorno)
        draw_set_alpha(_al);
        draw_set_colour(cor_rgb(0x000000));          // contorno preto, igual ao do sprite
        draw_rectangle(_px - _tam / 2 - 1, _py - _tam / 2 - 1, _px + _tam / 2 + 1, _py + _tam / 2 + 1, false);
        draw_set_colour(cor_rgb(_p.cor));
        draw_rectangle(_px - _tam / 2, _py - _tam / 2, _px + _tam / 2, _py + _tam / 2, false);
        draw_set_alpha(1);
        draw_set_colour(c_white);
    }
    exit;
}
else if (escalando != 0) { spr = spr_rato_escalando; xs = face; idx = (tecla_cima || tecla_baixo) ? floor(tempo_anim * 10) % 8 : 0; }
else if (roendo > 0) { spr = spr_rato_roendo; idx = floor(tempo_anim * 10) % 5; }
else if (!chao)
{
    if (velv < 0)
    {
        // pulo: 0 e 1 agachar, 2 impulso, 3 ponto mais alto (a subida passa rápido pelos 3 primeiros)
        spr = spr_rato_pulo;
        idx = min(7, floor(tempo_ar / 0.03));
    }
    else
    {
        spr = spr_rato_queda;
        idx = min(7, floor(tempo_queda / 0.05));
    }
}
else if (abs(velh) > 20) { spr = spr_rato_andando; idx = floor(tempo_anim * 12) % 8; }
else idx = floor(global.tempo_jogo * 4) % 8;      // parado: respira
if (escondido) al = 0.4;

// as sprites de andar, parado, pulo e queda têm 16 quadros: 0..7 sem chave e 8..15 com a chave na boca
if (global.tem_chave && !morto && (spr == spr_rato_parado || spr == spr_rato_andando || spr == spr_rato_pulo || spr == spr_rato_queda)) idx += 8;

var agua_y = morto ? -1 : linha_agua();
if (agua_y >= 0 && cy > agua_y)
{
    // só a parte dentro da água leva o filtro azul
    var sxo = sprite_get_xoffset(spr), syo = sprite_get_yoffset(spr), sw = sprite_get_width(spr), sh = sprite_get_height(spr);
    var corte = clamp((agua_y - cy) / k + syo, 0, sh);
    var dx = cx - sxo * xs * k, dy = cy - syo * k;
    if (corte > 0) draw_sprite_part_ext(spr, idx, 0, 0, sw, corte, dx, dy, xs * k, k, c_white, al);
    draw_sprite_part_ext(spr, idx, 0, corte, sw, sh - corte, dx, dy + corte * k, xs * k, k, 0xffb870, al * 0.85);
}
else draw_sprite_ext(spr, idx, cx, cy, xs * k * esc_x, k * esc_y, 0, c_white, al);      // esc_x/esc_y: estica ao pular, achata ao cair
// chave na boca agora vem nos próprios quadros do rato (8..15); escalando/morto mantêm a boca vazia
if (global.tem_chave && !morto && escalando != 0)
    draw_sprite_ext(spr_chave_boca, 0, cx + face * k * 8, cy - 11 * k, face * k, k, 0, c_white, al);
