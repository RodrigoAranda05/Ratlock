// ===== Utilidades de desenho e efeitos =====

// converte 0xRRGGBB (como no CSS) para a cor do GameMaker (que usa BGR)
function col(_h)
{
    return make_colour_rgb((_h >> 16) & 255, (_h >> 8) & 255, _h & 255);
}

function rc(_x, _y, _w, _h, _c)
{
    draw_set_colour(col(_c));
    draw_rectangle(_x, _y, _x + _w - 1, _y + _h - 1, false);
}

// retângulo translúcido
function rca(_x, _y, _w, _h, _c, _a)
{
    draw_set_alpha(_a);
    rc(_x, _y, _w, _h, _c);
    draw_set_alpha(1);
}

// texto com sombra: _al = "left", "center" ou "right"; _z = tamanho aproximado em pixels
function tx(_s, _x, _y, _c, _al, _z)
{
    var sc = _z / 13;
    if (_al == "center") draw_set_halign(fa_center);
    else if (_al == "right") draw_set_halign(fa_right);
    else draw_set_halign(fa_left);
    draw_set_valign(fa_middle);
    draw_set_colour(c_black);
    draw_text_transformed(_x + 1, _y + 1, _s, sc, sc, 0);
    draw_set_colour(col(_c));
    draw_text_transformed(_x, _y, _s, sc, sc, 0);
}

function toast(_s, _t)
{
    global.toastS = _s;
    global.toastT = _t;
}

function spark(_x, _y, _n)
{
    for (var i = 0; i < _n; i++)
    {
        array_push(global.parts, {
            x: _x, y: _y,
            vx: (random(1) - 0.5) * 90,
            vy: -random(1) * 80,
            l: 0.5,
            c: (random(1) < 0.5) ? 0xffd84a : 0xffffff
        });
    }
}

// m:ss.d
function fmt_tempo(_t)
{
    var m = floor(_t / 60);
    var s = floor(_t % 60);
    var d = floor((_t * 10) % 10);
    return string(m) + ":" + ((s < 10) ? "0" : "") + string(s) + "." + string(d);
}

// brilho aditivo (lâmpadas, lanternas)
function brilho(_x, _y, _r, _a)
{
    draw_set_alpha(_a);
    draw_circle_colour(_x, _y, _r, make_colour_rgb(255, 214, 130), c_black, false);
    draw_set_alpha(1);
}

function estrela(_x, _y, _r, _on)
{
    var c1 = _on ? 0xffd23f : 0x2a3040;
    draw_set_colour(col(c1));
    for (var k = 0; k < 10; k++)
    {
        var a1 = -pi / 2 + k * pi / 5;
        var a2 = -pi / 2 + (k + 1) * pi / 5;
        var r1 = (k % 2) ? _r * 0.45 : _r;
        var r2 = ((k + 1) % 2) ? _r * 0.45 : _r;
        draw_triangle(_x, _y, _x + cos(a1) * r1, _y + sin(a1) * r1, _x + cos(a2) * r2, _y + sin(a2) * r2, false);
    }
}

function icone_queijo(_x, _y, _on)
{
    draw_set_colour(col(_on ? 0xffd23f : 0x2a3040));
    draw_triangle(_x - 5, _y + 3, _x + 5, _y + 3, _x + 5, _y - 2, false);
    draw_triangle(_x - 5, _y + 3, _x + 5, _y - 2, _x - 5, _y - 4, false);
    if (_on) rc(_x - 2, _y, 2, 2, 0xc8921a);
    else { draw_set_colour(col(0x556666)); draw_line(_x - 5, _y + 3, _x + 5, _y + 3); }
}
