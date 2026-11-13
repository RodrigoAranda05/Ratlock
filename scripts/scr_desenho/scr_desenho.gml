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
    global.fonte = -1;
    global.fonte_largura = 1;
    // Poppins Bold vem junto do jogo (Included Files); se não achar, usa a Arial do sistema
    if (file_exists(working_directory + "Poppins-Bold.ttf"))
    {
        global.fonte = font_add(working_directory + "Poppins-Bold.ttf", 28, false, false, 32, 255);
        global.fonte_largura = 0.9;
    }
    if (global.fonte == -1) global.fonte = font_add("Arial", 28, true, false, 32, 255);
    if (global.fonte == -1) { global.fonte_escala = 1; return; }
    draw_set_font(global.fonte);
    global.fonte_escala = altura_padrao / max(1, string_height("Ag"));
    draw_set_font(-1);
}

function escala_texto(_z)
{
    return (_z / 13) * global.fonte_escala * global.fonte_largura;
}

function largura_texto(_s, _z)
{
    draw_set_font(global.fonte);
    var w = string_width(_s) * escala_texto(_z);
    draw_set_font(-1);
    return w;
}

// desenhar texto: só na GUI (obj_ui Draw GUI), onde a matriz já amplia o layout 480x272
function desenha_texto(_s, _x, _y, _c, _al, _z, _maxw = 0)
{
    var sc = escala_texto(_z);
    draw_set_font(global.fonte);
    if (_maxw > 0)
    {
        var lw = string_width(_s) * sc;
        if (lw > _maxw) sc *= _maxw / lw;      // texto maior que o botão: encolhe para caber
    }
    if (_al == "center") draw_set_halign(fa_center);
    else if (_al == "right") draw_set_halign(fa_right);
    else draw_set_halign(fa_left);
    draw_set_valign(fa_middle);
    // o jogo desliga o filtro de textura (pixel perfeito), mas a fonte vetorial precisa dele para não serrilhar
    gpu_set_texfilter(true);
    var claro = (((_c >> 16) & 255) + ((_c >> 8) & 255) + (_c & 255)) > 330;
    if (claro)
    {
        draw_set_colour(c_black);
        var al0 = draw_get_alpha();
        draw_set_alpha(al0 * 0.6);
        draw_text_transformed(_x + 0.5, _y + 0.7, _s, sc, sc, 0);
        draw_set_alpha(al0);
    }
    draw_set_colour(cor_rgb(_c));
    draw_text_transformed(_x, _y, _s, sc, sc, 0);
    draw_set_colour(c_white);
    gpu_set_texfilter(false);
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

// painel arredondado semitransparente do HUD (layout 480x272)
function desenha_painel(_x, _y, _w, _h, _alfa = 0.82, _borda = 0x3b4a63)
{
    draw_set_alpha(_alfa);
    draw_set_colour(cor_rgb(0x0b1019));
    draw_roundrect_ext(_x, _y, _x + _w, _y + _h, 6, 6, false);
    draw_set_alpha(min(1, _alfa + 0.1));
    draw_set_colour(cor_rgb(_borda));
    draw_roundrect_ext(_x, _y, _x + _w, _y + _h, 6, 6, true);
    draw_set_alpha(1);
    draw_set_colour(c_white);
}

// ---------- visual dos menus ----------
// fundo dos menus: degradê escuro com um fio dourado no topo
function desenha_fundo_menu(_a)
{
    draw_set_alpha(_a);
    draw_rectangle_colour(0, 0, VW, VH, cor_rgb(0x0b111b), cor_rgb(0x0b111b), cor_rgb(0x03060b), cor_rgb(0x03060b), false);
    draw_set_alpha(1);
    desenha_rect_alfa(0, 0, VW, 1, 0xffd84a, 0.35 * _a);
}

// rodapé com as teclas: [["Enter", "jogar"], ["Esc", "voltar"]]
function desenha_dicas(_y, _itens)
{
    var n = array_length(_itens);
    var larg = 0;
    for (var k = 0; k < n; k++) larg += largura_texto(_itens[k][0], 8) + 10 + 4 + largura_texto(_itens[k][1], 8) + 12;
    var xx = (VW - larg + 12) / 2;
    for (var k = 0; k < n; k++)
    {
        var wt = largura_texto(_itens[k][0], 8) + 10;
        desenha_painel(xx, _y - 6, wt, 12, 0.9, 0x4a5a78);
        desenha_texto(_itens[k][0], xx + wt / 2, _y + 0.5, 0xffd84a, "center", 8);
        xx += wt + 4;
        desenha_texto(_itens[k][1], xx, _y + 0.5, 0x9aa7bd, "left", 8);
        xx += largura_texto(_itens[k][1], 8) + 12;
    }
}

// título de seção com fio dourado embaixo
function desenha_titulo_secao(_texto, _y, _tam = 18)
{
    var w = largura_texto(_texto, _tam);
    desenha_texto(_texto, VW / 2, _y, 0xffd84a, "center", _tam);
    desenha_rect_alfa(VW / 2 - w / 2 - 6, _y + _tam * 0.75, w + 12, 1, 0xffd84a, 0.45);
}

// partícula redonda: faísca = risco com brilho aditivo; poeira = bolinha que cresce e some
function desenha_particula(_f)
{
    var vida = clamp(_f.l / _f.l0, 0, 1);
    if (_f.k == "f")
    {
        var a = min(1, vida * 2);
        gpu_set_blendmode(bm_add);
        var e = (0.07 + 0.09 * vida);
        draw_sprite_ext(spr_brilho, 0, _f.x, _f.y, e, e, 0, cor_rgb(_f.c), a * 0.9);
        gpu_set_blendmode(bm_normal);
        draw_set_alpha(a);
        draw_set_colour(cor_rgb(_f.c));
        draw_line_width(_f.x, _f.y, _f.x - _f.vx * 0.03, _f.y - _f.vy * 0.03, 1);
    }
    else if (_f.k == "a")
    {
        // gota: 1x2 subindo/caindo, vira ponto no fim
        var px = floor(_f.x), py = floor(_f.y);
        desenha_rect(px, py, 1, (vida > 0.3) ? 2 : 1, _f.c);
    }
    else if (_f.k == "b")
    {
        // bolha: anel de 3x3 que balança um pouco e estoura (vira ponto) no fim
        var bx = floor(_f.x + sin(_f.l * 18)), by = floor(_f.y);
        if (vida > 0.2)
        {
            desenha_rect(bx + 1, by, 1, 1, _f.c); desenha_rect(bx, by + 1, 1, 1, _f.c);
            desenha_rect(bx + 2, by + 1, 1, 1, _f.c); desenha_rect(bx + 1, by + 2, 1, 1, _f.c);
        }
        else desenha_rect(bx + 1, by + 1, 1, 1, 0xffffff);
    }
    else if (_f.k == "o")
    {
        // ondinha: dois traços que se afastam do centro e piscam ao sumir
        var meio = floor(_f.x), py = floor(_f.y);
        var ab = floor((1 - vida) * 13) + 2;
        if (vida > 0.25 || floor(_f.l * 30) % 2 == 0)
        {
            desenha_rect(meio - ab - 2, py, 3, 1, _f.c);
            desenha_rect(meio + ab, py, 3, 1, _f.c);
        }
    }
    else
    {
        // poeira em pixel art: cruzinha clara, depois quadradinho, depois um ponto escuro (sem círculos nem transparência)
        var px = floor(_f.x), py = floor(_f.y);
        if (vida > 0.62)
        {
            desenha_rect(px, py - 1, 1, 3, _f.c);
            desenha_rect(px - 1, py, 3, 1, _f.c);
        }
        else if (vida > 0.3) desenha_rect(px, py, 2, 2, _f.c);
        else desenha_rect(px, py, 1, 1, 0x7a8494);
    }
    draw_set_alpha(1);
    draw_set_colour(c_white);
}

// espinho virado para uma das 4 direções (0 cima, 1 baixo, 2 esquerda, 3 direita); o sprite original aponta para cima
function desenha_espinho(_x, _y, _dir, _esc = 1, _alfa = 1)
{
    var s = 16 * _esc;
    switch (_dir)
    {
        case 1: draw_sprite_ext(spr_espinho, 0, _x + s, _y + s, _esc, _esc, 180, c_white, _alfa); break;
        case 2: draw_sprite_ext(spr_espinho, 0, _x, _y + s, _esc, _esc, 90, c_white, _alfa); break;
        case 3: draw_sprite_ext(spr_espinho, 0, _x + s, _y, _esc, _esc, 270, c_white, _alfa); break;
        default: draw_sprite_ext(spr_espinho, 0, _x, _y, _esc, _esc, 0, c_white, _alfa); break;
    }
}

function faiscas(_x, _y, _n)
{
    for (var i = 0; i < _n; i++)
    {
        array_push(global.particulas, {
            x: _x, y: _y,
            vx: (random(1) - 0.5) * 90,
            vy: -random(1) * 80,
            l: 0.5, l0: 0.5, g: 300, t: 2, k: "f",
            c: (random(1) < 0.5) ? 0xffd84a : 0xffffff
        });
    }
}

// poeira no chão (pulo, pouso, virar, arrastar caixa). _dir: -1/1 sopra para esse lado, 0 abre para os dois lados
function poeira(_x, _y, _dir, _n)
{
    for (var i = 0; i < _n; i++)
    {
        var lado = (_dir != 0) ? _dir : ((random(1) < 0.5) ? -1 : 1);
        array_push(global.particulas, {
            x: _x + (random(1) - 0.5) * 6, y: _y - 1 - random(1) * 2,
            vx: lado * (18 + random(1) * 30),
            vy: -(1 + random(1) * 7),
            l: 0.3 + random(1) * 0.22, l0: 0.5, g: 40, t: 2 + random(1) * 1.5, k: "p",
            c: (random(1) < 0.5) ? 0xc9d0da : 0x8f99a8
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

// duração em horas:minutos:segundos (ex.: 1:05:09)
function formata_duracao(_t)
{
    var h = floor(_t / 3600);
    var m = floor((_t % 3600) / 60);
    var s = floor(_t % 60);
    return string(h) + ":" + ((m < 10) ? "0" : "") + string(m) + ":" + ((s < 10) ? "0" : "") + string(s);
}

// barra de progresso: _f de 0 a 1
function desenha_barra(_x, _y, _w, _h, _f, _c)
{
    desenha_rect(_x, _y, _w, _h, 0x10141b);
    desenha_rect(_x, _y, floor(_w * clamp(_f, 0, 1)), _h, _c);
}

#region mapa estilo "overworld"

// fundo ilustrado de uma tela: _quadro do spr_fundo_tela (0 estatísticas, 1 configurações, 2 vitória)
function desenha_fundo_tela(_quadro, _a = 1)
{
    // reaproveita o mesmo fundo da tela inicial (a cela à noite) e põe um véu escuro para leitura
    draw_sprite(spr_fundo_menu, 0, 0, 0);
    desenha_rect_alfa(0, 0, VW, VH, 0x05080f, 0.7 * _a);
}

// posição do nó _i de _n no mapa: um caminho em zigue-zague da esquerda para a direita
function pos_no_mapa(_i, _n)
{
    var u = (_n <= 1) ? 0.5 : _i / (_n - 1);
    var xx = 58 + u * 364;
    var yy = 128 + ((_i % 2 == 0) ? 38 : -38) + sin(_i * 2.1) * 10;
    return [round(xx), round(yy)];
}

// trilha de quadradinhos entre os nós; _ate = último nó já aberto (a trilha depois dele fica cinza)
function desenha_trilha_mapa(_n, _ate)
{
    for (var i = 0; i < _n - 1; i++)
    {
        var a = pos_no_mapa(i, _n), b = pos_no_mapa(i + 1, _n);
        var d = point_distance(a[0], a[1], b[0], b[1]);
        var passos = floor(d / 6);
        var aberta = (i + 1 <= _ate);
        for (var s = 1; s < passos; s++)
        {
            var u = s / passos;
            var px = round(lerp(a[0], b[0], u)), py = round(lerp(a[1], b[1], u));
            desenha_rect(px - 2, py - 1, 5, 4, 0x0c0912);
            desenha_rect(px - 2, py - 2, 4, 4, aberta ? 0xa89a82 : 0x4a4f5c);
            desenha_rect(px - 2, py - 2, 4, 1, aberta ? 0xd2c4a6 : 0x626878);
        }
    }
}

// nó do mapa em tema de prisão: porta de cela com grades (fase) ou bloco de celas com ameias (mundo).
// _estado: 0 bloqueado (cadeado), 1 aberto, 2 concluído (porta aberta + estrela); _cor = cor do mundo
function desenha_no_mapa(_x, _y, _rot, _estado, _sel, _cor, _mundo = false)
{
    var w = _mundo ? 32 : 22, h = _mundo ? 26 : 24;
    var oy = _sel ? -abs(sin(global.tempo_jogo * 6)) * 2 : 0;
    var x0 = _x - w / 2, y0 = _y - h / 2 + oy;
    desenha_rect_alfa(x0 + 1, _y + h / 2 - 1, w + 2, 4, 0x000000, 0.35);
    if (_estado == 1 || _estado == 2)
    {
        // luz da cela espalhada no chão
        desenha_rect_alfa(x0 - 3, y0 - 3, w + 6, h + 6, _cor, _sel ? 0.28 : 0.14);
    }
    var pedra = (_estado == 0) ? 0x3a3f4a : 0x6a6178;
    if (_mundo)
    {
        // ameias no topo
        for (var q = 0; q < 4; q++) { desenha_rect(x0 - 2 + q * 9, y0 - 7, 6, 6, 0x0c0912); desenha_rect(x0 - 1 + q * 9, y0 - 6, 4, 5, pedra); }
        // bandeirinha da cor do mundo
        desenha_rect(_x, y0 - 14, 1, 8, 0x0c0912);
        desenha_rect(_x + 1, y0 - 14, 6, 4, (_estado == 0) ? 0x4a5568 : _cor);
    }
    desenha_rect(x0 - 2, y0 - 2, w + 4, h + 4, 0x0c0912);
    desenha_rect(x0 - 1, y0 - 1, w + 2, h + 2, pedra);
    desenha_rect(x0 - 1, y0 - 1, w + 2, 1, mix_cor(pedra, 0.3));
    desenha_rect(x0 - 1, y0 + h, w + 2, 1, mix_cor(pedra, -0.4));
    var fundo = (_estado == 0) ? 0x232834 : ((_estado == 2) ? 0x120c1c : mix_cor(_cor, -0.45));
    desenha_rect(x0 + 2, y0 + 2, w - 4, h - 4, fundo);
    if (_estado == 1) desenha_rect(x0 + 3, y0 + 3, w - 6, 3, mix_cor(_cor, -0.2));
    // grades de ferro (na cela concluída a porta ficou aberta: só uma barra encostada na lateral)
    if (_estado == 2)
    {
        desenha_rect(x0 + 2, y0 + 2, 2, h - 4, 0x4a4558);
        desenha_rect(x0 + 2, y0 + 2, 1, h - 4, 0x7a7390);
    }
    else
    {
        for (var bx = x0 + 4; bx < x0 + w - 3; bx += 4)
        {
            desenha_rect(bx, y0 + 2, 2, h - 4, (_estado == 0) ? 0x14171e : 0x0a0710);
            desenha_rect(bx, y0 + 2, 1, h - 4, (_estado == 0) ? 0x3a404e : 0x5a5470);
        }
        desenha_rect(x0 + 2, y0 + h / 2 - 1, w - 4, 2, (_estado == 0) ? 0x14171e : 0x0a0710);
    }
    if (_sel)
    {
        var p = (floor(global.tempo_jogo * 5) % 2 == 0);
        var c = p ? 0xffffff : 0xffd84a;
        desenha_rect(x0 - 5, y0 - 5, w + 10, 1, c); desenha_rect(x0 - 5, y0 + h + 4, w + 10, 1, c);
        desenha_rect(x0 - 5, y0 - 5, 1, h + 10, c); desenha_rect(x0 + w + 4, y0 - 5, 1, h + 10, c);
    }
    if (_estado == 0)
    {
        // cadeado
        desenha_rect(_x - 4, _y + oy - 1, 9, 7, 0x8a7a50);
        desenha_rect(_x - 4, _y + oy - 1, 9, 1, 0xc8b878);
        desenha_rect(_x - 3, _y + oy - 5, 1, 4, 0xa0a0b0); desenha_rect(_x + 3, _y + oy - 5, 1, 4, 0xa0a0b0);
        desenha_rect(_x - 3, _y + oy - 6, 7, 1, 0xa0a0b0);
        desenha_rect(_x, _y + oy + 2, 1, 2, 0x1c1408);
    }
    else
    {
        // plaquinha com o número
        desenha_rect(_x - 6, _y + oy - 5, 12, 11, 0x0c0912);
        desenha_rect(_x - 5, _y + oy - 4, 10, 9, 0x2a2438);
        desenha_texto(_rot, _x, _y + oy, (_estado == 2) ? 0xffd84a : 0xf3efe6, "center", 11);
        if (_estado == 2) desenha_estrela(x0 + w - 3, y0 + 1, true);
    }
}

// clareia/escurece uma cor 0xRRGGBB (k de -1 a 1)
function mix_cor(_c, _k)
{
    var r = (_c >> 16) & 255, g = (_c >> 8) & 255, b = _c & 255;
    if (_k >= 0) { r += (255 - r) * _k; g += (255 - g) * _k; b += (255 - b) * _k; }
    else { r *= 1 + _k; g *= 1 + _k; b *= 1 + _k; }
    return (floor(r) << 16) | (floor(g) << 8) | floor(b);
}

// o rato que anda pelo mapa (global.mapa guarda a posição suave)
function desenha_rato_mapa(_esc = 1)
{
    var m = global.mapa;
    var spr = m.anda ? spr_rato_andando : spr_rato_parado;
    var idx = m.anda ? floor(global.tempo_jogo * 10) % 4 : floor(global.tempo_jogo * 2) % 2;
    var pulo = m.anda ? -abs(sin(global.tempo_jogo * 16)) * 2 : 0;
    desenha_rect_alfa(m.rx - 6, m.ry + 1, 12, 2, 0x000000, 0.3);
    draw_sprite_ext(spr, idx, m.rx, m.ry + pulo, m.face * _esc, _esc, 0, c_white, 1);
}

// faixa de informações embaixo do mapa
function desenha_faixa_mapa(_titulo, _sub, _y = 216)
{
    desenha_hex(50, _y, 380, 38, 0x1a2540, 0x0b1222, 0.9, 14);
    desenha_hex_borda(50, _y, 380, 38, 0xffd84a, 0.9, 2, 14);
    desenha_rect_alfa(64, _y + 1, 352, 1, 0xffffff, 0.3);
    desenha_texto(_titulo, VW / 2, _y + 12, 0xffd84a, "center", 13, 340);
    desenha_texto(_sub, VW / 2, _y + 27, 0xc4cee0, "center", 9, 340);
}

// popup de confirmação para fechar o jogo (Esc na tela inicial)
function desenha_popup_sair()
{
    // véu escuro em cima do menu
    desenha_rect_alfa(0, 0, VW, VH, 0x03060e, 0.72);
    // caixa escura e plana com borda dourada (mesmo clima do menu principal)
    var bx = 110, by = 74, bw = 260, bh = 112;
    desenha_rect_alfa(bx, by, bw, bh, 0x0a0e1a, 0.96);
    desenha_rect(bx, by, bw, 1, 0xffd84a);
    desenha_rect(bx, by + bh - 1, bw, 1, 0xffd84a);
    desenha_rect(bx, by, 1, bh, 0xffd84a);
    desenha_rect(bx + bw - 1, by, 1, bh, 0xffd84a);
    desenha_rect_alfa(bx + 1, by + 1, bw - 2, 1, 0xffffff, 0.22);
    // título e subtítulo
    desenha_texto("SAIR DO JOGO?", VW / 2, by + 24, 0xffd84a, "center", 15, bw - 20);
    desenha_rect_alfa(bx + 60, by + 38, bw - 120, 1, 0xffd84a, 0.5);
    desenha_texto("Você volta para o desktop.", VW / 2, by + 52, 0xc4cee0, "center", 9, bw - 20);
    // SIM / NÃO no estilo da home: losango dourado + sublinhado na escolha
    var opcoes = ["SIM", "NÃO"];
    var xs = [bx + 80, bx + 160];
    var ty = by + 80;
    for (var k = 0; k < 2; k++)
    {
        var sel = (global.sair_op == k);
        var tx = xs[k];
        if (sel)
        {
            var cx = tx - 12, cy = ty + 6;
            draw_set_colour(cor_rgb(0xffd84a));
            draw_primitive_begin(pr_trianglelist);
            draw_vertex(cx, cy - 6); draw_vertex(cx + 6, cy); draw_vertex(cx - 6, cy);
            draw_vertex(cx - 6, cy); draw_vertex(cx + 6, cy); draw_vertex(cx, cy + 6);
            draw_primitive_end();
            draw_set_colour(cor_rgb(0x1a1630));
            draw_primitive_begin(pr_trianglelist);
            draw_vertex(cx, cy - 2); draw_vertex(cx + 2, cy); draw_vertex(cx - 2, cy);
            draw_vertex(cx - 2, cy); draw_vertex(cx + 2, cy); draw_vertex(cx, cy + 2);
            draw_primitive_end();
            draw_set_colour(c_white);
            desenha_texto(opcoes[k], tx, ty + 6, 0xffd84a, "left", 12);
            desenha_rect(floor(tx), floor(ty + 14), floor(largura_texto(opcoes[k], 12)), 1, 0xffd84a);
        }
        else desenha_texto(opcoes[k], tx, ty + 6, 0xa9b4c4, "left", 11);
    }
}

// controle deslizante de volume (0 a 1) em 10 blocos
function desenha_slider(_x, _y, _v, _cor)
{
    var cheios = round(_v * 10);
    for (var k = 0; k < 10; k++)
    {
        var on = (k < cheios);
        var xx = _x + k * 17;
        desenha_rect(xx, _y, 14, 10, on ? mix_cor(_cor, -0.45) : 0x1a2233);
        desenha_rect(xx, _y, 14, 8, on ? _cor : 0x232d42);
        if (on) desenha_rect(xx, _y, 14, 2, mix_cor(_cor, 0.45));
    }
}

#endregion

#region água: respingos

// y da superfície da poça que contém o ponto, ou -1 se o ponto está fora da água
function superficie_agua(_px, _py)
{
    var i = floor(_px / TL), j = floor(_py / TL);
    if (tile_em(i, j) != "m") return -1;
    while (j > 0 && tile_em(i, j - 1) == "m") j--;
    return j * TL + 3;
}

// respingo em pixel art: gotas que sobem e caem + duas ondinhas abrindo na superfície (_forca de 0 a 1)
function espirra(_x, _y, _forca)
{
    var f = clamp(_forca, 0.25, 1);
    var n = 7 + floor(f * 12);
    for (var i = 0; i < n; i++)
    {
        array_push(global.particulas, {
            x: _x + (random(1) - 0.5) * 8, y: _y,
            vx: (random(1) - 0.5) * 80 * (0.5 + f),
            vy: -(50 + random(1) * 110) * (0.5 + f * 0.8),
            l: 0.5 + random(1) * 0.3, l0: 0.7, g: 380, t: 1, k: "a",
            c: (random(1) < 0.5) ? 0xdff2ff : 0x7ec0ff
        });
    }
    array_push(global.particulas, {x: _x, y: _y + 1, vx: 0, vy: 0, l: 0.55, l0: 0.55, g: 0, t: 1, k: "o", c: 0xdff2ff});
    array_push(global.particulas, {x: _x, y: _y + 1, vx: 0, vy: 0, l: 0.4, l0: 0.4, g: 0, t: 1, k: "o", c: 0x7ec0ff});
}

// pé/caixa se mexendo na água: ondinha na superfície, gotinhas e uma bolha que sobe
function chapinha(_x, _y)
{
    array_push(global.particulas, {x: _x, y: _y + 1, vx: 0, vy: 0, l: 0.35, l0: 0.35, g: 0, t: 1, k: "o", c: 0xdff2ff});
    if (random(1) < 0.7)
    {
        array_push(global.particulas, {
            x: _x + (random(1) - 0.5) * 6, y: _y, vx: (random(1) - 0.5) * 40, vy: -(25 + random(1) * 40),
            l: 0.35, l0: 0.5, g: 300, t: 1, k: "a", c: (random(1) < 0.5) ? 0xdff2ff : 0x7ec0ff
        });
    }
    if (random(1) < 0.45)
    {
        array_push(global.particulas, {
            x: _x + (random(1) - 0.5) * 8, y: _y + 5, vx: 0, vy: -(12 + random(1) * 10),
            l: 0.6 + random(1) * 0.4, l0: 1.0, g: 0, t: 1, k: "b", c: 0xbfe4ff
        });
    }
}

#endregion


#region seletor de fases estilo "cartões" (Super Meat Boy)
// ícone de fase da fileira de cima do seletor; _est 0 bloqueado, 1 aberto, 2 concluído; _est3 = estrelas (0 a 3)
function desenha_icone_fase(_x, _y, _num, _est, _sel, _est3)
{
    var w = 28, h = 26;
    var oy = _sel ? -3 - abs(sin(global.tempo_jogo * 5)) * 1.2 : 0;
    var x0 = _x - w / 2, y0 = _y - h / 2 + oy;
    desenha_rect_alfa(x0 + 1, _y + h / 2 - 2, w, 4, 0x000000, 0.4);
    desenha_rect(x0 - 2, y0 - 2, w + 4, h + 4, _sel ? 0xffd84a : 0x0c0912);
    desenha_rect(x0 - 1, y0 - 1, w + 2, h + 2, 0x0c0912);
    var corpo = (_est == 0) ? 0x3a3f4a : ((_est == 2) ? 0x5e5a78 : 0x4a4a68);
    if (_sel) corpo = mix_cor(corpo, 0.25);
    desenha_rect(x0, y0, w, h, corpo);
    desenha_rect(x0, y0, w, 2, mix_cor(corpo, 0.3));
    desenha_rect(x0, y0 + h - 2, w, 2, mix_cor(corpo, -0.35));
    if (_est == 0)
    {
        desenha_rect(_x - 4, _y - 1, 8, 7, 0x1c2029);
        desenha_rect(_x - 3, _y - 5, 1, 5, 0x1c2029); desenha_rect(_x + 2, _y - 5, 1, 5, 0x1c2029); desenha_rect(_x - 3, _y - 6, 6, 1, 0x1c2029);
    }
    else
    {
        desenha_texto(string(_num), _x, y0 + ((_est == 2) ? 10 : 13), _sel ? 0xffd84a : 0xf3efe6, "center", 12);
        if (_est == 2) for (var q = 0; q < 3; q++) desenha_rect(_x - 7 + q * 5, y0 + h - 7, 4, 4, (q < _est3) ? 0xffd84a : 0x2a2f3a);
    }
}

// quadro com a miniatura (quadro _fi do spr_previa) da fase escolhida
function desenha_previa_fase(_fi, _bloq, _a)
{
    var x0 = 80, y0 = 42;
    desenha_rect(x0 - 3, y0 - 3, 326, 182, 0x0c0912);
    desenha_rect(x0 - 2, y0 - 2, 324, 180, _bloq ? 0x4a5a78 : 0xffd84a);
    desenha_rect(x0 - 1, y0 - 1, 322, 178, 0x0c0912);
    draw_set_alpha(_a);
    draw_sprite(spr_previa, _fi, x0, y0);
    draw_set_alpha(1);
    if (_bloq)
    {
        desenha_rect_alfa(x0, y0, 320, 176, 0x05080f, 0.78);
        var cx = x0 + 160, cy = y0 + 76;
        desenha_rect(cx - 12, cy - 4, 24, 20, 0x7b808c); desenha_rect(cx - 12, cy - 4, 24, 3, 0xa9aeb8); desenha_rect(cx - 3, cy + 4, 6, 7, 0x1c2029);
        desenha_rect(cx - 9, cy - 18, 4, 15, 0x7b808c); desenha_rect(cx + 5, cy - 18, 4, 15, 0x7b808c); desenha_rect(cx - 9, cy - 20, 18, 4, 0x7b808c);
        desenha_texto("FASE BLOQUEADA", VW / 2, cy + 34, 0xf3efe6, "center", 12);
        desenha_texto("Termine a fase anterior", VW / 2, cy + 48, 0x9aa7bd, "center", 9);
    }
}

// faixa de título no alto: nome do mundo + porcentagem de conclusão
function desenha_banner(_titulo, _sub, _pct)
{
    desenha_rect(0, 0, VW, 34, 0x0c0912);
    desenha_rect(0, 34, VW, 2, 0xffd84a);
    desenha_rect_alfa(0, 36, VW, 4, 0x000000, 0.35);
    desenha_texto(_titulo, 14, 13, 0xf3efe6, "left", 16);
    desenha_texto(_sub, 14, 27, 0x9aa7bd, "left", 8);
    if (_pct >= 0)
    {
        desenha_texto(string(round(_pct * 100)) + "%", VW - 14, 13, 0xffd84a, "right", 16);
        desenha_rect(VW - 110, 24, 96, 5, 0x232d42);
        desenha_rect(VW - 110, 24, round(96 * _pct), 5, 0xffd84a);
    }
}

// barra preta de informações embaixo (nome da fase + dados)
function desenha_barra_info(_titulo, _sub)
{
    desenha_rect(0, 212, VW, 34, 0x0c0912);
    desenha_rect(0, 210, VW, 2, 0xffd84a);
    desenha_texto(_titulo, 14, 224, 0xf3efe6, "left", 13);
    desenha_texto(_sub, 14, 238, 0x9aa7bd, "left", 9);
}

#endregion

// desenha o sprite com o filtro azul só na parte que está dentro da água (_agua_y = superfície, -1 = fora da água)
function desenha_sprite_agua(_spr, _idx, _x, _y, _xs, _ys, _al, _agua_y)
{
    var sxo = sprite_get_xoffset(_spr), syo = sprite_get_yoffset(_spr), sw = sprite_get_width(_spr), sh = sprite_get_height(_spr);
    var corte = (_agua_y < 0) ? sh : clamp((_agua_y - _y) / _ys + syo, 0, sh);
    var dx = _x - sxo * _xs, dy = _y - syo * _ys;
    if (corte >= sh) { draw_sprite_ext(_spr, _idx, _x, _y, _xs, _ys, 0, c_white, _al); return; }
    if (corte > 0) draw_sprite_part_ext(_spr, _idx, 0, 0, sw, corte, dx, dy, _xs, _ys, c_white, _al);
    draw_sprite_part_ext(_spr, _idx, 0, corte, sw, sh - corte, dx, dy + corte * _ys, _xs, _ys, 0xffb870, _al * 0.85);
}


#region visual "central de corridas": botões hexagonais, faixas diagonais e painéis translúcidos
// hexágono achatado (retângulo com as pontas em bico) com degradê de cima (_c1) para baixo (_c2); _cham = largura do bico
function desenha_hex(_x, _y, _w, _h, _c1, _c2, _a, _cham = -1)
{
    var c = (_cham < 0) ? _h * 0.5 : _cham;
    var cy = _y + _h / 2;
    var k1 = cor_rgb(_c1), k2 = cor_rgb(_c2), km = cor_rgb(mix_cor_entre(_c1, _c2, 0.5));
    draw_primitive_begin(pr_trianglelist);
    draw_vertex_colour(_x + c, _y, k1, _a); draw_vertex_colour(_x + _w - c, _y, k1, _a); draw_vertex_colour(_x + _w, cy, km, _a);
    draw_vertex_colour(_x + c, _y, k1, _a); draw_vertex_colour(_x + _w, cy, km, _a); draw_vertex_colour(_x, cy, km, _a);
    draw_vertex_colour(_x, cy, km, _a); draw_vertex_colour(_x + _w, cy, km, _a); draw_vertex_colour(_x + _w - c, _y + _h, k2, _a);
    draw_vertex_colour(_x, cy, km, _a); draw_vertex_colour(_x + _w - c, _y + _h, k2, _a); draw_vertex_colour(_x + c, _y + _h, k2, _a);
    draw_primitive_end();
}

function mix_cor_entre(_a, _b, _k)
{
    var r = lerp((_a >> 16) & 255, (_b >> 16) & 255, _k), g = lerp((_a >> 8) & 255, (_b >> 8) & 255, _k), b = lerp(_a & 255, _b & 255, _k);
    return (floor(r) << 16) | (floor(g) << 8) | floor(b);
}

// contorno do hexágono
function desenha_hex_borda(_x, _y, _w, _h, _cor, _a, _larg = 1, _cham = -1)
{
    var c = (_cham < 0) ? _h * 0.5 : _cham;
    var cy = _y + _h / 2;
    draw_set_alpha(_a);
    draw_set_colour(cor_rgb(_cor));
    draw_line_width(_x + c, _y, _x + _w - c, _y, _larg);
    draw_line_width(_x + _w - c, _y, _x + _w, cy, _larg);
    draw_line_width(_x + _w, cy, _x + _w - c, _y + _h, _larg);
    draw_line_width(_x + _w - c, _y + _h, _x + c, _y + _h, _larg);
    draw_line_width(_x + c, _y + _h, _x, cy, _larg);
    draw_line_width(_x, cy, _x + c, _y, _larg);
    draw_set_alpha(1);
    draw_set_colour(c_white);
}

// colchetes "<" ">" dourados nas pontas do botão escolhido
// (setinhas nas laterais removidas a pedido; a função fica vazia para não quebrar chamadas antigas)
function desenha_colchetes(_x, _y, _w, _h, _a = 1)
{
}

// botão claro de vidro (não escolhido): branco translúcido com brilho no alto
function desenha_botao_vidro(_x, _y, _w, _h, _a = 0.9)
{
    desenha_rect_alfa(_x + 3, _y + _h - 1, _w - 4, 3, 0x000000, 0.35 * _a);
    desenha_hex(_x, _y, _w, _h, 0xf6f8fd, 0xbac3d6, _a);
    desenha_hex_borda(_x, _y, _w, _h, 0xffffff, 0.8 * _a);
    desenha_rect_alfa(_x + _h * 0.5, _y + 2, _w - _h, 1, 0xffffff, 0.8 * _a);
}

// botão dourado (escolhido)
function desenha_botao_ouro(_x, _y, _w, _h)
{
    desenha_rect_alfa(_x + 3, _y + _h, _w - 4, 4, 0x000000, 0.4);
    desenha_hex(_x, _y, _w, _h, 0xfff2a0, 0xf0a800, 1);
    desenha_hex_borda(_x, _y, _w, _h, 0xfff9d0, 0.9);
    desenha_rect_alfa(_x + _h * 0.5, _y + 2, _w - _h, 2, 0xffffff, 0.55);
}

// opção de menu (usada em configurações etc.): selecionada = ouro, as outras = vidro
function desenha_opcao_menu(_y, _texto, _sel)
{
    // estilo da home: losango dourado + sublinhado quando selecionado
    var al = largura_texto(_texto, 12);
    var tx = VW / 2 - al / 2;
    var cx = tx - 10, cy = _y + 8;
    if (_sel)
    {
        draw_set_colour(cor_rgb(0xffd84a));
        draw_primitive_begin(pr_trianglelist);
        draw_vertex(cx, cy - 6); draw_vertex(cx + 6, cy); draw_vertex(cx - 6, cy);
        draw_vertex(cx - 6, cy); draw_vertex(cx + 6, cy); draw_vertex(cx, cy + 6);
        draw_primitive_end();
        draw_set_colour(cor_rgb(0x1a1630));
        draw_primitive_begin(pr_trianglelist);
        draw_vertex(cx, cy - 2); draw_vertex(cx + 2, cy); draw_vertex(cx - 2, cy);
        draw_vertex(cx - 2, cy); draw_vertex(cx + 2, cy); draw_vertex(cx, cy + 2);
        draw_primitive_end();
        draw_set_colour(c_white);
        desenha_texto(_texto, tx, cy, 0xffd84a, "left", 12);
        desenha_rect(floor(tx), floor(cy + 8), floor(al), 1, 0xffd84a);
    }
    else desenha_texto(_texto, VW / 2, cy, 0xa9b4c4, "center", 11);
}

// lista vertical de botões à esquerda; o ouro desliza (sem pulos) até a opção escolhida
function desenha_lista_hex(_x, _y0, _passo, _w, _h, _textos, _cur)
{
    // estilo da home: lista com losango dourado e sublinhado na escolha (unificação visual)
    desenha_menu_home(_x, _y0 - _h / 2 + 4, _passo, _textos, _cur);
}


// versão centralizada (telas com poucas opções)
function desenha_lista_menu(_y0, _passo, _textos, _cur)
{
    desenha_lista_hex(VW / 2 - 100, _y0, _passo, 200, _passo - 6, _textos, _cur);
}

// quadradinho de atalho (embaixo na tela inicial): vidro ou ouro
function desenha_atalho(_x, _y, _w, _h, _texto, _sel)
{
    var mw = _w - _h * 1.2;
    if (_sel) { desenha_botao_ouro(_x - 2, _y - 2, _w + 4, _h + 4); desenha_texto(_texto, _x + _w / 2, _y + _h / 2 + 0.5, 0x3a2600, "center", 10, mw); }
    else { desenha_botao_vidro(_x, _y, _w, _h, 0.85); desenha_texto(_texto, _x + _w / 2, _y + _h / 2 + 0.5, 0x242a3a, "center", 10, mw); }
}

// cartão de menu (linhas de configurações e estatísticas): hexágono escuro de vidro; escolhido = brilho e colchetes dourados
function desenha_cartao(_x, _y, _w, _h, _sel = false, _trava = false)
{
    var a = _trava ? 0.5 : 0.82;
    desenha_hex(_x, _y, _w, _h, _sel ? 0x34508a : 0x1a2540, _sel ? 0x1b2c52 : 0x0e1526, a, _h * 0.4);
    desenha_hex_borda(_x, _y, _w, _h, _sel ? 0xffd84a : 0xaebbd6, _sel ? 1 : 0.35, _sel ? 2 : 1, _h * 0.4);
    desenha_rect_alfa(_x + _h * 0.4, _y + 1, _w - _h * 0.8, 1, 0xffffff, _sel ? 0.45 : 0.15);
}

// faixas diagonais translúcidas que correm devagar + painel escuro à esquerda (tom _cor, ex.: azul-gelo)
function desenha_fundo_diag(_xt = 300, _xb = 360, _cor = 0x9fb8ff)
{
    // (painel diagonal substituído pelo véu uniforme para unificar com o menu principal)
}
function desenha_titulo_faixa(_texto, _sub = "")
{
    desenha_hex(-14, 10, largura_texto(_texto, 17) + 56, 24, 0xfff2a0, 0xf0a800, 1, 12);
    desenha_texto(_texto, 14, 22.5, 0x3a2600, "left", 17);
    if (_sub != "") desenha_texto(_sub, 16, 42, 0xb6c3dc, "left", 8);
}

// linha de ranking: _pos 0.. (medalhas nos três primeiros), _meu = corrida do jogador
function desenha_linha_rank(_x, _y, _w, _h, _pos, _meu)
{
    var med = [0xffd84a, 0xd8dee9, 0xe0955a];
    if (_meu) desenha_hex(_x - 3, _y - 2, _w + 6, _h + 4, 0xfff2a0, 0xf0a800, 0.95, _h * 0.4);
    else desenha_hex(_x, _y, _w, _h, 0xffffff, 0xb8c4dd, 0.16, _h * 0.4);
    desenha_hex_borda(_x, _y, _w, _h, _meu ? 0xfff9d0 : 0xffffff, _meu ? 0.9 : 0.3, 1, _h * 0.4);
    var cor = (_pos < 3) ? med[_pos] : 0x5d6a86;
    desenha_hex(_x + 3, _y + 2, 26, _h - 4, mix_cor(cor, 0.25), mix_cor(cor, -0.3), 1, (_h - 4) * 0.4);
    desenha_texto(string(_pos + 1), _x + 16, _y + _h / 2 + 0.5, 0x1b1b24, "center", 10);
}
#endregion

#region mapa de mundos "medalhões"

// cadeado desenhado em retângulos
function desenha_cadeado(_x, _y, _cor)
{
    desenha_rect(_x - 5, _y - 9, 10, 2, 0x10141b);
    desenha_rect(_x - 5, _y - 12, 2, 5, 0x10141b); desenha_rect(_x + 3, _y - 12, 2, 5, 0x10141b);
    desenha_rect(_x - 4, _y - 13, 8, 2, 0x10141b);
    desenha_rect(_x - 4, _y - 12, 1, 4, _cor); desenha_rect(_x + 3, _y - 12, 1, 4, _cor); desenha_rect(_x - 3, _y - 12, 6, 1, _cor);
    desenha_rect(_x - 7, _y - 8, 14, 11, 0x10141b);
    desenha_rect(_x - 6, _y - 7, 12, 9, _cor);
    desenha_rect(_x - 6, _y - 7, 12, 2, mix_cor(_cor, 0.35));
    desenha_rect(_x - 1, _y - 4, 2, 4, 0x10141b);
}

// cartão vertical de um mundo (seleção de mundo): cor do mundo, número gigante, nome, números de progresso
// _estado: 0 trancado, 1 aberto, 2 concluído; _perto: 0..1 quanto a moldura dourada está em cima deste cartão
function desenha_cartao_mundo(_x, _y, _w, _h, _num, _nome, _estado, _cor, _feitas, _total, _est, _estmax, _q, _qmax, _perto)
{
    var viva = (_estado > 0);
    var cx = _x + _w / 2;
    var c1 = viva ? mix_cor(_cor, 0.15 + _perto * 0.2) : 0x4a5266;
    var c2 = viva ? mix_cor(_cor, -0.6) : 0x151a26;
    desenha_rect_alfa(_x + 4, _y + _h + 1, _w - 8, 4, 0x000000, 0.4);
    desenha_hex(_x, _y, _w, _h, c1, c2, 0.96, 14);
    // faixa de luz em diagonal e número gigante apagado ao fundo
    draw_set_alpha(0.16);
    desenha_texto(_num, cx, _y + 54, 0xffffff, "center", 58);
    draw_set_alpha(1);
    desenha_rect_alfa(_x + 14, _y + 1, _w - 28, 2, 0xffffff, 0.4);
    desenha_hex_borda(_x, _y, _w, _h, 0xffffff, viva ? 0.4 : 0.2, 1, 14);
    if (viva) desenha_texto(_num, cx, _y + 34, 0xffffff, "center", 26);
    else desenha_cadeado(cx, _y + 44, 0xaab2c6);
    // nome numa plaquinha
    desenha_hex(_x + 6, _y + 72, _w - 12, 16, viva ? 0x10182c : 0x0c1019, viva ? 0x050810 : 0x050810, 0.85, 6);
    desenha_texto(_nome, cx, _y + 80.5, viva ? 0xffffff : 0x7d8798, "center", 10, _w - 22);
    if (viva)
    {
        draw_sprite(spr_estrela, 1, _x + 10, _y + 96);
        desenha_texto(string(_est) + "/" + string(_estmax), _x + 24, _y + 103, 0xffe9a0, "left", 9, _w - 34);
        desenha_icone_queijo(_x + 10, _y + 112, true);
        desenha_texto(string(_q) + "/" + string(_qmax), _x + 24, _y + 119, 0xffd27a, "left", 9, _w - 34);
        desenha_texto(string(_feitas) + "/" + string(_total) + " fases", cx, _y + _h - 17, 0xdbe3f4, "center", 8, _w - 12);
        desenha_rect(_x + 10, _y + _h - 10, _w - 20, 4, 0x080b14);
        desenha_rect(_x + 11, _y + _h - 9, floor((_w - 22) * clamp(_feitas / max(1, _total), 0, 1)), 2, (_estado == 2) ? 0x4ade80 : 0xffffff);
    }
    else desenha_texto("trancado", cx, _y + _h - 14, 0x7d8798, "center", 8, _w - 12);
    if (_estado == 2)
    {
        draw_set_colour(cor_rgb(0x0b1a10)); draw_circle(_x + _w - 10, _y + 10, 8, false);
        draw_set_colour(cor_rgb(0x4ade80)); draw_circle(_x + _w - 10, _y + 10, 6.5, false);
        draw_set_colour(cor_rgb(0x0b3a1c)); draw_line_width(_x + _w - 13, _y + 10, _x + _w - 11, _y + 12.5, 1.5); draw_line_width(_x + _w - 11, _y + 12.5, _x + _w - 7, _y + 7, 1.5);
        draw_set_colour(c_white);
    }
}

#endregion

#region morcegos e menu da home

// morcego pixel art (16x10 aprox) voando; fase 0 = asas para cima, fase 1 = asas para baixo
function desenha_morcego(_x, _y, _fase)
{
    var cb = 0xa070e0;    // corpo (lilás)
    var ce = 0x5a3890;    // sombra
    var co = 0x14081e;    // contorno escuro (olhos/boca linha)
    var ca = 0xffd84a;    // olho amarelo
    var ct = 0xf3efe6;    // presinha branca
    // orelhas
    desenha_rect(_x + 7, _y + 1, 2, 2, cb);
    desenha_rect(_x + 11, _y + 1, 2, 2, cb);
    desenha_rect(_x + 7, _y + 0, 1, 1, cb);
    desenha_rect(_x + 12, _y + 0, 1, 1, cb);
    // corpo
    desenha_rect(_x + 6, _y + 3, 8, 4, cb);
    desenha_rect(_x + 7, _y + 7, 6, 1, cb);
    desenha_rect(_x + 8, _y + 8, 4, 1, ce);
    // olhos e boca
    desenha_rect(_x + 8, _y + 4, 1, 1, ca);
    desenha_rect(_x + 11, _y + 4, 1, 1, ca);
    desenha_rect(_x + 9, _y + 6, 1, 1, ct);
    desenha_rect(_x + 10, _y + 6, 1, 1, ct);
    if (_fase == 0)
    {
        // asa esquerda levantada
        desenha_rect(_x + 0, _y + 3, 2, 1, cb);
        desenha_rect(_x + 1, _y + 2, 3, 1, cb);
        desenha_rect(_x + 2, _y + 1, 4, 1, cb);
        desenha_rect(_x + 3, _y + 0, 2, 1, cb);
        desenha_rect(_x + 4, _y + 2, 2, 1, ce);
        // asa direita levantada
        desenha_rect(_x + 18, _y + 3, 2, 1, cb);
        desenha_rect(_x + 16, _y + 2, 3, 1, cb);
        desenha_rect(_x + 14, _y + 1, 4, 1, cb);
        desenha_rect(_x + 15, _y + 0, 2, 1, cb);
        desenha_rect(_x + 14, _y + 2, 2, 1, ce);
    }
    else
    {
        // asas abaixadas
        desenha_rect(_x + 0, _y + 5, 2, 1, cb);
        desenha_rect(_x + 1, _y + 6, 3, 1, cb);
        desenha_rect(_x + 2, _y + 7, 4, 1, cb);
        desenha_rect(_x + 4, _y + 5, 2, 1, ce);
        desenha_rect(_x + 18, _y + 5, 2, 1, cb);
        desenha_rect(_x + 16, _y + 6, 3, 1, cb);
        desenha_rect(_x + 14, _y + 7, 4, 1, cb);
        desenha_rect(_x + 14, _y + 5, 2, 1, ce);
    }
}

// menu vertical da home, estilo mapa minimalista (losango dourado à esquerda da escolha)
function desenha_menu_home(_x, _y0, _passo, _textos, _cur)
{
    for (var k = 0; k < array_length(_textos); k++)
    {
        var yy = _y0 + k * _passo;
        var sel = (k == _cur);
        var trv = string_pos("~", _textos[k]) > 0;    // item marcado como bloqueado (começa com "~")
        var rot = trv ? string_copy(_textos[k], 2, string_length(_textos[k]) - 1) : _textos[k];
        var cor = trv ? 0x6a7490 : (sel ? 0xffd84a : 0xa9b4c4);
        if (sel)
        {
            // losango dourado à esquerda
            var cx = _x + 4, cy = yy + 6;
            draw_set_colour(cor_rgb(0xffd84a));
            draw_primitive_begin(pr_trianglelist);
            draw_vertex(cx, cy - 6); draw_vertex(cx + 6, cy); draw_vertex(cx - 6, cy);
            draw_vertex(cx - 6, cy); draw_vertex(cx + 6, cy); draw_vertex(cx, cy + 6);
            draw_primitive_end();
            draw_set_colour(cor_rgb(0x1a1630));
            draw_primitive_begin(pr_trianglelist);
            draw_vertex(cx, cy - 2); draw_vertex(cx + 2, cy); draw_vertex(cx - 2, cy);
            draw_vertex(cx - 2, cy); draw_vertex(cx + 2, cy); draw_vertex(cx, cy + 2);
            draw_primitive_end();
            draw_set_colour(c_white);
        }
        else if (trv)
        {
            // cadeado pequeno
            desenha_rect(_x + 1, yy + 4, 6, 4, 0x3a3450);
            desenha_rect(_x + 2, yy + 2, 4, 3, 0x3a3450);
            desenha_rect(_x + 3, yy + 2, 1, 2, 0x1a1630);
            desenha_rect(_x + 4, yy + 2, 1, 2, 0x1a1630);
        }
        desenha_texto(rot, _x + 14, yy + 6, cor, "left", (sel ? 12 : 11), 180);
        if (sel) desenha_rect(_x + 14, yy + 14, floor(largura_texto(rot, 12)), 1, 0xffd84a);
    }
}

#endregion

// fundo das telas secundárias: a cela com um véu escuro por cima, para leitura e consistência visual
function desenha_fundo_menu_tela(_alfa = 0.68)
{
    draw_sprite(spr_fundo_menu, 0, 0, 0);
    desenha_rect_alfa(0, 0, VW, VH, 0x05080f, _alfa);
}

// menu de pausa durante a fase: véu escuro + opções estilo home + sub-popup de SAIR
function desenha_pause_menu()
{
    // véu escuro em cima do mundo
    desenha_rect_alfa(0, 0, VW, VH, 0x03060e, 0.72);
    // caixa escura plana com borda dourada
    var bx = 100, by = 40, bw = 280, bh = 200;
    desenha_rect_alfa(bx, by, bw, bh, 0x0a0e1a, 0.96);
    desenha_rect(bx, by, bw, 1, 0xffd84a);
    desenha_rect(bx, by + bh - 1, bw, 1, 0xffd84a);
    desenha_rect(bx, by, 1, bh, 0xffd84a);
    desenha_rect(bx + bw - 1, by, 1, bh, 0xffd84a);
    desenha_rect_alfa(bx + 1, by + 1, bw - 2, 1, 0xffffff, 0.22);
    // título
    desenha_texto("PAUSA", VW / 2, by + 24, 0xffd84a, "center", 17, bw - 20);
    desenha_rect_alfa(bx + 80, by + 40, bw - 160, 1, 0xffd84a, 0.6);
    desenha_texto("Fase " + string(global.fase_atual + 1), VW / 2, by + 54, 0xc4cee0, "center", 9, bw - 20);
    // menu estilo home (losango + sublinhado)
    var itens = ["CONTINUAR", "RENASCER", "CONFIGURAÇÕES", "MENU PRINCIPAL", "SAIR DO JOGO"];
    desenha_menu_home(bx + 60, by + 76, 22, itens, global.pausa_cursor);
    // sub-popup de confirmação de saída
    if (global.pausa_sair_confirma) desenha_popup_sair();
}
