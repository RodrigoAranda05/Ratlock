// morcego (origem no centro do quadro 32x32)
// posição sempre em pixel inteiro: meio pixel deixa o desenho torto (um olho maior que o outro)
var _x = round(x);
var _y = round(y + balao_pulo);
var _xs = (estado == "voando" && sentido < 0) ? -1 : 1;
draw_sprite_ext(spr_morcego, floor(anim) % 14, _x, _y, _xs, 1, 0, c_white, 1);

// caixa da dica: só enquanto ele está pousado
if (estado != "voando")
{
    var escala_fala = 0.22;
    draw_set_font(global.fonte);
    var caixa_w = max(28, string_width(dica_texto) * escala_fala + 10);
    var caixa_h = 12;
    var cx = _x;
    var cy = _y - 14 + round(sin(global.tempo_jogo * 2.2));
    draw_set_colour(make_colour_rgb(20, 18, 30));
    draw_roundrect(cx - caixa_w / 2, cy - caixa_h / 2, cx + caixa_w / 2, cy + caixa_h / 2, false);
    draw_set_colour(c_white);
    draw_roundrect(cx - caixa_w / 2, cy - caixa_h / 2, cx + caixa_w / 2, cy + caixa_h / 2, true);
    // biquinho apontando para o morcego
    draw_triangle(cx - 3, cy + caixa_h / 2, cx + 3, cy + caixa_h / 2, cx, cy + caixa_h / 2 + 3, false);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_text_transformed(cx, cy, dica_texto, escala_fala, escala_fala, 0);
    draw_set_font(-1);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_colour(c_white);
}
