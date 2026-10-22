// ===== desenho e efeitos =====
// Tudo é sprite: spr_pixel esticado vira retângulo, spr_brilho esticado vira luz.
// Cores vêm como 0xRRGGBB e são convertidas para o formato do GameMaker (BGR).

function cor_rgb(_h)
{
    return make_colour_rgb((_h >> 16) & 255, (_h >> 8) & 255, _h & 255);
}

function formata_tempo(_t)
{
    var m = floor(_t / 60);
    var s = floor(_t % 60);
    var d = floor((_t * 10) % 10);
    return string(m) + ":" + ((s < 10) ? "0" : "") + string(s) + "." + string(d);
}

function desenha_pixel(_x, _y, _w, _h, _c, _a)
{
    draw_sprite_ext(spr_pixel, 0, _x, _y, _w, _h, 0, cor_rgb(_c), _a);
}

function desenha_rect(_x, _y, _w, _h, _c)
{
    draw_sprite_ext(spr_pixel, 0, _x, _y, _w, _h, 0, cor_rgb(_c), 1);
}

function desenha_rect_alfa(_x, _y, _w, _h, _c, _a)
{
    draw_sprite_ext(spr_pixel, 0, _x, _y, _w, _h, 0, cor_rgb(_c), _a);
}

// Fonte de sistema desenhada em alta resolução (o texto é nítido mesmo com a GUI ampliada).
// global.fonte_escala compensa a diferença de tamanho entre ela e a fonte padrão do GameMaker.
function cria_fonte()
{
    draw_set_font(-1);
    var altura_padrao = string_height("Ag");
    global.fonte = font_add("Arial", 28, true, false, 32, 255);
    if (global.fonte == -1) { global.fonte = -1; global.fonte_escala = 1; return; }
    draw_set_font(global.fonte);
    global.fonte_escala = altura_padrao / max(1, string_height("Ag"));
    draw_set_font(-1);
}

function escala_texto(_z)
{
    return (_z / 13) * global.fonte_escala;
}

function largura_texto(_s, _z)
{
    draw_set_font(global.fonte);
    var w = string_width(_s) * escala_texto(_z);
    draw_set_font(-1);
    return w;
}

// desenhar texto: só na GUI (obj_ui Draw GUI), onde a matriz já amplia o layout 480x272
function desenha_texto(_s, _x, _y, _c, _al, _z)
{
    var sc = escala_texto(_z);
    draw_set_font(global.fonte);
    if (_al == "center") draw_set_halign(fa_center);
    else if (_al == "right") draw_set_halign(fa_right);
    else draw_set_halign(fa_left);
    draw_set_valign(fa_middle);
    draw_set_colour(c_black);
    draw_text_transformed(_x + 0.6, _y + 0.6, _s, sc, sc, 0);
    draw_set_colour(cor_rgb(_c));
    draw_text_transformed(_x, _y, _s, sc, sc, 0);
    draw_set_colour(c_white);
    draw_set_font(-1);
}

function desenha_estrela(_x, _y, _on)
{
    draw_sprite(spr_estrela, _on ? 1 : 0, _x, _y);
}

function desenha_icone_queijo(_x, _y, _on)
{
    draw_sprite(spr_icone_queijo, _on ? 1 : 0, _x, _y);
}

function desenha_brilho(_x, _y, _r, _a)
{
    draw_sprite_ext(spr_brilho, 0, _x, _y, _r / 32, _r / 32, 0, c_white, _a);
}

function mostra_aviso(_s, _t)
{
    global.aviso_texto = _s;
    global.aviso_tempo = _t;
}

function faiscas(_x, _y, _n)
{
    for (var i = 0; i < _n; i++)
    {
        array_push(global.particulas, {
            x: _x, y: _y,
            vx: (random(1) - 0.5) * 90,
            vy: -random(1) * 80,
            l: 0.5,
            c: (random(1) < 0.5) ? 0xffd84a : 0xffffff
        });
    }
}

// ---------- GUI em alta resolução ----------
// O layout é 480x272 (VW x VH); a matriz amplia para a janela. Chame gui_comeca() no Draw GUI e gui_termina() no fim.
function gui_comeca()
{
    var k = min(JANELA_W / VW, JANELA_H / VH);
    matrix_set(matrix_world, matrix_build((JANELA_W - VW * k) / 2, (JANELA_H - VH * k) / 2, 0, 0, 0, 0, k, k, 1));
}

function gui_termina()
{
    matrix_set(matrix_world, matrix_build_identity());
    draw_set_alpha(1);
    draw_set_colour(c_white);
}

// posição do mouse no layout 480x272 (como o desenho do GUI enxerga)
function mouse_layout_x()
{
    var k = min(JANELA_W / VW, JANELA_H / VH);
    return (device_mouse_x_to_gui(0) - (JANELA_W - VW * k) / 2) / k;
}

function mouse_layout_y()
{
    var k = min(JANELA_W / VW, JANELA_H / VH);
    return (device_mouse_y_to_gui(0) - (JANELA_H - VH * k) / 2) / k;
}

function desenha_moldura(_x, _y, _w, _h)
{
    desenha_rect(_x - 2, _y - 2, _w + 4, 2, 0xffd84a);
    desenha_rect(_x - 2, _y + _h, _w + 4, 2, 0xffd84a);
    desenha_rect(_x - 2, _y, 2, _h, 0xffd84a);
    desenha_rect(_x + _w, _y, 2, _h, 0xffd84a);
}
