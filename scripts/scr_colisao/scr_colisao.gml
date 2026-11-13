// ===== colisão por grade =====
// global.grade[linha][coluna] guarda um caractere por tile (montado no Room Start a partir das células):
//   =  plataforma de mão única      #  cano/vinha (segundo plano, escala)        S  pedra            ^  espinho       m  poça
//   v  ventilação                    1-4  dutos
//   q Q j J  portões (4 cores)     
//   U u n R r Y y  ventoinhas        i I x z  lasers
// As funções abaixo recebem uma "caixa" com x, y, w, h (o rato, um inimigo, uma caixa...).

function tile_em(_i, _j)
{
    if (_i < 0 || _i >= GW || _j < 0) return "S";
    if (_j >= GH) return ".";
    return global.grade[_j][_i];
}

// só visual: vizinho conta como pedra se for pedra
function pedra_visual(_i, _j)
{
    if (_i < 0 || _i >= GW || _j < 0 || _j >= GH) return true;   // fora da sala conta como pedra (igual ao criador)
    var c = tile_em(_i, _j);
    return c == "S";
}

// Blocos do tileset (spr_pedra). Os argumentos dizem se o lado/diagonal está LIVRE (sem pedra):
// cima, baixo, esq, dir e as diagonais ce (cima-esq.), cd (cima-dir.), be (baixo-esq.), bd (baixo-dir.).
//   0 parede esq.   1 parede dir.   2 teto   3 chão   4-7 cantos (sup-esq, sup-dir, inf-esq, inf-dir)
//   8-11 canto de dentro (inf-dir, inf-esq, sup-dir, sup-esq)   12-13 pontas da plataforma (esq., dir.)
//   14-15 pontas do pilar (cima, baixo)   16-19 dois cantos de dentro juntos (em cima, embaixo, à esq., à dir.)
//   20 miolo liso   21 meio da plataforma   22 meio do pilar
//   23-25 teto + canto de dentro embaixo (esq., dir., os dois)       26-28 chão + canto de dentro em cima (esq., dir., os dois)
//   29-30 parede esq./dir. + canto de dentro (inf-dir./inf-esq.)       31-32 parede esq./dir. + canto de dentro (sup-dir./sup-esq.)
//   33-34 parede esq./dir. + os dois cantos de dentro                  35 quatro cantos de dentro
//   36-39 três cantos de dentro (falta o inf-dir., inf-esq., sup-dir., sup-esq.)
//   40-43 quina (sup-esq., sup-dir., inf-esq., inf-dir.) + canto de dentro do lado oposto
// Combinação sem bloco no tileset: usa o mais parecido (pedra solta usa 12; cantos de dentro opostos usam 11/10).
function bloco_pedra(_cima, _baixo, _esq, _dir, _ce, _cd, _be, _bd, _i, _j)
{
    var livres = (_cima ? 1 : 0) + (_baixo ? 1 : 0) + (_esq ? 1 : 0) + (_dir ? 1 : 0);

    if (livres == 4) return 12;                      // pedra solta
    if (livres == 3)                                 // pontas
    {
        if (!_dir) return 12;                        // ponta esquerda da plataforma
        if (!_esq) return 13;                        // ponta direita
        if (!_baixo) return 14;                      // ponta de cima do pilar
        return 15;                                   // ponta de baixo do pilar
    }
    if (livres == 2)
    {
        if (_cima && _baixo) return 21;              // meio da plataforma fina
        if (_esq && _dir) return 22;                 // meio do pilar fino
        if (_cima && _esq) return _bd ? 40 : 4;      // quina + canto de dentro do lado oposto
        if (_cima && _dir) return _be ? 41 : 5;
        if (_baixo && _esq) return _cd ? 42 : 6;
        return _ce ? 43 : 7;
    }
    if (livres == 1)                                 // um lado livre: os cantos de dentro do lado oposto contam
    {
        if (_cima)
        {
            if (_be && _bd) return 25;
            if (_be) return 23;
            if (_bd) return 24;
            return 2;
        }
        if (_baixo)
        {
            if (_ce && _cd) return 28;
            if (_ce) return 26;
            if (_cd) return 27;
            return 3;
        }
        if (_esq)
        {
            if (_cd && _bd) return 33;
            if (_bd) return 29;
            if (_cd) return 31;
            return 0;
        }
        if (_ce && _be) return 34;
        if (_be) return 30;
        if (_ce) return 32;
        return 1;
    }
    // nenhum lado livre: só sobram os cantos de dentro
    var cantos = (_ce ? 1 : 0) + (_cd ? 1 : 0) + (_be ? 1 : 0) + (_bd ? 1 : 0);
    if (cantos == 4) return 35;
    if (cantos == 3)
    {
        if (!_bd) return 36;
        if (!_be) return 37;
        if (!_cd) return 38;
        return 39;
    }
    if (cantos == 2)
    {
        if (_ce && _cd) return 16;
        if (_be && _bd) return 17;
        if (_ce && _be) return 18;
        if (_cd && _bd) return 19;
        return _ce ? 11 : 10;                        // opostos: sem bloco próprio
    }
    if (_ce) return 11;
    if (_cd) return 10;
    if (_be) return 9;
    if (_bd) return 8;
    return 20;
}

function quadro_pedra(_i, _j)
{
    return bloco_pedra(!pedra_visual(_i, _j - 1), !pedra_visual(_i, _j + 1), !pedra_visual(_i - 1, _j), !pedra_visual(_i + 1, _j),
        !pedra_visual(_i - 1, _j - 1), !pedra_visual(_i + 1, _j - 1), !pedra_visual(_i - 1, _j + 1), !pedra_visual(_i + 1, _j + 1), _i, _j);
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
    if (!_pe && !_pd) return (_parede_e || _parede_d) ? 7 : 8;      // solta junto de uma parede: o 7, espelhado quando a parede é a da direita
    if (!_pe) return _parede_e ? 3 : 5;
    if (!_pd) return _parede_d ? 4 : 6;
    return 2;
}

// a plataforma solta, com parede só do lado direito, usa o quadro 7 espelhado
function plataforma_espelha(_pe, _pd, _parede_e, _parede_d)
{
    return !_pe && !_pd && _parede_d && !_parede_e;
}

// onde (em x, dentro do tile) cada quadro do spr_plataforma é sólido: as pontas só têm barra de um lado
function span_plataforma(_q, _espelhado = false)
{
    var sp = [[1, 15], [0, 16], [0, 16], [0, 16], [0, 16], [8, 16], [0, 7], [0, 14], [1, 15]][_q];
    if (_espelhado) return [TL - sp[1], TL - sp[0]];
    return sp;
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

function solido_rato(_i, _j)
{
    var c = tile_em(_i, _j);
    if (c == "S") return true;       // o cano (#) é segundo plano: não bate em ninguém
    var g = cor_do_portao(c);
    if (g >= 0 && global.cor_ativa == g) return true;       // bloco aparece quando o botão da cor está ativo
    if (dir_ventoinha(c) != undefined) return true;          // ventoinha
    if (dir_laser(c) != undefined) return true;        // emissor de laser
    return false;
}

// retângulo que mata de cada espinho (^ chão, V teto, < aponta p/ esquerda, > aponta p/ direita)
function caixa_espinho(_c, _i, _j)
{
    switch (_c)
    {
        case "^": return {x: _i * TL + 2, y: _j * TL + 7, w: 12, h: 9};
        case "V": return {x: _i * TL + 2, y: _j * TL, w: 12, h: 9};
        case "<": return {x: _i * TL + 7, y: _j * TL + 2, w: 9, h: 12};   // base na parede da direita, pontas para a esquerda
        case ">": return {x: _i * TL, y: _j * TL + 2, w: 9, h: 12};
    }
    return undefined;
}

// o objeto _o (rato, chave) encostou em algum espinho?
function espinho_toca(_o)
{
    for (var j = floor(_o.y / TL); j <= floor((_o.y + _o.h) / TL); j++)
    {
        for (var i = floor(_o.x / TL); i <= floor((_o.x + _o.w) / TL); i++)
        {
            var c = tile_em(i, j);
            if (string_pos(c, "^V<>") > 0 && retangulos_batem(_o, caixa_espinho(c, i, j))) return true;
        }
    }
    return false;
}

function solido_inimigo(_i, _j)
{
    return solido_rato(_i, _j);
}

function ocupa_portao_ativo(_i, _j)
{
    return cor_do_portao(tile_em(_i, _j)) == global.cor_ativa;
}

// blocos da cor que está para ficar ativa (ninguém pode estar dentro deles)
function ocupa_portao_pendente(_i, _j)
{
    return cor_do_portao(tile_em(_i, _j)) == global.cor_pendente;
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
