// ===== colisão por grade =====
// global.grade[linha][coluna] guarda um caractere por tile (montado no Room Start a partir das células):
//   #  cano (dá para escalar)        S  pedra            f  parede falsa     ^  espinho       m  poça
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
    if (c == "#" || c == "S") return true;
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
            if (_s(i, j)) return [i, j];
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

function move_y_grade(_o, _d, _s)
{
    _o.y += _d;
    var h = tile_sobreposto(_o, _s);
    if (h != undefined)
    {
        _o.y = (_d > 0) ? h[1] * TL - _o.h : (h[1] + 1) * TL;
        return true;
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
