if (folha_morcego >= 0)
{
    // Escala original do sprite: cada quadro da folha mede 32x32.
       draw_sprite_ext(folha_morcego, quadro_bat, x, y - 8, 1, 1, 0, c_white, 1);

}
if (!fugindo)
{
    // Edite o texto abaixo para mudar a tecla mostrada ao jogador.
    draw_set_colour(make_colour_rgb(20, 18, 30));
    draw_set_font(global.fonte);
    var escala_fala = 0.22;
    var largura_fala = string_width(fala) * escala_fala;
    var caixa_w = max(28, largura_fala + 10);
    var caixa_h = 12;
    var cx = x;
    var cy = y - 24;
    draw_set_colour(make_colour_rgb(20, 18, 30));
    draw_roundrect(cx - caixa_w / 2, cy - caixa_h / 2, cx + caixa_w / 2, cy + caixa_h / 2, false);
    draw_set_colour(c_white);
    draw_roundrect(cx - caixa_w / 2, cy - caixa_h / 2, cx + caixa_w / 2, cy + caixa_h / 2, true);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_text_transformed(cx, cy, fala, escala_fala, escala_fala, 0);
    draw_set_font(-1);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
}
