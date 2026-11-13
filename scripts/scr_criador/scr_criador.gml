// ===== criador de fases =====
// A fase criada é uma grade CRIADOR_COL x CRIADOR_LIN. Cada célula guarda -1 (vazia) ou um "código de peça":
//     código = índice da peça * 8 + variante        (variante = cor, direção, número do duto...)
// Para jogar, constroi_fase_custom() cria as instâncias na rm_custom, no canto do tile (igual a uma room normal).
// Para compartilhar, a grade vira um texto (codifica_fase) que o outro jogador cola no menu (decodifica_fase).
//
// REGRA: só dá para salvar ou compartilhar uma fase que o próprio criador já ZEROU no modo teste.
// O jogo marca global.ed.validada quando o teste termina sem cheats, e qualquer mudança na grade apaga a marca.
// O código leva uma soma de verificação; se alguém mexer no texto, o jogo recusa.

#region peças

function nova_peca(_k, _nome, _obj, _nvar, _unica, _esc, _oculta = false)
{
    return {k: _k, nome: _nome, obj: _obj, nvar: _nvar, unica: _unica, esc: _esc, oculta: _oculta};
}

// ATENÇÃO: a ordem desta lista faz parte do código de compartilhar. Só acrescente peças no FIM.
// esc = escala do ícone na paleta (peças altas ficam menores).
// oculta = peça removida do jogo: continua na lista só para não mudar o número das outras (não aparece na paleta nem entra na fase).
function carrega_pecas()
{
    global.pecas = [
        nova_peca("rato", "Rato (início)", obj_player, 1, true, 1),
        nova_peca("chave", "Chave", obj_chave, 1, true, 1),
        nova_peca("porta", "Porta (saída)", obj_porta, 1, true, 0.6),
        nova_peca("pedra", "Pedra", obj_pedra, 1, false, 1),
        nova_peca("pedra_falsa", "Parede falsa (removida)", obj_pedra, 1, false, 1, true),
        nova_peca("cano", "Cano (escalar)", obj_cano, 1, false, 1),
        nova_peca("espinho", "Espinho", obj_espinho, 4, false, 1),
        nova_peca("poca", "Poça", obj_poca, 1, false, 1),
        nova_peca("ventilacao", "Grade de ventilação (removida)", obj_portao, 1, false, 1, true),
        nova_peca("duto", "Duto", obj_duto, 2, false, 1),       // só um par: nº 1 e nº 2
        nova_peca("portao", "Bloco de cor", obj_portao, 4, false, 1),
        nova_peca("piso", "Piso de cor (virou bloco de cor)", obj_portao, 4, false, 1, true),
        nova_peca("botao", "Botão", obj_botao, 8, false, 1),
        nova_peca("ventoinha", "Ventoinha", obj_ventoinha, 7, false, 1),
        nova_peca("laser", "Laser", obj_laser, 4, false, 1),
        nova_peca("caixa", "Caixa", obj_caixa, 1, false, 1),
        nova_peca("cabo", "Cabo de energia", obj_cabo, 2, false, 1),
        nova_peca("lampada", "Lâmpada", obj_lampada, 1, false, 1),
        nova_peca("barril", "Barril", obj_barril, 1, false, 1),
        nova_peca("camera", "Câmera", obj_camera, 1, false, 1),
        nova_peca("queijo", "Queijo (só um por fase)", obj_queijo, 1, true, 1),
        nova_peca("guarda", "Guarda", obj_guarda, 1, false, 0.9),
        nova_peca("guarda_lanterna", "Guarda com lanterna", obj_guarda_lanterna, 1, false, 0.9),
        nova_peca("eletricista", "Eletricista", obj_eletricista, 1, false, 0.9),
        nova_peca("cao", "Cão farejador", obj_cao, 1, false, 1),
        nova_peca("sentinela", "Sentinela (removido)", obj_portao, 1, false, 1, true),
        nova_peca("plataforma", "Plataforma (sobe por baixo)", obj_plataforma, 1, false, 1),
        nova_peca("fio", "Fio de energia (automático)", obj_fio, 1, false, 1, true)
    ];
    global.pecas_vis = [];                      // índices das peças que aparecem na paleta
    for (var p = 0; p < array_length(global.pecas); p++)
    {
        if (!global.pecas[p].oculta) array_push(global.pecas_vis, p);
    }
    global.cores_nomes = ["vermelho", "azul", "verde", "amarelo"];
    global.dir_nomes = ["direita", "cima", "esquerda", "baixo"];
}

function indice_peca(_k)
{
    for (var i = 0; i < array_length(global.pecas); i++)
    {
        if (global.pecas[i].k == _k) return i;
    }
    return -1;
}

// ventoinha: variantes 0-2 sopram (direita, cima, esquerda); 3-6 puxam (direita, cima, esquerda, baixo)
function variante_ventoinha(_v)
{
    if (_v < 3) return [_v, 0];
    return [_v - 3, 1];
}

// variáveis da instância (as mesmas Variable Definitions que se mudam na room) para cada variante
function props_peca(_i, _v)
{
    switch (global.pecas[_i].k)
    {
        case "duto": return {numero: _v + 1};
        case "espinho": return {direcao: _v};
        case "cabo": return {desligado: _v};
        case "portao": return {cor: _v};
        case "botao": return {cor: _v % 4, comeca_ativo: (_v >= 4) ? 1 : 0};
        case "ventoinha":
            var vt = variante_ventoinha(_v);
            return {direcao: vt[0], puxa: vt[1]};
        case "laser": return {direcao: _v, fase_pulso: -1};
    }
    return {};
}

function nome_variante(_i, _v)
{
    switch (global.pecas[_i].k)
    {
        case "espinho": return ["no chão (aponta p/ cima)", "no teto (aponta p/ baixo)", "na parede da direita (aponta p/ esquerda)", "na parede da esquerda (aponta p/ direita)"][_v];
        case "cabo": return (_v == 1) ? "começa SEM energia (o rato não religa)" : "com energia";
        case "duto": return "nº " + string(_v + 1) + " (liga com o nº " + string(2 - _v) + ")";
        case "portao": return global.cores_nomes[_v];
        case "botao": return global.cores_nomes[_v % 4] + ((_v >= 4) ? ", começa ativo" : "");
        case "ventoinha":
            var vt = variante_ventoinha(_v);
            return (vt[1] ? "puxa " : "sopra ") + global.dir_nomes[vt[0]];
        case "laser": return "para " + global.dir_nomes[_v];
    }
    return "";
}

// sprite e quadro que o editor mostra. Os spr_ed_* têm a origem deslocada: ficam certos com a peça no canto da célula.
function sprite_peca(_i, _v)
{
    switch (global.pecas[_i].k)
    {
        case "rato": return spr_ed_rato;
        case "chave": return spr_ed_chave;
        case "porta": return spr_ed_porta;
        case "pedra": return spr_pedra;
        case "cano": return spr_cano;
        case "plataforma": return spr_plataforma;
        case "espinho": return spr_espinho;
        case "poca": return spr_poca;
        case "duto": return spr_duto;
        case "portao": return [spr_portao_0, spr_portao_1, spr_portao_2, spr_portao_3][_v];
        case "botao": return [spr_botao_0, spr_botao_1, spr_botao_2, spr_botao_3][_v % 4];
        case "ventoinha":
            var vt = variante_ventoinha(_v);
            var vertical = (vt[0] == 1 || vt[0] == 3);
            if (vt[1]) return vertical ? spr_vent_suga_v : spr_vent_suga_h;
            return vertical ? spr_vent_sopra_v : spr_vent_sopra_h;
        case "laser": return spr_laser;
        case "caixa": return spr_caixa;
        case "cabo": return spr_ed_cabo;
        case "lampada": return spr_ed_lampada;
        case "barril": return spr_ed_barril;
        case "camera": return spr_ed_camera;
        case "queijo": return spr_ed_queijo;
        case "guarda": return spr_ed_guarda_g;
        case "guarda_lanterna": return spr_ed_guarda_l;
        case "eletricista": return spr_ed_guarda_f;
        case "cao": return spr_ed_cao;
    }
    return spr_pixel;
}

function quadro_peca(_i, _v)
{
    switch (global.pecas[_i].k)
    {
        case "cabo": return 0;
        case "ventoinha": return floor(global.tempo_jogo * 12) % 4;
        case "botao": return (_v >= 4) ? 1 : 0;
        case "laser": return [0, 2, 1, 3][_v];
        case "pedra": return 4;
        case "plataforma": return 8;
    }
    return 0;
}

// desenha a peça como o jogo desenha, com o canto da célula em (_x, _y)
function desenha_peca(_i, _v, _x, _y, _esc, _alfa)
{
    if (global.pecas[_i].k == "espinho") { desenha_espinho(_x, _y, _v, _esc, _alfa); return; }
    draw_sprite_ext(sprite_peca(_i, _v), quadro_peca(_i, _v), _x, _y, _esc, _esc, 0, c_white, _alfa);
}

// a célula do editor tem a peça _k? (para emendar canos e plataformas)
function editor_tem(_i, _j, _k)
{
    if (_i < 0 || _j < 0 || _i >= CRIADOR_COL || _j >= CRIADOR_LIN) return false;
    var c = global.ed.grade[_j][_i];
    if (c < 0) return false;
    return global.pecas[floor(c / 8)].k == _k;
}

// o editor emenda o visual da pedra pelos vizinhos (fora da grade conta como pedra)
function editor_pedra(_i, _j)
{
    if (_i < 0 || _j < 0 || _i >= CRIADOR_COL || _j >= CRIADOR_LIN) return true;
    var c = global.ed.grade[_j][_i];
    if (c < 0) return false;
    var k = global.pecas[floor(c / 8)].k;
    return k == "pedra";
}

#endregion


#region grade

function grade_vazia()
{
    var g = [];
    for (var j = 0; j < CRIADOR_LIN; j++)
    {
        var fileira = [];
        for (var i = 0; i < CRIADOR_COL; i++) array_push(fileira, -1);
        array_push(g, fileira);
    }
    return g;
}

// fase nova: já vem com pedra em volta (dá para apagar)
function grade_nova()
{
    var g = grade_vazia();
    var pedra = indice_peca("pedra") * 8;
    for (var j = 0; j < CRIADOR_LIN; j++)
    {
        for (var i = 0; i < CRIADOR_COL; i++)
        {
            if (i == 0 || j == 0 || i == CRIADOR_COL - 1 || j == CRIADOR_LIN - 1) g[j][i] = pedra;
        }
    }
    return g;
}

function copia_grade(_g)
{
    var c = [];
    for (var j = 0; j < CRIADOR_LIN; j++)
    {
        var fileira = [];
        for (var i = 0; i < CRIADOR_COL; i++) array_push(fileira, _g[j][i]);
        array_push(c, fileira);
    }
    return c;
}

function conta_pecas(_g)
{
    var n = [];
    for (var k = 0; k < array_length(global.pecas); k++) array_push(n, 0);
    for (var j = 0; j < CRIADOR_LIN; j++)
    {
        for (var i = 0; i < CRIADOR_COL; i++)
        {
            if (_g[j][i] >= 0) n[floor(_g[j][i] / 8)]++;
        }
    }
    return n;
}

// "" se a fase tem o mínimo para ser jogada; senão o que está faltando
function problemas_fase(_g)
{
    var n = conta_pecas(_g);
    if (n[indice_peca("rato")] == 0) return "Falta o RATO (início)";
    if (n[indice_peca("chave")] == 0) return "Falta a CHAVE";
    if (n[indice_peca("porta")] == 0) return "Falta a PORTA";
    // os dutos andam em par (nº 1 e nº 2): um sozinho não leva a lugar nenhum
    var d1 = 0, d2 = 0, ip = indice_peca("duto");
    for (var j = 0; j < CRIADOR_LIN; j++)
    {
        for (var i = 0; i < CRIADOR_COL; i++)
        {
            if (_g[j][i] == ip * 8) d1++;
            if (_g[j][i] == ip * 8 + 1) d2++;
        }
    }
    if (d1 > 0 && d2 == 0) return "Falta o duto nº 2 (par do nº 1)";
    if (d2 > 0 && d1 == 0) return "Falta o duto nº 1 (par do nº 2)";
    return "";
}

#endregion


#region código de compartilhar

function b64_char(_n)
{
    return string_char_at(ALFA_B64, _n + 1);
}

function b64_valor(_c)
{
    if (_c == "") return -1;
    return string_pos(_c, ALFA_B64) - 1;
}

// só letras maiúsculas, números e espaço, até 16 caracteres
function limpa_nome(_s)
{
    _s = string_upper(_s);
    var r = "";
    for (var k = 1; k <= string_length(_s); k++)
    {
        var c = string_char_at(_s, k);
        if (string_pos(c, NOME_CHARS) > 0 && string_length(r) < 16) r += c;
    }
    return r;
}

// soma de verificação de 4 caracteres
function soma_codigo(_s, _n = 4)
{
    var h = 7919;
    for (var k = 1; k <= string_length(_s); k++) h = (h * 131 + ord(string_char_at(_s, k)) + k) % 16777213;
    h = (h * 977 + 40503) % 16777213;
    var r = "";
    for (var k = 0; k < _n; k++)
    {
        r += b64_char(h % 64);
        h = floor(h / 64);
    }
    return r;
}

// ---- formato "R4": o código inteiro é uma fila de bits (6 bits viram 1 caractere), bem menor que os antigos RL2/RL3 ----
// bits: tamanho do nome (5) + nome (6 cada) + n peças diferentes (8) + n códigos de peça (9 cada) + trechos até cobrir as 220 células.
// Cada trecho = símbolo (0 vazio, 1..n peça da lista, n+1 "igual à célula de cima") + quantas células seguidas (código gama: curto para números pequenos).
function bits_de(_v, _n)
{
    var r = "";
    for (var k = _n - 1; k >= 0; k--) r += (floor(_v / power(2, k)) % 2 == 1) ? "1" : "0";
    return r;
}

// leitor de bits: {s: texto de 0 e 1, p: posição}; devolve -1 se faltar bit
function le_bits(_r, _n)
{
    if (_r.p + _n - 1 > string_length(_r.s)) return -1;
    var v = 0;
    for (var k = 0; k < _n; k++)
    {
        v = v * 2 + ((string_char_at(_r.s, _r.p) == "1") ? 1 : 0);
        _r.p++;
    }
    return v;
}

function bits_gama(_v)
{
    var nb = 0;
    while (power(2, nb + 1) <= _v) nb++;
    var z = "";
    for (var k = 0; k < nb; k++) z += "0";
    return z + bits_de(_v, nb + 1);
}

function le_gama(_r)
{
    var z = 0;
    var b = le_bits(_r, 1);
    while (b == 0 && z < 9) { z++; b = le_bits(_r, 1); }
    if (b != 1) return -1;
    var resto = (z > 0) ? le_bits(_r, z) : 0;
    if (resto < 0) return -1;
    return power(2, z) + resto;
}

function bits_largura(_n)
{
    var w = 1;
    while (power(2, w) < _n) w++;
    return w;
}

function codifica_fase(_f)
{
    var nome = limpa_nome(_f.nome);
    var bits = bits_de(string_length(nome), 5);
    for (var k = 1; k <= string_length(nome); k++) bits += bits_de(string_pos(string_char_at(nome, k), NOME_CHARS) - 1, 6);
    var total = CRIADOR_COL * CRIADOR_LIN;
    var plano = [];
    var lista = [];
    for (var q = 0; q < total; q++)
    {
        var c = _f.grade[floor(q / CRIADOR_COL)][q % CRIADOR_COL];
        array_push(plano, c);
        if (c >= 0 && array_get_index(lista, c) < 0) array_push(lista, c);
    }
    var n = array_length(lista);
    bits += bits_de(n, 8);
    for (var k = 0; k < n; k++) bits += bits_de(lista[k], 9);
    var w = bits_largura(n + 2);
    var q = 0;
    while (q < total)
    {
        var mesmo = 1;
        while (q + mesmo < total && plano[q + mesmo] == plano[q]) mesmo++;
        var cima = 0;
        if (q >= CRIADOR_COL)
        {
            while (q + cima < total && plano[q + cima] == plano[q + cima - CRIADOR_COL]) cima++;
        }
        if (cima > mesmo) { bits += bits_de(n + 1, w) + bits_gama(cima); q += cima; }
        else
        {
            bits += bits_de((plano[q] < 0) ? 0 : array_get_index(lista, plano[q]) + 1, w) + bits_gama(mesmo);
            q += mesmo;
        }
    }
    while (string_length(bits) % 6 != 0) bits += "0";
    var s = "R4";
    for (var k = 0; k < string_length(bits); k += 6)
    {
        var grupo = {s: string_copy(bits, k + 1, 6), p: 1};
        s += b64_char(le_bits(grupo, 6));
    }
    return s + soma_codigo(s, 3);
}

// lê um código "R4" (texto já limpo); devolve a fase ou undefined
function decodifica_r4(_t)
{
    var total_ch = string_length(_t);
    if (total_ch < 8) return undefined;
    var corpo = string_copy(_t, 1, total_ch - 3);
    if (soma_codigo(corpo, 3) != string_copy(_t, total_ch - 2, 3)) return undefined;
    var bits = "";
    for (var k = 3; k <= string_length(corpo); k++) bits += bits_de(b64_valor(string_char_at(corpo, k)), 6);
    var r = {s: bits, p: 1};
    var tam = le_bits(r, 5);
    if (tam < 0 || tam > 16) return undefined;
    var nome = "";
    for (var k = 0; k < tam; k++)
    {
        var v = le_bits(r, 6);
        if (v < 0 || v >= string_length(NOME_CHARS)) return undefined;
        nome += string_char_at(NOME_CHARS, v + 1);
    }
    var n = le_bits(r, 8);
    if (n < 0) return undefined;
    var lista = [];
    for (var k = 0; k < n; k++)
    {
        var c = le_bits(r, 9);
        if (c < 0) return undefined;
        array_push(lista, c);
    }
    var w = bits_largura(n + 2);
    var g = grade_vazia();
    var total = CRIADOR_COL * CRIADOR_LIN;
    var plano = array_create(total, -1);
    var pos = 0;
    while (pos < total)
    {
        var sim = le_bits(r, w);
        var rep = le_gama(r);
        if (sim < 0 || rep < 0 || sim > n + 1 || pos + rep > total) return undefined;
        for (var k = 0; k < rep; k++)
        {
            if (sim == n + 1)
            {
                if (pos < CRIADOR_COL) return undefined;
                plano[pos] = plano[pos - CRIADOR_COL];
            }
            else plano[pos] = (sim == 0) ? -1 : lista[sim - 1];
            pos++;
        }
    }
    for (var q = 0; q < total; q++)
    {
        if (plano[q] >= 0 && !poe_peca_codigo(g, q, plano[q])) return undefined;
    }
    if (problemas_fase(g) != "") return undefined;
    return {nome: nome, grade: g, validada: true, slot: -1};
}

// formato antigo "RL3": "RL3" + tamanho do nome + nome + n + n códigos de peça (2 caracteres) + trechos (peça, repetições) + soma. Só lê (não escreve mais).
// põe a peça de código _c na célula _pos da grade _g (mesmas regras para o formato novo e o antigo); false = código inválido
function poe_peca_codigo(_g, _pos, _c)
{
    var idx = floor(_c / 8);
    if (idx >= array_length(global.pecas) || _c % 8 >= global.pecas[idx].nvar) return false;
    if (global.pecas[idx].k == "piso")
    {
        // códigos antigos: o piso virou bloco de cor (mesma regra: sólido quando o botão da cor está ativo), mesma cor
        _c = (_c % 8 < 2) ? indice_peca("portao") * 8 + (_c % 8) : -1;
        idx = (_c < 0) ? idx : floor(_c / 8);
    }
    if (_c >= 0 && !global.pecas[idx].oculta) _g[floor(_pos / CRIADOR_COL)][_pos % CRIADOR_COL] = _c;   // peça removida some da fase
    return true;
}

// devolve a fase (já marcada como validada) ou undefined se o texto estiver errado/alterado. Aceita "RL3" e o antigo "RL2".
function decodifica_fase(_texto)
{
    var t = "";
    for (var k = 1; k <= string_length(_texto); k++)
    {
        var ch = string_char_at(_texto, k);
        if (b64_valor(ch) >= 0) t += ch;          // ignora espaços e quebras de linha
    }
    var total = string_length(t);
    if (string_copy(t, 1, 2) == "R4") return decodifica_r4(t);
    var versao = string_copy(t, 1, 3);
    if (total < 12 || (versao != "RL2" && versao != "RL3")) return undefined;
    var corpo = string_copy(t, 1, total - 4);
    if (soma_codigo(corpo) != string_copy(t, total - 3, 4)) return undefined;

    var p = 4;
    var tam = b64_valor(string_char_at(t, p));
    p++;
    if (tam < 0 || tam > 16) return undefined;
    var nome = "";
    for (var k = 0; k < tam; k++)
    {
        var v = b64_valor(string_char_at(t, p));
        p++;
        if (v < 0 || v >= string_length(NOME_CHARS)) return undefined;
        nome += string_char_at(NOME_CHARS, v + 1);
    }

    var g = grade_vazia();
    var pos = 0;
    var fim = string_length(corpo);
    if (versao == "RL2")
    {
        while (p + 3 <= fim)
        {
            var vazias = b64_valor(string_char_at(t, p)) * 64 + b64_valor(string_char_at(t, p + 1));
            var c = b64_valor(string_char_at(t, p + 2)) * 64 + b64_valor(string_char_at(t, p + 3));
            p += 4;
            pos += vazias;
            if (pos >= CRIADOR_COL * CRIADOR_LIN) return undefined;
            if (!poe_peca_codigo(g, pos, c)) return undefined;
            pos++;
        }
        if (p != fim + 1) return undefined;
    }
    else
    {
        var n = b64_valor(string_char_at(t, p));
        p++;
        var lista = [];
        for (var k = 0; k < n; k++)
        {
            if (p + 1 > fim) return undefined;
            array_push(lista, b64_valor(string_char_at(t, p)) * 64 + b64_valor(string_char_at(t, p + 1)));
            p += 2;
        }
        while (p + 1 <= fim)
        {
            var qual = b64_valor(string_char_at(t, p));
            var rep = b64_valor(string_char_at(t, p + 1)) + 1;
            p += 2;
            if (qual < 0 || qual > n || pos + rep > CRIADOR_COL * CRIADOR_LIN) return undefined;
            for (var r = 0; r < rep; r++)
            {
                if (qual > 0 && !poe_peca_codigo(g, pos, lista[qual - 1])) return undefined;
                pos++;
            }
        }
        if (p != fim + 1) return undefined;
    }
    if (problemas_fase(g) != "") return undefined;
    return {nome: nome, grade: g, validada: true, slot: -1};
}

#endregion


#region fases salvas (ratlock.ini)

function carrega_custom()
{
    global.custom_salvas = [];
    ini_open("ratlock.ini");
    var n = ini_read_real("custom", "n", 0);
    for (var i = 0; i < n; i++)
    {
        var f = decodifica_fase(ini_read_string("custom", "c" + string(i), ""));
        if (f != undefined)
        {
            f.slot = array_length(global.custom_salvas);
            array_push(global.custom_salvas, f);
        }
    }
    ini_close();
}

function grava_custom()
{
    ini_open("ratlock.ini");
    ini_write_real("custom", "n", array_length(global.custom_salvas));
    for (var i = 0; i < array_length(global.custom_salvas); i++)
    {
        ini_write_string("custom", "c" + string(i), codifica_fase(global.custom_salvas[i]));
    }
    ini_close();
}

#endregion


#region jogar a fase criada

// cria as instâncias da fase em rm_custom (chamado no Room Start, antes de monta_fase)
function constroi_fase_custom()
{
    var f = global.custom_atual;
    var queijos = 0;
    for (var j = 0; j < CRIADOR_LIN; j++)
    {
        for (var i = 0; i < CRIADOR_COL; i++)
        {
            var c = f.grade[j][i];
            if (c < 0) continue;
            var idx = floor(c / 8);
            instance_create_layer(i * TL, j * TL, "Instances", global.pecas[idx].obj, props_peca(idx, c % 8));
            if (global.pecas[idx].k == "queijo") queijos++;
        }
    }
    return {mundo: -1, nome: f.nome, tempo_par: 0, objetivo3: "chave", tem_queijo: queijos};
}

#endregion
