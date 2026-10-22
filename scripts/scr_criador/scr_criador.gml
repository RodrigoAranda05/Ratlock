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

function nova_peca(_k, _nome, _obj, _nvar, _unica, _esc)
{
    return {k: _k, nome: _nome, obj: _obj, nvar: _nvar, unica: _unica, esc: _esc};
}

// ATENÇÃO: a ordem desta lista faz parte do código de compartilhar. Só acrescente peças no FIM.
// esc = escala do ícone na paleta (peças altas ficam menores).
function carrega_pecas()
{
    global.pecas = [
        nova_peca("rato", "Rato (início)", obj_player, 1, true, 1),
        nova_peca("chave", "Chave", obj_chave, 1, true, 1),
        nova_peca("porta", "Porta (saída)", obj_porta, 1, true, 0.6),
        nova_peca("pedra", "Pedra", obj_pedra, 1, false, 1),
        nova_peca("pedra_falsa", "Parede falsa", obj_pedra_falsa, 1, false, 1),
        nova_peca("cano", "Cano (escalar)", obj_cano, 1, false, 1),
        nova_peca("espinho", "Espinho", obj_espinho, 1, false, 1),
        nova_peca("poca", "Poça", obj_poca, 1, false, 1),
        nova_peca("ventilacao", "Grade de ventilação", obj_ventilacao, 1, false, 1),
        nova_peca("duto", "Duto", obj_duto, 4, false, 1),
        nova_peca("portao", "Portão", obj_portao, 4, false, 1),
        nova_peca("piso", "Piso de cor", obj_piso, 4, false, 1),
        nova_peca("botao", "Botão", obj_botao, 8, false, 1),
        nova_peca("ventoinha", "Ventoinha", obj_ventoinha, 7, false, 1),
        nova_peca("laser", "Laser", obj_laser, 4, false, 1),
        nova_peca("caixa", "Caixa", obj_caixa, 1, false, 1),
        nova_peca("cabo", "Cabo de energia", obj_cabo, 1, false, 1),
        nova_peca("lampada", "Lâmpada", obj_lampada, 1, false, 1),
        nova_peca("barril", "Barril", obj_barril, 1, false, 1),
        nova_peca("camera", "Câmera", obj_camera, 1, false, 1),
        nova_peca("queijo", "Queijo", obj_queijo, 1, false, 1),
        nova_peca("guarda", "Guarda", obj_guarda, 1, false, 0.9),
        nova_peca("guarda_lanterna", "Guarda com lanterna", obj_guarda_lanterna, 1, false, 0.9),
        nova_peca("guarda_noturno", "Guarda noturno", obj_guarda_noturno, 1, false, 0.9),
        nova_peca("eletricista", "Eletricista", obj_eletricista, 1, false, 0.9),
        nova_peca("cao", "Cão farejador", obj_cao, 1, false, 1),
        nova_peca("cacador", "Caçador", obj_cacador, 1, false, 1),
        nova_peca("sentinela", "Sentinela", obj_sentinela, 1, false, 0.8)
    ];
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
        case "portao": return {cor: _v};
        case "piso": return {cor: _v};
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
        case "duto": return "nº " + string(_v + 1) + ((_v < 2) ? " (par azul)" : " (par laranja)");
        case "portao": return global.cores_nomes[_v];
        case "piso": return global.cores_nomes[_v];
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
        case "pedra_falsa": return spr_pedra_falsa;
        case "cano": return spr_cano;
        case "espinho": return spr_espinho;
        case "poca": return spr_poca;
        case "ventilacao": return spr_ventilacao;
        case "duto": return (_v < 2) ? spr_duto_azul : spr_duto_laranja;
        case "portao": return [spr_portao_0, spr_portao_1, spr_portao_2, spr_portao_3][_v];
        case "piso": return [spr_piso_0, spr_piso_1, spr_piso_2, spr_piso_3][_v];
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
        case "guarda_noturno": return spr_ed_guarda_n;
        case "eletricista": return spr_ed_guarda_f;
        case "cao": return spr_ed_cao;
        case "cacador": return spr_ed_cacador;
        case "sentinela": return spr_ed_sentinela;
    }
    return spr_pixel;
}

function quadro_peca(_i, _v)
{
    switch (global.pecas[_i].k)
    {
        case "duto": return floor(global.tempo_jogo * 4) % 4;
        case "ventoinha": return floor(global.tempo_jogo * 12) % 4;
        case "botao": return (_v >= 4) ? 1 : 0;
        case "laser": return [0, 3, 1, 2][_v] * 4;
    }
    return 0;
}

// desenha a peça como o jogo desenha, com o canto da célula em (_x, _y)
function desenha_peca(_i, _v, _x, _y, _esc, _alfa)
{
    draw_sprite_ext(sprite_peca(_i, _v), quadro_peca(_i, _v), _x, _y, _esc, _esc, 0, c_white, _alfa);
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
function soma_codigo(_s)
{
    var h = 7919;
    for (var k = 1; k <= string_length(_s); k++) h = (h * 131 + ord(string_char_at(_s, k)) + k) % 16777213;
    h = (h * 977 + 40503) % 16777213;
    var r = "";
    for (var k = 0; k < 4; k++)
    {
        r += b64_char(h % 64);
        h = floor(h / 64);
    }
    return r;
}

// formato: "RL2" + tamanho do nome + nome + itens + soma
// cada item (4 caracteres) = quantas células vazias vieram antes (2 caracteres) + código da peça (2 caracteres)
function codifica_fase(_f)
{
    var nome = limpa_nome(_f.nome);
    var s = "RL2" + b64_char(string_length(nome));
    for (var k = 1; k <= string_length(nome); k++) s += b64_char(string_pos(string_char_at(nome, k), NOME_CHARS) - 1);
    var vazias = 0;
    for (var j = 0; j < CRIADOR_LIN; j++)
    {
        for (var i = 0; i < CRIADOR_COL; i++)
        {
            var c = _f.grade[j][i];
            if (c < 0) { vazias++; continue; }
            s += b64_char(floor(vazias / 64)) + b64_char(vazias % 64) + b64_char(floor(c / 64)) + b64_char(c % 64);
            vazias = 0;
        }
    }
    return s + soma_codigo(s);
}

// devolve a fase (já marcada como validada) ou undefined se o texto estiver errado/alterado
function decodifica_fase(_texto)
{
    var t = "";
    for (var k = 1; k <= string_length(_texto); k++)
    {
        var ch = string_char_at(_texto, k);
        if (b64_valor(ch) >= 0) t += ch;          // ignora espaços e quebras de linha
    }
    var total = string_length(t);
    if (total < 12 || string_copy(t, 1, 3) != "RL2") return undefined;
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
    while (p + 3 <= fim)
    {
        var vazias = b64_valor(string_char_at(t, p)) * 64 + b64_valor(string_char_at(t, p + 1));
        var c = b64_valor(string_char_at(t, p + 2)) * 64 + b64_valor(string_char_at(t, p + 3));
        p += 4;
        pos += vazias;
        if (pos >= CRIADOR_COL * CRIADOR_LIN) return undefined;
        var idx = floor(c / 8);
        if (idx >= array_length(global.pecas) || c % 8 >= global.pecas[idx].nvar) return undefined;
        g[floor(pos / CRIADOR_COL)][pos % CRIADOR_COL] = c;
        pos++;
    }
    if (p != fim + 1) return undefined;
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
