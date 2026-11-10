// ===== colisão por grade =====
// global.grade[linha][coluna] guarda um caractere por tile (montado no Room Start a partir das células):
//   =  plataforma de mão única      #  cano/vinha (segundo plano, escala)        S  pedra            ^  espinho       m  poça
//   v  ventilação                    1-4  dutos
//   q Q j J  portões (4 cores)       a A e E  pisos de cor
//   U u n R r Y y  ventoinhas        i I x z  lasers
// As funções abaixo recebem uma "caixa" com x, y, w, h (o rato, um inimigo, uma caixa...).

function tile_em(_i, _j)
{
    if (_i < 0 || _i >= GW || _j < 0) return "S";
    if (_j >= GH) return ".";
    return global.grade[_j][_i];
}

// Formas da pedra (novo estilo, os blocos não se ligam): 0 = 16x16, 1 = 32x32, 2 = 16x32 (em pé), 3 = 32x16 (deitado)
function pedra_larg(_forma)
{
    return (_forma == 1 || _forma == 3) ? 2 : 1;
}

function pedra_alt(_forma)
{
    return (_forma == 1 || _forma == 2) ? 2 : 1;
}

function pedra_sprite(_forma)
{
    switch (_forma)
    {
        case 1: return spr_pedra_g;
        case 2: return spr_pedra_a;
        case 3: return spr_pedra_l;
    }
    return spr_pedra;
}

// Quadros do spr_cano: 0 vertical, 1 cima+direita, 2 cima+esquerda, 3 baixo+direita, 4 baixo+esquerda,
// 5 horizontal, 6 cruz, 7 esq.+dir.+baixo, 8 esq.+dir.+cima, 9 cima+baixo+esq., 10 cima+baixo+dir.
// Os argumentos dizem se o vizinho de cima/baixo/esquerda/direita também é cano.
// _pedra_e/_pedra_d/_pedra_c/_pedra_b: tem pedra à esquerda/direita/em cima/embaixo. A ponta solta do cano faz a curva e "sai" da pedra
// (vertical vira para o lado, horizontal vira para cima ou para baixo).
function quadro_cano(_cima, _baixo, _esq, _dir, _pedra_e = false, _pedra_d = false, _pedra_c = false, _pedra_b = false)
{
    var n = (_cima ? 1 : 0) + (_baixo ? 1 : 0) + (_esq ? 1 : 0) + (_dir ? 1 : 0);
    if (n == 1 && (_cima || _baixo) && (_pedra_d || _pedra_e))
    {
        var pd = _pedra_d;                                  // as duas paredes: sai pela direita
        if (_cima) return pd ? 1 : 2;
        return pd ? 3 : 4;
    }
    if (n == 1 && (_esq || _dir) && (_pedra_c || _pedra_b))
    {
        // ponta de cano horizontal junto de teto/chão: curva para cima ou para baixo (cima tem preferência)
        if (_pedra_c) return _dir ? 1 : 2;
        return _dir ? 3 : 4;
    }
    if (n == 4) return 6;
    if (n == 3)
    {
        if (!_cima) return 7;
        if (!_baixo) return 8;
        if (!_dir) return 9;
        return 10;
    }
    if (n == 2)
    {
        if (_cima && _baixo) return 0;
        if (_esq && _dir) return 5;
        if (_cima) return _dir ? 1 : 2;
        return _dir ? 3 : 4;
    }
    if (n == 1) return (_esq || _dir) ? 5 : 0;
    return 0;
}

// Quadros do spr_plataforma: 8 solta, 5 ponta esquerda, 6 ponta direita, 2 meio, 3 ponta esquerda presa na parede,
// 4 ponta direita presa na parede, 7 solta presa na parede da esquerda.
function quadro_plataforma(_pe, _pd, _parede_e, _parede_d)
{
    if (!_pe && !_pd) return _parede_e ? 7 : 8;
    if (!_pe) return _parede_e ? 3 : 5;
    if (!_pd) return _parede_d ? 4 : 6;
    return 2;
}

// onde (em x, dentro do tile) cada quadro do spr_plataforma é sólido: as pontas só têm barra de um lado
function span_plataforma(_q)
{
    var sp = [[1, 15], [0, 16], [0, 16], [0, 16], [0, 16], [8, 16], [0, 7], [0, 14], [1, 15]];
    return sp[_q];
}

// o tile (_i,_j) é plataforma e o corpo (_x0.._x1) está sobre a parte que tem barra?
function plat_tile(_i, _j, _x0, _x1)
{
    if (tile_em(_i, _j) != "=") return false;
    var sp = global.plat_span[_j][_i];
    return _x1 > _i * TL + sp[0] && _x0 < _i * TL + sp[1];
}

// plataforma de mão única (=): os pés do corpo estão em cima dela?
function plat_sob(_o)
{
    var fim = _o.y + _o.h;
    var j = floor((fim + 1) / TL);
    if (fim > j * TL + 0.01) return false;
    var x0 = floor(_o.x / TL);
    var x1 = floor((_o.x + _o.w - 0.01) / TL);
    for (var i = x0; i <= x1; i++)
    {
        if (plat_tile(i, j, _o.x, _o.x + _o.w)) return true;
    }
    return false;
}

function tile_escalavel(_i, _j)
{
    return tile_em(_i, _j) == "#";
}

function dir_ventoinha(_c)
{
    switch (_c)
    {
        case "U": return [0, -1];
        case "u": return [0, -1];
        case "n": return [0, 1];
        case "R": return [1, 0];
        case "r": return [1, 0];
        case "Y": return [-1, 0];
        case "y": return [-1, 0];
    }
    return undefined;
}

function dir_laser(_c)
{
    switch (_c)
    {
        case "i": return [1, 0];
        case "I": return [-1, 0];
        case "x": return [0, 1];
        case "z": return [0, -1];
    }
    return undefined;
}

function cor_do_portao(_c)
{
    switch (_c)
    {
        case "q": return 0;
        case "Q": return 1;
        case "j": return 2;
        case "J": return 3;
    }
    return -1;
}

function cor_do_piso(_c)
{
    switch (_c)
    {
        case "a": return 0;
        case "A": return 1;
        case "e": return 2;
        case "E": return 3;
    }
    return -1;
}

function solido_rato(_i, _j)
{
    var c = tile_em(_i, _j);
    if (c == "S") return true;       // o cano (#) é segundo plano: não bate em ninguém
    var g = cor_do_portao(c);
    if (g >= 0 && global.cor_ativa != g) return true;       // portão fechado
    if (dir_ventoinha(c) != undefined) return true;          // ventoinha
    if (dir_laser(c) != undefined) return true;        // emissor de laser
    var f = cor_do_piso(c);
    if (f >= 0 && global.cor_ativa == f) return true;        // piso de cor ativo
    return false;
}

function solido_inimigo(_i, _j)
{
    return solido_rato(_i, _j) || string_pos(tile_em(_i, _j), "v") > 0;
}

function ocupa_portao_ativo(_i, _j)
{
    return cor_do_portao(tile_em(_i, _j)) == global.cor_ativa;
}

function ocupa_piso_novo(_i, _j)
{
    return cor_do_piso(tile_em(_i, _j)) == global.cor_pendente;
}

function tile_sobreposto(_o, _s)
{
    var x0 = floor(_o.x / TL);
    var x1 = floor((_o.x + _o.w - 0.01) / TL);
    var y0 = floor(_o.y / TL);
    var y1 = floor((_o.y + _o.h - 0.01) / TL);
    for (var j = y0; j <= y1; j++)
    {
        for (var i = x0; i <= x1; i++)
        {
            if (!_s(i, j)) continue;
            return [i, j];
        }
    }
    return undefined;
}

function move_x_grade(_o, _d, _s)
{
    _o.x += _d;
    var h = tile_sobreposto(_o, _s);
    if (h != undefined)
    {
        _o.x = (_d > 0) ? h[0] * TL - _o.w : (h[0] + 1) * TL;
        return true;
    }
    return false;
}

// _plat = true: plataformas de mão única (=) seguram quem vem de cima
function move_y_grade(_o, _d, _s, _plat = false)
{
    var antes = _o.y + _o.h;
    _o.y += _d;
    var h = tile_sobreposto(_o, _s);
    if (h != undefined)
    {
        _o.y = (_d > 0) ? h[1] * TL - _o.h : (h[1] + 1) * TL;
        return true;
    }
    if (_plat && _d > 0)
    {
        var j = floor((_o.y + _o.h) / TL);
        if (antes <= j * TL + 0.01)
        {
            var x0 = floor(_o.x / TL);
            var x1 = floor((_o.x + _o.w - 0.01) / TL);
            for (var i = x0; i <= x1; i++)
            {
                if (plat_tile(i, j, _o.x, _o.x + _o.w))
                {
                    _o.y = j * TL - _o.h;
                    return true;
                }
            }
        }
    }
    return false;
}

function retangulos_batem(_a, _b)
{
    return _a.x < _b.x + _b.w && _a.x + _a.w > _b.x && _a.y < _b.y + _b.h && _a.y + _a.h > _b.y;
}

function tem_visao(_ax, _ay, _bx, _by)
{
    var n = ceil(point_distance(_ax, _ay, _bx, _by) / 4);
    for (var i = 1; i < n; i++)
    {
        var xx = _ax + (_bx - _ax) * i / n;
        var yy = _ay + (_by - _ay) * i / n;
        if (solido_rato(floor(xx / TL), floor(yy / TL))) return false;
        for (var k = 0; k < array_length(global.caixas); k++)
        {
            var b = global.caixas[k];
            if (xx >= b.x && xx <= b.x + b.w && yy >= b.y && yy <= b.y + b.h) return false;
        }
    }
    return true;
}
