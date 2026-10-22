// ===== obj_criador: telas do criador de fases (lista de fases do jogador e editor) =====
// Persistente, criado pelo obj_game. Só reage quando global.estado é "lista_custom" ou "editor".
// A fase em edição fica em global.ed = {nome, grade, validada, slot}; as funções de peças, código e
// montagem da fase estão em scr_criador. O mouse desenha a fase; o teclado cuida do resto.

if (instance_number(obj_criador) > 1) { instance_destroy(); exit; }
persistent = true;
depth = -10001;

#region estado

sel = 3;                    // peça escolhida na paleta (índice em global.pecas; -1 = borracha)
var_sel = 0;                // variante da peça (cor, direção...)
estado_visto = "";         // último global.estado que este objeto viu (evita usar a mesma tecla em duas telas)
nomeando = false;           // digitando o nome da fase
salva_depois_do_nome = false;
msg = "";                   // aviso temporário
msg_tempo = 0;
confirma = "";              // ação que espera a segunda tecla ("apagar", "limpar")
confirma_tempo = 0;
lista_cursor = 0;
lista_rolagem = 0;
mx = 0;                     // mouse no layout 480x272
my = 0;

// layout (unidades do layout 480x272)
// (o desenho fixo dessas áreas está no spr_fundo_criador, que é o fundo da rm_criador: dá para ver na room)
grade_x = 4;
grade_y = 22;
paleta_x = 332;
paleta_y = 22;
botoes = [
    {texto: "TESTAR  (T)", acao: "testar"},
    {texto: "SALVAR  (S)", acao: "salvar"},
    {texto: "NOME  (N)", acao: "nome"},
    {texto: "COPIAR CÓDIGO  (C)", acao: "copiar"}
];

#endregion


#region utilidades

avisa = function(_s)
{
    msg = _s;
    msg_tempo = 3.5;
}

// espera uma segunda tecla igual para confirmar uma ação perigosa
pede_confirmacao = function(_acao, _texto)
{
    if (confirma == _acao && confirma_tempo > 0) { confirma = ""; return true; }
    confirma = _acao;
    confirma_tempo = 2.5;
    avisa(_texto);
    return false;
}

novo_rascunho = function()
{
    global.ed = {nome: "", grade: grade_nova(), validada: false, slot: -1};
    sel = indice_peca("pedra");
    var_sel = 0;
}

// slot da paleta: 0 = borracha, 1.. = peças
slot_x = function(_s) { return paleta_x + (_s % 6) * 24; }
slot_y = function(_s) { return paleta_y + floor(_s / 6) * 22; }

slot_sob_mouse = function()
{
    for (var s = 0; s <= array_length(global.pecas); s++)
    {
        if (mx >= slot_x(s) && mx < slot_x(s) + 20 && my >= slot_y(s) && my < slot_y(s) + 20) return s;
    }
    return -2;
}

celula_sob_mouse = function()
{
    var i = floor((mx - grade_x) / TL);
    var j = floor((my - grade_y) / TL);
    if (i < 0 || j < 0 || i >= CRIADOR_COL || j >= CRIADOR_LIN) return undefined;
    return [i, j];
}

botao_y = function(_n) { return 140 + _n * 17; }

botao_sob_mouse = function()
{
    for (var n = 0; n < array_length(botoes); n++)
    {
        if (mx >= paleta_x && mx < paleta_x + 144 && my >= botao_y(n) && my < botao_y(n) + 14) return n;
    }
    return -1;
}

#endregion


#region editor: ações

escolhe_peca = function(_i)
{
    sel = clamp(_i, -1, array_length(global.pecas) - 1);
    var_sel = 0;
}

gira_variante = function()
{
    if (sel < 0) return;
    var_sel = (var_sel + 1) % global.pecas[sel].nvar;
}

// põe (ou apaga) uma peça numa célula. Qualquer mudança tira a validação da fase.
aplica_celula = function(_i, _j, _apaga)
{
    var ed = global.ed;
    var novo = (_apaga || sel < 0) ? -1 : sel * 8 + var_sel;
    if (ed.grade[_j][_i] == novo) return;
    if (novo >= 0 && global.pecas[sel].unica)
    {
        // rato, chave e porta só existem uma vez: a anterior sai do lugar
        for (var j = 0; j < CRIADOR_LIN; j++)
        {
            for (var i = 0; i < CRIADOR_COL; i++)
            {
                if (ed.grade[j][i] >= 0 && floor(ed.grade[j][i] / 8) == sel) ed.grade[j][i] = -1;
            }
        }
    }
    ed.grade[_j][_i] = novo;
    ed.validada = false;
}

testar = function()
{
    var ed = global.ed;
    var problema = problemas_fase(ed.grade);
    if (problema != "") { avisa(problema); return; }
    inicia_custom({nome: ed.nome, grade: copia_grade(ed.grade)}, "teste");
}

salvar = function()
{
    var ed = global.ed;
    var problema = problemas_fase(ed.grade);
    if (problema != "") { avisa(problema); return; }
    if (!ed.validada) { avisa("Passe da fase no TESTAR para poder salvar"); return; }
    if (ed.nome == "")
    {
        nomeando = true;
        salva_depois_do_nome = true;
        keyboard_string = "";
        return;
    }
    var copia = {nome: ed.nome, grade: copia_grade(ed.grade), validada: true, slot: ed.slot};
    if (ed.slot >= 0) global.custom_salvas[ed.slot] = copia;
    else
    {
        copia.slot = array_length(global.custom_salvas);
        array_push(global.custom_salvas, copia);
        ed.slot = copia.slot;
        global.stats.fases_criadas++;
        grava_save();
    }
    grava_custom();
    avisa("Fase salva! C copia o código para compartilhar");
}

copiar_codigo = function(_f)
{
    if (!_f.validada) { avisa("Passe da fase no TESTAR para poder compartilhar"); return; }
    clipboard_set_text(codifica_fase(_f));
    avisa("Código copiado! Mande para um amigo");
}

limpar = function()
{
    if (!pede_confirmacao("limpar", "Aperte X de novo para limpar tudo")) return;
    global.ed.grade = grade_nova();
    global.ed.validada = false;
}

executa_acao = function(_a)
{
    if (_a == "testar") testar();
    else if (_a == "salvar") salvar();
    else if (_a == "nome") { nomeando = true; salva_depois_do_nome = false; keyboard_string = global.ed.nome; }
    else if (_a == "copiar") copiar_codigo(global.ed);
}

#endregion


#region lista de fases do jogador

monta_itens = function()
{
    var it = [{t: "novo"}];
    if (global.ed != undefined && global.ed.slot < 0) array_push(it, {t: "rasc"});
    array_push(it, {t: "imp"});
    for (var i = 0; i < array_length(global.custom_salvas); i++) array_push(it, {t: "fase", i: i});
    return it;
}

importa_clipboard = function()
{
    if (!clipboard_has_text()) { avisa("Copie o código de uma fase primeiro"); return; }
    var f = decodifica_fase(clipboard_get_text());
    if (f == undefined) { avisa("Código inválido ou alterado"); return; }
    var novo = codifica_fase(f);
    for (var i = 0; i < array_length(global.custom_salvas); i++)
    {
        if (codifica_fase(global.custom_salvas[i]) == novo) { avisa("Essa fase já está na sua lista"); return; }
    }
    f.slot = array_length(global.custom_salvas);
    array_push(global.custom_salvas, f);
    grava_custom();
    lista_cursor = array_length(monta_itens()) - 1;
    avisa("Fase importada: " + ((f.nome == "") ? "SEM NOME" : f.nome));
}

apaga_fase = function(_i)
{
    array_delete(global.custom_salvas, _i, 1);
    for (var k = 0; k < array_length(global.custom_salvas); k++) global.custom_salvas[k].slot = k;
    if (global.ed != undefined && global.ed.slot == _i) global.ed.slot = -1;
    else if (global.ed != undefined && global.ed.slot > _i) global.ed.slot--;
    grava_custom();
    lista_cursor = min(lista_cursor, array_length(monta_itens()) - 1);
    avisa("Fase apagada");
}

#endregion


#region desenho

desenha_lista = function()
{
    desenha_rect(0, 0, VW, VH, 0x070b11);        // cobre o desenho do editor, que é o fundo desta room
    desenha_texto("CRIAR FASES", VW / 2, 20, 0xffd84a, "center", 18);
    desenha_texto("Monte uma fase, passe dela para provar que dá para vencer e compartilhe o código", VW / 2, 38, 0xa9b4c4, "center", 9);
    var it = monta_itens();
    var visiveis = 9;
    var y0 = 54;
    for (var n = 0; n < array_length(it); n++)
    {
        if (n < lista_rolagem || n >= lista_rolagem + visiveis) continue;
        var yy = y0 + (n - lista_rolagem) * 19;
        var a = it[n];
        desenha_rect(60, yy, 360, 17, 0x1b2433);
        if (n == lista_cursor) desenha_moldura(60, yy, 360, 17);
        var cor = (n == lista_cursor) ? 0xf3efe6 : 0xa9b4c4;
        if (a.t == "novo") desenha_texto("+ NOVA FASE", 72, yy + 9, 0x4ade80, "left", 12);
        else if (a.t == "rasc") desenha_texto("> CONTINUAR O RASCUNHO" + ((global.ed.nome != "") ? "  (" + global.ed.nome + ")" : ""), 72, yy + 9, 0xffd84a, "left", 12);
        else if (a.t == "imp") desenha_texto("COLAR CÓDIGO DE UMA FASE  (Ctrl+V)", 72, yy + 9, 0x7cc4ff, "left", 12);
        else
        {
            var f = global.custom_salvas[a.i];
            desenha_texto(string(a.i + 1) + ".  " + ((f.nome == "") ? "SEM NOME" : f.nome), 72, yy + 9, cor, "left", 12);
            desenha_texto("validada", 408, yy + 9, 0x4ade80, "right", 9);
        }
    }
    if (lista_rolagem > 0) desenha_seta_rolagem_c(VW / 2, 46, -1);
    if (lista_rolagem + visiveis < array_length(it)) desenha_seta_rolagem_c(VW / 2, y0 + visiveis * 19 + 1, 1);
    if (msg_tempo > 0) desenha_texto(msg, VW / 2, 238, 0xffe9a0, "center", 11);
    var sel_item = (lista_cursor < array_length(it)) ? it[lista_cursor] : undefined;
    if (sel_item != undefined && sel_item.t == "fase") desenha_texto("Enter: jogar  ·  E: editar  ·  C: copiar código  ·  Del: apagar  ·  Esc: voltar", VW / 2, 258, 0x7d8798, "center", 9);
    else desenha_texto("Enter: escolher  ·  Ctrl+V: colar código  ·  Esc: voltar", VW / 2, 258, 0x7d8798, "center", 9);
}

desenha_seta_rolagem_c = function(_x, _y, _dir)
{
    for (var k = 0; k < 4; k++)
    {
        var larg = 1 + k * 2;
        var yy = (_dir < 0) ? _y + k : _y + 3 - k;
        desenha_rect(_x - floor(larg / 2), yy, larg, 1, 0xffd84a);
    }
}

desenha_editor = function()
{
    var ed = global.ed;
    // o fundo (barra de cima, grade, paleta e botões) é o spr_fundo_criador da rm_criador; aqui vai só o que muda

    // barra de cima: nome, peça escolhida (ou aviso) e situação
    desenha_texto((ed.nome == "") ? "SEM NOME" : ed.nome, 6, 9, 0xf3efe6, "left", 10);
    var meio = "";
    var meio_cor = 0xa9b4c4;
    if (msg_tempo > 0) { meio = msg; meio_cor = 0xffe9a0; }
    else if (sel < 0) meio = "Borracha";
    else
    {
        meio = global.pecas[sel].nome;
        var nv = nome_variante(sel, var_sel);
        if (nv != "") meio += "  ·  " + nv + "  (R muda)";
    }
    desenha_texto(meio, 130, 9, meio_cor, "left", 10);
    desenha_texto(ed.validada ? "VALIDADA" : "NÃO VALIDADA", VW - 6, 9, ed.validada ? 0x4ade80 : 0xff6b5e, "right", 10);

    // grade
    for (var j = 0; j < CRIADOR_LIN; j++)
    {
        for (var i = 0; i < CRIADOR_COL; i++)
        {
            var c = ed.grade[j][i];
            if (c >= 0) desenha_peca(floor(c / 8), c % 8, grade_x + i * TL, grade_y + j * TL, 1, 1);
        }
    }

    // célula sob o mouse: prévia da peça
    var cel = celula_sob_mouse();
    if (cel != undefined && !nomeando)
    {
        var cx = grade_x + cel[0] * TL;
        var cy = grade_y + cel[1] * TL;
        if (sel >= 0) desenha_peca(sel, var_sel, cx, cy, 1, 0.55);
        desenha_rect_alfa(cx, cy, TL, TL, (sel < 0) ? 0xff4030 : 0xffd84a, 0.22);
    }

    // paleta
    var sob = slot_sob_mouse();
    for (var s = 0; s <= array_length(global.pecas); s++)
    {
        var px = slot_x(s), py = slot_y(s);
        if (s == sob) desenha_rect(px, py, 20, 20, 0x2a3750);
        if (s == 0) desenha_texto("X", px + 10, py + 11, 0xff6b5e, "center", 14);
        else
        {
            var pc = global.pecas[s - 1];
            var e = pc.esc;
            desenha_peca(s - 1, (s - 1 == sel) ? var_sel : 0, px + 10 - 8 * e, py + 20 - 16 * e, e, 1);
        }
        if (s - 1 == sel) desenha_moldura(px, py, 20, 20);
    }

    // botões
    var bsob = botao_sob_mouse();
    for (var n = 0; n < array_length(botoes); n++)
    {
        var by = botao_y(n);
        if (n == bsob) desenha_rect(paleta_x, by, 144, 14, 0x2a3750);
        var bcor = 0xf3efe6;
        if (botoes[n].acao == "salvar" || botoes[n].acao == "copiar") bcor = ed.validada ? 0x4ade80 : 0x5b6578;
        desenha_texto(botoes[n].texto, paleta_x + 72, by + 8, bcor, "center", 9);
    }

    desenha_texto("Clique: pôr  ·  Botão direito: apagar  ·  Roda ou Q/E: trocar peça  ·  R: cor/direção", 6, 214, 0x7d8798, "left", 9);
    desenha_texto("T: testar  ·  S: salvar  ·  C: copiar código  ·  N: nome  ·  X: limpar  ·  Esc: voltar", 6, 228, 0x7d8798, "left", 9);
    desenha_texto("Para salvar ou compartilhar, passe da fase no teste (sem cheats).", 6, 244, 0x5b6578, "left", 9);

    // digitando o nome
    if (nomeando)
    {
        desenha_rect_alfa(0, 0, VW, VH, 0x05080e, 0.8);
        desenha_rect(110, 100, 260, 56, 0x1b2433);
        desenha_moldura(110, 100, 260, 56);
        desenha_texto("NOME DA FASE", VW / 2, 114, 0xffd84a, "center", 11);
        desenha_texto(ed.nome + ((floor(global.tempo_jogo * 2) % 2 == 0) ? "_" : " "), VW / 2, 134, 0xf3efe6, "center", 14);
        desenha_texto("Enter: confirmar  ·  Esc: cancelar", VW / 2, 150, 0x7d8798, "center", 8);
    }
}

#endregion
