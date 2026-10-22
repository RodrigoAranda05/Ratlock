// ===== Estado global do jogo, carregamento de fases e simulação do mundo =====

function jogo_inicia()
{
    global.LV = fases_cria();
    global.mundos = [
        {n: "Celas", d: "Os primeiros passos do rato"},
        {n: "Circuitos", d: "Botões, caixas, cabos e água"},
        {n: "Vigilância", d: "Guardas, cão e câmeras"},
        {n: "Sopro", d: "Ventoinhas e a grande fuga"},
        {n: "Cofre", d: "Lasers, pisos de cor e verticais"}
    ];
    global.FIN = 21;                // fase que fecha o mundo 4 (mostra a tela final)

    global.T0 = 0; global.flash = 0; global.toastS = ""; global.toastT = 0; global.ct = 0;
    global.st = "title"; global.mode = "normal";
    global.mi = 0; global.si = 0; global.ws = 0; global.wsel = 0;
    global.cheat = false; global.inv = false;
    global.deaths = 0; global.gTime = 0;
    global.lvDeaths = 0; global.lvTime = 0; global.lvGnaw = 0; global.lvDrop = 0;
    global.res = [false, false, false]; global.cz = -1; global.newBest = false;
    global.act = -1; global.pend = -1; global.lit = true; global.hasKey = false; global.alarme = false;
    global.lt = 0; global.lvl = 0;
    global.parts = []; global.btns = []; global.boxes = []; global.cams = []; global.cables = [];
    global.lamps = []; global.hides = []; global.portals = []; global.enemies = []; global.cheeses = [];
    global.lasers = []; global.fans = []; global.vento = []; global.M = [];
    global.door = {x: 0, y: 0}; global.key = undefined; global.start = [1, 1];
    global.fundo = -1;              // surface com o cenário estático
    global.musica = true;

    // entradas lidas pelo obj_player e usadas pelo controle do jogo
    global.K = {left: false, right: false, up: false, down: false, grab: false, gnaw: false,
                upE: false, grabE: false, dropE: false};

    // quantos queijos existem em cada fase
    for (var i = 0; i < array_length(global.LV); i++)
    {
        var n = 0;
        var L = global.LV[i];
        for (var j = 0; j < GH; j++)
        {
            for (var k = 0; k < GW; k++)
            {
                if (string_char_at(L.mapa[j], k + 1) == "c") n++;
            }
        }
        L.cs = n;
    }
    save_carrega();
}

// ===== progresso salvo (arquivo ratlock.ini) =====
function save_carrega()
{
    ini_open("ratlock.ini");
    global.SV = {
        unl: ini_read_real("geral", "unl", 0),
        ch_t: ini_read_real("geral", "ch_t", -1),
        ch_d: ini_read_real("geral", "ch_d", 0),
        stars: [],
        cheese: []
    };
    for (var i = 0; i < array_length(global.LV); i++)
    {
        var s = ini_read_string("estrelas", string(i), "000");
        array_push(global.SV.stars, [real(string_char_at(s, 1)), real(string_char_at(s, 2)), real(string_char_at(s, 3))]);
        array_push(global.SV.cheese, ini_read_real("queijo", string(i), 0));
    }
    ini_close();
}

function save_grava()
{
    ini_open("ratlock.ini");
    ini_write_real("geral", "unl", global.SV.unl);
    ini_write_real("geral", "ch_t", global.SV.ch_t);
    ini_write_real("geral", "ch_d", global.SV.ch_d);
    for (var i = 0; i < array_length(global.LV); i++)
    {
        var a = global.SV.stars[i];
        ini_write_string("estrelas", string(i), string(a[0]) + string(a[1]) + string(a[2]));
        ini_write_real("queijo", string(i), global.SV.cheese[i]);
    }
    ini_close();
}

function unl_efetivo()
{
    return global.cheat ? 999 : global.SV.unl;
}

function mundo_fases(_w)
{
    var r = [];
    for (var i = 0; i < array_length(global.LV); i++)
    {
        if (global.LV[i].mundo == _w) array_push(r, i);
    }
    return r;
}

function mundo_desbloqueado(_w)
{
    return mundo_fases(_w)[0] <= unl_efetivo();
}

function mundo_estrelas(_w)
{
    var l = mundo_fases(_w), n = 0;
    for (var i = 0; i < array_length(l); i++)
    {
        var a = global.SV.stars[l[i]];
        n += a[0] + a[1] + a[2];
    }
    return n;
}

function mundo_queijos(_w)
{
    var l = mundo_fases(_w), n = 0;
    for (var i = 0; i < array_length(l); i++) n += global.SV.cheese[l[i]];
    return n;
}

function mundo_queijos_max(_w)
{
    var l = mundo_fases(_w), n = 0;
    for (var i = 0; i < array_length(l); i++)
    {
        if (global.LV[l[i]].cs > 0) n++;
    }
    return n;
}

function total_estrelas()
{
    var n = 0;
    for (var i = 0; i < array_length(global.LV); i++)
    {
        var a = global.SV.stars[i];
        n += a[0] + a[1] + a[2];
    }
    return n;
}

function total_queijos()
{
    var n = 0;
    for (var i = 0; i < array_length(global.LV); i++) n += global.SV.cheese[i];
    return n;
}

function total_queijos_max()
{
    var n = 0;
    for (var i = 0; i < array_length(global.LV); i++)
    {
        if (global.LV[i].cs > 0) n++;
    }
    return n;
}

// ===== inimigos =====
function inimigo_cria(_t, _tx, _ty)
{
    var w = 12, h = 22;
    if (_t == "C") { w = 16; h = 10; }
    else if (_t == "H") { w = 14; h = 9; }
    else if (_t == "T") { w = 16; h = 24; }
    return {
        t: _t, w: w, h: h,
        x: _tx * TL + (TL - w) / 2, y: (_ty + 1) * TL - h,
        vx: 0, vy: 0, dir: -1, st: 0, mem: 0, tm: 0, ex: 0,
        alarme: false, blind: false, dark: false, cl: 0, rp: 0, hit: 0, on: false, warn: false,
        a: 0, b: 0
    };
}

// ===== carregamento =====
function carrega_fase(_i, _retry)
{
    if (!_retry) { global.lvDeaths = 0; global.lvTime = 0; global.lvGnaw = 0; global.lvDrop = 0; }
    global.btns = []; global.boxes = []; global.cams = [];
    global.act = -1; global.pend = -1; global.alarme = false; global.lvl = _i;
    global.cheeses = []; global.lasers = []; global.lt = 0; global.cables = []; global.lamps = [];
    global.hides = []; global.portals = []; global.enemies = []; global.key = undefined;
    global.hasKey = false; global.lit = true; global.parts = [];

    var L = global.LV[_i];
    global.M = [];
    for (var j = 0; j < GH; j++)
    {
        var linha = [];
        for (var i = 0; i < GW; i++) array_push(linha, string_char_at(L.mapa[j], i + 1));
        array_push(global.M, linha);
    }

    // transforma os caracteres de entidade em objetos do jogo
    for (var j = 0; j < GH; j++)
    {
        for (var k = 0; k < GW; k++)
        {
            var ch = global.M[j][k];
            var cx = k * TL + 8;
            var ld = laser_dir(ch);
            if (ld != undefined) array_push(global.lasers, {i: k, j: j, d: ld, ph: ((k * 7 + j * 3) % 10) * 0.32, on: false, warn: false, len: 0, r: {x: 0, y: 0, w: 0, h: 0}});
            if (ch == "P") global.start = [k, j];
            else if (ch == "k") global.key = {hx: cx, hy: j * TL + 8, x: cx - 3, y: j * TL + 5, w: 6, h: 6, vx: 0, vy: 0, st: "home", t: 0, cd: 0};
            else if (ch == "D") global.door = {x: k, y: j};
            else if (ch == "c") array_push(global.cheeses, {x: cx, y: j * TL + 8, got: false, sec: false, ci: k, cj: j});
            else if (ch == "w") array_push(global.cables, {x: cx, y: j * TL + 8, cut: false});
            else if (ch == "l") array_push(global.lamps, {x: cx, y: j * TL});
            else if (ch == "h") array_push(global.hides, {c: k, r: j});
            else if (string_pos(ch, "1234") > 0) array_push(global.portals, {x: cx, y: j * TL + 8, ch: ch, tx: k, ty: j, to: undefined});
            else if (botao_cor(ch) >= 0) array_push(global.btns, {tx: k, ty: j, dn: false, c: botao_cor(ch)});
            else if (ch == "X") array_push(global.boxes, {x: k * TL, y: j * TL, w: 16, h: 16, vx: 0, vy: 0, ox: k * TL, oy: j * TL});
            else if (ch == "Z") array_push(global.cams, {x: cx, y: j * TL + 4, ang: pi / 2, sw: 0.9, t: random(6), seen: 0, on: true, see: false});
            else if (string_pos(ch, "LGTHNCF") > 0) array_push(global.enemies, inimigo_cria(ch, k, j));
            if (string_pos(ch, "PkDcwlhLGTHNCFbBoOXZ") > 0) global.M[j][k] = ".";
        }
    }

    // queijos escondidos em paredes falsas só aparecem quando o rato chega perto
    for (var q = 0; q < array_length(global.cheeses); q++)
    {
        var c = global.cheeses[q];
        for (var a = -1; a <= 1; a++)
        {
            for (var b = -1; b <= 1; b++)
            {
                if (c.cj + b >= 0 && c.cj + b < GH && c.ci + a >= 0 && c.ci + a < GW && global.M[c.cj + b][c.ci + a] == "f") c.sec = true;
            }
        }
    }

    // zonas de vento das ventoinhas
    global.vento = [];
    for (var gy = 0; gy < GH; gy++)
    {
        var lv = [];
        for (var gx = 0; gx < GW; gx++) array_push(lv, "");
        array_push(global.vento, lv);
    }
    global.fans = [];
    for (var j = 0; j < GH; j++)
    {
        for (var k = 0; k < GW; k++)
        {
            var fc = global.M[j][k];
            var d = fan_dir(fc);
            if (d != undefined)
            {
                var puxa = (fc == "y" || fc == "r");
                var ml = (d[0] != 0) ? (puxa ? 7 : 6) : 10;
                array_push(global.fans, {i: k, j: j, c: fc});
                for (var n = 1; n <= ml; n++)
                {
                    var i2 = k + d[0] * n;
                    var j2 = j + d[1] * n;
                    if (psol(i2, j2)) break;
                    global.vento[j2][i2] = fc;
                    if (d[0] != 0)
                    {
                        var qmax = puxa ? 3 : 1;
                        for (var q2 = 1; q2 <= qmax; q2++)
                        {
                            if (j2 - q2 > 0 && !psol(i2, j2 - q2) && global.vento[j2 - q2][i2] == "") global.vento[j2 - q2][i2] = fc;
                        }
                    }
                }
            }
        }
    }

    // duto de entrada liga ao duto de saída
    for (var q = 0; q < array_length(global.portals); q++)
    {
        var pa = global.portals[q];
        var par = "";
        if (pa.ch == "1") par = "2";
        else if (pa.ch == "2") par = "1";
        else if (pa.ch == "3") par = "4";
        else par = "3";
        for (var r = 0; r < array_length(global.portals); r++)
        {
            if (global.portals[r] != pa && global.portals[r].ch == par) pa.to = global.portals[r];
        }
    }

    // área de patrulha dos guardas (até onde o chão é reto)
    for (var q = 0; q < array_length(global.enemies); q++)
    {
        var e = global.enemies[q];
        if (e.t == "T") continue;
        var row = floor((e.y + e.h - 1) / TL);
        var a2 = floor((e.x + e.w / 2) / TL);
        var b2 = a2;
        while (!esol(a2 - 1, row) && esol(a2 - 1, row + 1)) a2--;
        while (!esol(b2 + 1, row) && esol(b2 + 1, row + 1)) b2++;
        e.a = a2 * TL;
        e.b = (b2 + 1) * TL - e.w;
    }

    global.fundo_ok = false;
    with (global.jog) reseta(global.start[0] * TL + 3, (global.start[1] + 1) * TL - 10);
    if (global.mode != "challenge") toast(L.dica, 4.5);
}

// ===== eventos do jogo =====
function morre()
{
    var p = global.jog;
    if (p.morto || global.st != "play" || p.teleporte != undefined) return;
    if (global.cheat && global.inv)
    {
        if (p.y > GH * TL)
        {
            p.x = global.start[0] * TL + 3;
            p.y = (global.start[1] + 1) * TL - 10;
            p.velh = 0; p.velv = 0;
        }
        return;
    }
    p.morto = true; p.t_morte = 0; p.velv = -230; p.velh = 0; p.escalando = 0; p.roendo = 0;
    global.deaths++; global.lvDeaths++; global.flash = 0.5;
}

function corta_cabo(_c)
{
    _c.cut = true;
    global.lvGnaw++;
    var todos = true;
    for (var i = 0; i < array_length(global.cables); i++)
    {
        if (!global.cables[i].cut) todos = false;
    }
    if (todos) global.lit = false;
    spark(_c.x, _c.y, 24);
    global.flash = 0.25;
    toast("Cabo roído: energia cortada!", 3);
}

function solta_chave()
{
    var p = global.jog;
    var k = global.key;
    global.lvDrop++;
    k.st = "free"; global.hasKey = false;
    k.x = p.x + p.w / 2 + p.face * 5 - 3;
    k.y = p.y + 1;
    k.vx = global.K.down ? p.face * 15 : p.face * 95;
    k.vy = global.K.down ? 0 : -290;
    k.t = 0; k.cd = 0.5;
}

function volta_chave()
{
    var k = global.key;
    k.st = "home"; k.x = k.hx - 3; k.y = k.hy - 3; k.vx = 0; k.vy = 0; k.t = 0;
    spark(k.hx, k.hy, 14);
    toast("A chave voltou ao lugar de origem", 2.5);
}

function levanta_alarme()
{
    global.alarme = true;
    for (var i = 0; i < array_length(global.enemies); i++)
    {
        var e = global.enemies[i];
        if (string_pos(e.t, "GLNCF") > 0) e.alarme = true;
    }
    toast("ALARME! A câmera avisou os guardas", 3);
}

function laser_comprimento(_L)
{
    var xx = _L.i * TL + 8 + _L.d[0] * 8;
    var yy = _L.j * TL + 8 + _L.d[1] * 8;
    var n = 0;
    while (n < 160)
    {
        var bate = psol(floor(xx / TL), floor(yy / TL));
        if (!bate)
        {
            for (var k = 0; k < array_length(global.boxes); k++)
            {
                var b = global.boxes[k];
                if (xx >= b.x && xx < b.x + b.w && yy >= b.y && yy < b.y + b.h) bate = true;
            }
        }
        if (bate) break;
        xx += _L.d[0] * 4;
        yy += _L.d[1] * 4;
        n++;
    }
    return n * 4;
}

// ===== mundo: lasers, queijos, botões, caixas, câmeras, poças =====
function mundo_passo()
{
    var p = global.jog;
    global.lt += DT;

    for (var q = 0; q < array_length(global.lasers); q++)
    {
        var L = global.lasers[q];
        var t = (global.lt + L.ph) % 3.2;
        L.on = global.lit && t < 1.8;
        L.warn = global.lit && !L.on && t > 2.7;
        L.len = laser_comprimento(L);
        var sx = L.i * TL + 8 + L.d[0] * 8;
        var sy = L.j * TL + 8 + L.d[1] * 8;
        if (L.d[0] != 0) L.r = {x: (L.d[0] > 0) ? sx : sx - L.len, y: sy - 2, w: L.len, h: 4};
        else L.r = {x: sx - 2, y: (L.d[1] > 0) ? sy : sy - L.len, w: 4, h: L.len};
        if (L.on && ovl({x: p.x + 1, y: p.y + 1, w: p.w - 2, h: p.h - 2}, L.r)) morre();
    }

    for (var q = 0; q < array_length(global.cheeses); q++)
    {
        var c = global.cheeses[q];
        if (!c.got && point_distance(c.x, c.y, p.x + 5, p.y + 5) < 12)
        {
            c.got = true;
            spark(c.x, c.y, 18);
            toast("Queijo encontrado!", 2.5);
        }
    }

    // botões
    for (var q = 0; q < array_length(global.btns); q++)
    {
        var b = global.btns[q];
        var r = {x: b.tx * TL + 2, y: b.ty * TL + 10, w: 12, h: 6};
        var dn = ovl(p, r);
        for (var k = 0; k < array_length(global.boxes); k++)
        {
            if (ovl(global.boxes[k], r)) dn = true;
        }
        b.dn = dn;
        if (b.dn && b.c != global.act) global.pend = b.c;
    }
    if (global.pend >= 0 && global.pend != global.act)
    {
        // não troca a cor se o rato ou uma caixa estiver dentro de algo que vai fechar
        var occ = false;
        if (global.act >= 0)
        {
            if (ov(p, ocupa_gate_ativo) != undefined) occ = true;
            for (var k = 0; k < array_length(global.boxes); k++)
            {
                if (ov(global.boxes[k], ocupa_gate_ativo) != undefined) occ = true;
            }
        }
        if (ov(p, ocupa_piso_novo) != undefined) occ = true;
        for (var k = 0; k < array_length(global.boxes); k++)
        {
            if (ov(global.boxes[k], ocupa_piso_novo) != undefined) occ = true;
        }
        if (!occ)
        {
            global.act = global.pend;
            spark(p.x + 5, p.y + 8, 10);
            var nomes = ["vermelhas", "azuis", "verdes", "amarelas"];
            toast("Portas " + nomes[global.act] + " abertas", 2);
        }
    }

    // caixas caem
    for (var q = 0; q < array_length(global.boxes); q++)
    {
        var bx = global.boxes[q];
        bx.vy = min(bx.vy + 900 * DT, 400);
        if (caixa_move(bx, 0, bx.vy * DT)) bx.vy = 0;
        if (bx.y > GH * TL + 20) { bx.x = bx.ox; bx.y = bx.oy; bx.vy = 0; }
    }

    // câmeras
    for (var q = 0; q < array_length(global.cams); q++)
    {
        var cm = global.cams[q];
        cm.t += DT;
        cm.ang = pi / 2 + sin(cm.t * 0.8) * cm.sw;
        cm.on = global.lit;
        var px = p.x + 5, py = p.y + 5;
        var ddx = px - cm.x, ddy = py - cm.y;
        var df = abs(arctan2(ddy, ddx) - cm.ang);
        if (df > pi) df = 2 * pi - df;
        cm.see = cm.on && !p.escondido && point_distance(0, 0, ddx, ddy) < 150 && df < 0.33 && los(cm.x, cm.y, px, py);
        if (cm.see)
        {
            cm.seen += DT;
            if (cm.seen > 0.35 && !global.alarme) levanta_alarme();
        }
        else cm.seen = max(0, cm.seen - DT);
    }

    // poças eletrificadas enquanto houver cabo ligado
    var el = false;
    for (var q = 0; q < array_length(global.cables); q++)
    {
        if (!global.cables[q].cut) el = true;
    }
    if (el)
    {
        for (var j = floor(p.y / TL); j <= floor((p.y + p.h - 1) / TL); j++)
        {
            for (var i = floor(p.x / TL); i <= floor((p.x + p.w - 0.01) / TL); i++)
            {
                if (tile_em(i, j) == "m" && p.y + p.h > j * TL + 11)
                {
                    spark(p.x + 5, p.y + 8, 20);
                    morre();
                }
            }
        }
    }
}

// ===== inimigos =====
function inimigo_atualiza(_e)
{
    var p = global.jog;
    var px = p.x + 5;
    var ex = _e.x + _e.w / 2;
    var dx = px - ex;
    var dy = p.y + p.h - _e.y - _e.h;

    if (_e.t == "T")
    {
        // sentinela: feixe em ciclos de 4,2 s
        _e.tm = (_e.tm + DT) % 4.2;
        _e.blind = !global.lit;
        _e.on = !_e.blind && _e.tm < 1.8;
        _e.warn = !_e.blind && _e.tm > 3.7;
        var fy = _e.y + _e.h;
        var noCone = !p.escondido && p.x + p.w > ex - 176 && p.x < ex && p.y + p.h > fy - 48 && p.y < fy && los(ex, fy - 14, px, p.y + 5);
        if (_e.on && noCone)
        {
            _e.ex += DT;
            if (_e.ex > 0.3) morre();
        }
        else _e.ex = 0;
        return;
    }

    _e.blind = (_e.t == "L" && !global.lit && !perto_lanterna(_e));
    _e.dark = (_e.t == "F" && !global.lit && !perto_lanterna(_e));
    if (_e.dark) { _e.st = 0; _e.mem = 0; }

    var sight = (_e.t == "H") ? 130 : 90;
    var ve = false;
    if (_e.t == "C")
    {
        // o cão fareja até no barril
        ve = (abs(dx) < 120 && abs(dy) < 40);
    }
    else
    {
        ve = (!_e.dark && !p.escondido && abs(dy) < 30 && abs(dx) < sight && (_e.t == "H" || sign(dx) == _e.dir) && los(ex, _e.y + 6, px, p.y + 5));
    }

    var sp = 0;
    _e.cl = 0;
    if (!_e.blind)
    {
        if (ve) { _e.st = 1; _e.mem = 1.2; }
        else if (_e.st != 0)
        {
            _e.mem -= DT;
            if (_e.mem <= 0) _e.st = 0;
        }
        if (_e.alarme) _e.st = 1;
        if (_e.st != 0)
        {
            _e.dir = (dx > 0) ? 1 : -1;
            sp = (_e.t == "H") ? 92 : ((_e.t == "C") ? 128 : 82);
            if (_e.t == "H") { if (abs(dx) < 3) sp = 0; }
            else if ((_e.dir > 0 && _e.x >= _e.b + 8) || (_e.dir < 0 && _e.x <= _e.a - 8)) sp = 0;
        }
        else
        {
            // eletricista: vai religar o cabo roído mais próximo
            var rp = undefined;
            if (_e.t == "F")
            {
                var melhor = 99999;
                for (var q = 0; q < array_length(global.cables); q++)
                {
                    var cb = global.cables[q];
                    if (cb.cut && abs(cb.x - ex) < melhor) { melhor = abs(cb.x - ex); rp = cb; }
                }
            }
            if (rp != undefined)
            {
                var d = rp.x - ex;
                var cy = _e.y + _e.h / 2;
                var dyc = rp.y - cy;
                if (abs(d) < 22 && abs(dyc) < 24)
                {
                    sp = 0;
                    if (dyc < -4 && tile_trepa(floor(rp.x / TL), floor(cy / TL))) _e.cl = 1;
                    _e.rp += DT;
                    if (random(1) < 0.3) spark(rp.x, rp.y, 1);
                    if (_e.rp > 2.2)
                    {
                        rp.cut = false; global.lit = true; _e.rp = 0; _e.hit = 0;
                        spark(rp.x, rp.y, 20);
                        toast("O eletricista religou a luz!", 3);
                    }
                }
                else if (abs(d) < 24 && dyc <= -24 && tile_trepa(floor(rp.x / TL), floor(cy / TL)))
                {
                    sp = 0; _e.cl = 1; _e.rp = 0;
                    _e.y -= 55 * DT;
                }
                else
                {
                    _e.rp = 0;
                    _e.dir = (d > 0) ? 1 : -1;
                    sp = 62;
                }
            }
            else
            {
                _e.rp = 0; _e.hit = 0;
                sp = (_e.t == "H") ? 30 : ((_e.t == "C") ? 55 : 42);
                if (_e.x <= _e.a) _e.dir = 1;
                if (_e.x >= _e.b) _e.dir = -1;
            }
        }
    }
    _e.vx = _e.dir * sp;
    var bateu = mx(_e, _e.vx * DT, esol);
    if (!bateu && inimigo_na_caixa(_e)) { _e.x -= _e.vx * DT; bateu = true; }
    if (bateu && _e.st == 0)
    {
        var temCortado = false;
        for (var q = 0; q < array_length(global.cables); q++)
        {
            if (global.cables[q].cut) temCortado = true;
        }
        if (_e.t == "F" && temCortado) _e.hit = 1;
        else _e.dir = -_e.dir;
    }
    if (_e.cl != 0) _e.vy = 0;
    else
    {
        _e.vy = min(_e.vy + 900 * DT, 400);
        if (my(_e, _e.vy * DT, esol)) _e.vy = 0;
    }
    // contato: quem já te viu mata até no barril; o cão sempre mata
    if (!_e.blind && !_e.dark && (!p.escondido || _e.t == "C" || _e.st != 0) && ovl(p, {x: _e.x + 2, y: _e.y + 2, w: _e.w - 4, h: _e.h - 3})) morre();
}

// ===== passo do mundo (depois do jogador) =====
function jogo_passo()
{
    var p = global.jog;
    global.T0 += DT;
    global.flash = max(0, global.flash - DT);
    global.toastT -= DT;

    if (global.st == "play")
    {
        if (!p.morto)
        {
            // dutos: teletransporte
            var no = undefined;
            for (var q = 0; q < array_length(global.portals); q++)
            {
                var pt = global.portals[q];
                if (point_distance(pt.x, pt.y, p.x + 5, p.y + 5) < 9) { no = pt; break; }
            }
            if (no == undefined) p.portal_atual = undefined;
            else if (p.portal_atual == undefined && p.t_portal <= 0 && p.teleporte == undefined && no.to != undefined)
            {
                p.teleporte = {t: 0, to: no.to, m: false};
                p.escalando = 0; p.velh = 0; p.velv = 0;
                spark(no.x, no.y, 8);
            }
            for (var q = 0; q < array_length(global.enemies); q++) inimigo_atualiza(global.enemies[q]);
            mundo_passo();
            global.lvTime += DT;
            global.gTime += DT;
            if (espinho_toca(p)) morre();

            var k = global.key;
            k.cd -= DT;
            if (global.K.dropE && global.hasKey) solta_chave();
            if (k.st == "free")
            {
                k.vy = min(k.vy + 900 * DT, 400);
                if (mx(k, k.vx * DT, psol)) k.vx = 0;
                if (my(k, k.vy * DT, psol)) { if (k.vy > 0) k.vx = 0; k.vy = 0; }
                k.t += DT;
                if (k.t > 12 || k.y > GH * TL) volta_chave();
            }
            if (k.st != "carried" && k.cd <= 0 && p.escalando == 0 && point_distance(k.x + 3, k.y + 3, p.x + 5, p.y + 5) < 12)
            {
                k.st = "carried"; global.hasKey = true; k.t = 0;
                for (var q = 0; q < array_length(global.enemies); q++)
                {
                    if (global.enemies[q].t == "H") global.enemies[q].alarme = true;
                }
                toast("Chave na boca: pulo fraco e sem escalar", 3.5);
            }
            if (ovl(p, {x: global.door.x * TL, y: (global.door.y - 1) * TL, w: TL, h: 2 * TL}))
            {
                if (global.hasKey) nivel_concluido();
                else if (global.toastT <= 0) toast("Porta trancada. Pegue a chave primeiro!", 2);
            }
        }
    }
    else if (global.st == "clear")
    {
        global.ct += DT;
        if (global.mode == "challenge" && global.ct > 1.3) proximo_nivel();
    }
    else global.ct += DT;

    // partículas
    var novas = [];
    for (var q = 0; q < array_length(global.parts); q++)
    {
        var pa = global.parts[q];
        pa.l -= DT;
        pa.vy += 300 * DT;
        pa.x += pa.vx * DT;
        pa.y += pa.vy * DT;
        if (pa.l > 0) array_push(novas, pa);
    }
    global.parts = novas;
}

// ===== fluxo =====
function nivel_concluido()
{
    var L = global.LV[global.lvl];
    var r3 = false;
    if (L.o3 == "cabo") r3 = (global.lvGnaw == 0);
    else if (L.o3 == "chave") r3 = (global.lvDrop == 0);
    else r3 = (global.lvTime <= L.par * 0.65);
    global.res = [global.lvDeaths == 0, global.lvTime <= L.par, r3];

    var todos = (array_length(global.cheeses) > 0);
    for (var q = 0; q < array_length(global.cheeses); q++)
    {
        if (!global.cheeses[q].got) todos = false;
    }
    global.cz = (array_length(global.cheeses) > 0) ? (todos ? 1 : 0) : -1;

    if (global.mode == "normal" && !global.cheat)
    {
        if (global.cz == 1) global.SV.cheese[global.lvl] = 1;
        // atenção: em GML arrays são copiados ao modificar, então grava direto no array original
        for (var q = 0; q < 3; q++)
        {
            if (global.res[q]) global.SV.stars[global.lvl][q] = 1;
        }
        global.SV.unl = max(global.SV.unl, min(array_length(global.LV) - 1, global.lvl + 1));
        save_grava();
    }
    global.st = "clear";
    global.ct = 0;
}

function proximo_nivel()
{
    if (global.lvl + 1 >= array_length(global.LV) || (global.mode == "normal" && global.lvl == global.FIN)) fim_jogo();
    else { carrega_fase(global.lvl + 1, false); global.st = "play"; }
}

function fim_jogo()
{
    global.newBest = false;
    if (global.mode == "challenge" && !global.cheat)
    {
        if (global.SV.ch_t < 0 || global.gTime < global.SV.ch_t)
        {
            global.SV.ch_t = global.gTime;
            global.SV.ch_d = global.deaths;
            global.newBest = true;
            save_grava();
        }
    }
    global.st = "win";
    global.ct = 0;
}

function inicia_nivel(_i, _m)
{
    global.mode = _m;
    global.wsel = global.LV[_i].mundo;
    global.ws = global.wsel;
    if (_m == "challenge") { global.deaths = 0; global.gTime = 0; }
    carrega_fase(_i, false);
    global.st = "play";
}
