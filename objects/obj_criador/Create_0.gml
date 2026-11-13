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
// animações do editor (valores de 0 a 1 que vão atrás do alvo)
anim_slot = array_create(40, 0);        // mouse em cima do slot da paleta
anim_ativo = array_create(40, 0);       // slot da peça escolhida (fica levantado)
pulso_slot = array_create(40, 0);       // aperto ao clicar (de 1 a 0)
anim_botao = array_create(8, 0);
pulso_botao = array_create(8, 0);
plops = [];                             // "puf" quando uma peça é posta ou apagada numa célula
mx = 0;                     // mouse no layout 480x272
my = 0;

// layout (unidades do layout 480x272)
// (o desenho fixo dessas áreas está no spr_fundo_criador, que é o fundo da rm_criador: dá para ver na room)
grade_x = 80;
grade_y = 75;
paleta_x = 11;      // a paleta fica em cima, em 2 fileiras de 15 casas
paleta_y = 19;
botoes = [
    {texto: "TESTAR (T)", acao: "testar"},
    {texto: "SALVAR (S)", acao: "salvar"},
    {texto: "COPIAR (C)", acao: "copiar"},
    {texto: "NOME (N)", acao: "nome"},
    {texto: "LIMPAR (X)", acao: "limpar"},
    {texto: "VOLTAR (Esc)", acao: "voltar"}
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
slot_x = function(_s) { return paleta_x + (_s % 15) * 31; }
slot_y = function(_s) { return paleta_y + floor(_s / 15) * 27; }

slot_sob_mouse = function()
{
    for (var s = 0; s <= array_length(global.pecas_vis); s++)
    {
        if (mx >= slot_x(s) && mx < slot_x(s) + 24 && my >= slot_y(s) && my < slot_y(s) + 24) return s;
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

// botões nas duas laterais da grade: 3 à esquerda e 3 à direita
botao_x = function(_n) { return (_n < 3) ? 4 : 406; }
botao_y = function(_n) { return grade_y + 6 + (_n % 3) * 32; }

botao_sob_mouse = function()
{
    for (var n = 0; n < array_length(botoes); n++)
    {
        if (mx >= botao_x(n) && mx < botao_x(n) + 70 && my >= botao_y(n) && my < botao_y(n) + 24) return n;
    }
    return -1;
}

#endregion


#region editor: ações

escolhe_peca = function(_i)
{
    var passo = (_i < sel) ? -1 : 1;
    sel = clamp(_i, -1, array_length(global.pecas) - 1);
    while (sel >= 0 && global.pecas[sel].oculta) sel = clamp(sel + passo, -1, array_length(global.pecas) - 1);   // pula peça removida
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
    if (novo >= 0 && global.pecas[sel].k == "duto")
    {
        // só um par de dutos: cada número (1 e 2) existe uma vez e o anterior sai do lugar
        for (var j = 0; j < CRIADOR_LIN; j++)
        {
            for (var i = 0; i < CRIADOR_COL; i++)
            {
                if (ed.grade[j][i] == novo) ed.grade[j][i] = -1;
            }
        }
    }
    array_push(plops, {i: _i, j: _j, t: 0, c: (novo < 0) ? 0xff6b5e : 0xffd84a});
    if (novo >= 0) toca_som("snd_botao", 0.35, 1.4);
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
    else if (_a == "limpar") limpar();
    else if (_a == "voltar") global.estado = "lista_custom";
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
    desenha_fundo_tela(1);                       // cobre o desenho do editor, que é o fundo desta room
    desenha_fundo_diag(60, 100, 0xa8c0ff);
    desenha_titulo_faixa("CRIAR FASES", "Monte, teste e compartilhe com um código");
    var it = monta_itens();
    var visiveis = 8;
    var y0 = 60;
    for (var n = 0; n < array_length(it); n++)
    {
        if (n < lista_rolagem || n >= lista_rolagem + visiveis) continue;
        var yy = y0 + (n - lista_rolagem) * 22;
        var a = it[n];
        var sel = (n == lista_cursor);
        desenha_cartao(70, yy, 360, 19, sel, false);
        var cor = sel ? 0xffffff : 0xc4cee0;
        if (a.t == "novo") desenha_texto("+ NOVA FASE", 92, yy + 10, 0x4ade80, "left", 11);
        else if (a.t == "rasc") desenha_texto("CONTINUAR O RASCUNHO" + ((global.ed.nome != "") ? "  (" + global.ed.nome + ")" : ""), 92, yy + 10, 0xffd84a, "left", 11);
        else if (a.t == "imp") desenha_texto("COLAR CÓDIGO DE UMA FASE  (Ctrl+V)", 92, yy + 10, 0x7cc4ff, "left", 11);
        else
        {
            var f = global.custom_salvas[a.i];
            desenha_texto(string(a.i + 1) + ".  " + ((f.nome == "") ? "SEM NOME" : f.nome), 92, yy + 10, cor, "left", 11);
            desenha_texto("validada", 414, yy + 10, 0x4ade80, "right", 8);
        }
    }
    if (lista_rolagem > 0) desenha_seta_rolagem_c(VW / 2 + 20, 52, -1);
    if (lista_rolagem + visiveis < array_length(it)) desenha_seta_rolagem_c(VW / 2 + 20, y0 + visiveis * 22, 1);
    if (msg_tempo > 0) desenha_texto(msg, VW / 2, 242, 0xffe9a0, "center", 11);
    var sel_item = (lista_cursor < array_length(it)) ? it[lista_cursor] : undefined;
    if (sel_item != undefined && sel_item.t == "fase") desenha_dicas(262, [["Enter", "jogar"], ["E", "editar"], ["C", "copiar código"], ["Del", "apagar"], ["Esc", "voltar"]]);
    else desenha_dicas(262, [["Enter", "escolher"], ["Ctrl+V", "colar código"], ["Esc", "voltar"]]);
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
            if (c < 0) continue;
            var k = global.pecas[floor(c / 8)].k;
            if (k == "pedra")
            {
                // pedra escolhe o bloco do tileset pelos vizinhos, igual ao jogo
                var q = bloco_pedra(!editor_pedra(i, j - 1), !editor_pedra(i, j + 1), !editor_pedra(i - 1, j), !editor_pedra(i + 1, j),
                    !editor_pedra(i - 1, j - 1), !editor_pedra(i + 1, j - 1), !editor_pedra(i - 1, j + 1), !editor_pedra(i + 1, j + 1), i, j);
                draw_sprite(spr_pedra, q, grade_x + i * TL, grade_y + j * TL);
            }
            else if (k == "cano")
            {
                var qc = quadro_cano(editor_tem(i, j - 1, "cano"), editor_tem(i, j + 1, "cano"), editor_tem(i - 1, j, "cano"), editor_tem(i + 1, j, "cano"),
                    editor_pedra(i - 1, j), editor_pedra(i + 1, j), editor_pedra(i, j - 1), editor_pedra(i, j + 1));
                draw_sprite(spr_cano, qc, grade_x + i * TL, grade_y + j * TL);
            }
            else if (k == "plataforma")
            {
                var pe = editor_tem(i - 1, j, "plataforma"), pd = editor_tem(i + 1, j, "plataforma");
                var we = editor_tem(i - 1, j, "pedra"), wd = editor_tem(i + 1, j, "pedra");
                var esp = plataforma_espelha(pe, pd, we, wd);
                draw_sprite_ext(spr_plataforma, quadro_plataforma(pe, pd, we, wd), grade_x + i * TL + (esp ? TL : 0), grade_y + j * TL, esp ? -1 : 1, 1, 0, c_white, 1);
            }
            else if (k == "cabo")
            {
                // os fios aparecem sozinhos: sobem até o teto e descem até o chão
                for (var jj = j - 1; jj >= 0 && ed.grade[jj][i] < 0; jj--) draw_sprite(spr_fio, 0, grade_x + i * TL, grade_y + jj * TL);
                for (var jj = j + 1; jj < CRIADOR_LIN && ed.grade[jj][i] < 0; jj++) draw_sprite(spr_fio, 0, grade_x + i * TL, grade_y + jj * TL);
                draw_sprite(spr_cabo, 2 + ((c % 8 == 1) ? 7 : 0), grade_x + i * TL, grade_y + j * TL);
            }
            else desenha_peca(floor(c / 8), c % 8, grade_x + i * TL, grade_y + j * TL, 1, 1);
        }
    }
    var t = global.tempo_jogo;
    // célula sob o mouse: peça fantasma flutuando e cantoneiras que pulsam
    var cel = celula_sob_mouse();
    if (cel != undefined && !nomeando)
    {
        var cx = grade_x + cel[0] * TL;
        var cy = grade_y + cel[1] * TL;
        var cor_m = (sel < 0) ? 0xff6b5e : 0xffd84a;
        desenha_rect_alfa(cx, cy, TL, TL, cor_m, 0.16 + 0.08 * sin(t * 8));
        if (sel >= 0) desenha_peca(sel, var_sel, cx, cy + round(sin(t * 5)), 1, 0.6);
        var press = mouse_check_button(mb_left) || mouse_check_button(mb_right);
        var of = press ? -1 : round(0.5 + 0.5 * sin(t * 8));
        var cl = 4;
        for (var q = 0; q < 4; q++)
        {
            var qx = (q % 2 == 0) ? cx - of : cx + TL + of - 1;
            var qy = (q < 2) ? cy - of : cy + TL + of - 1;
            var dx = (q % 2 == 0) ? 1 : -1, dy = (q < 2) ? 1 : -1;
            desenha_rect(qx, qy, 1, cl * dy, 0xffffff);
            desenha_rect(qx, qy, cl * dx, 1, 0xffffff);
            if (dx < 0) desenha_rect(qx - cl + 1, qy, cl, 1, 0xffffff);
            if (dy < 0) desenha_rect(qx, qy - cl + 1, 1, cl, 0xffffff);
        }
    }
    // "puf" das peças postas
    var novos = [];
    for (var q = 0; q < array_length(plops); q++)
    {
        var pp = plops[q];
        pp.t += DT * 3.2;
        if (pp.t >= 1) continue;
        array_push(novos, pp);
        var tam = TL + pp.t * 14;
        var px0 = grade_x + pp.i * TL + TL / 2 - tam / 2, py0 = grade_y + pp.j * TL + TL / 2 - tam / 2;
        var al = 1 - pp.t;
        desenha_rect_alfa(px0, py0, tam, 1, pp.c, al); desenha_rect_alfa(px0, py0 + tam - 1, tam, 1, pp.c, al);
        desenha_rect_alfa(px0, py0, 1, tam, pp.c, al); desenha_rect_alfa(px0 + tam - 1, py0, 1, tam, pp.c, al);
    }
    plops = novos;

    // paleta: o slot sob o mouse sobe um pouco, o da peça escolhida fica levantado e brilha, o clicado "aperta"
    var sob = slot_sob_mouse();
    var ordem = [];
    for (var s = 0; s <= array_length(global.pecas_vis); s++) { if (((s == 0) ? -1 : global.pecas_vis[s - 1]) != sel) array_push(ordem, s); }
    for (var s = 0; s <= array_length(global.pecas_vis); s++) { if (((s == 0) ? -1 : global.pecas_vis[s - 1]) == sel) array_push(ordem, s); }
    for (var o = 0; o < array_length(ordem); o++)
    {
        var s = ordem[o];
        var ps = (s == 0) ? -1 : global.pecas_vis[s - 1];
        anim_slot[s] = lerp(anim_slot[s], (s == sob) ? 1 : 0, 0.3);
        anim_ativo[s] = lerp(anim_ativo[s], (ps == sel) ? 1 : 0, 0.25);
        pulso_slot[s] = max(0, pulso_slot[s] - DT * 7);
        var px = slot_x(s), py = slot_y(s);
        var lift = round(anim_slot[s] * 2 + anim_ativo[s] * 3 - pulso_slot[s] * 3);
        var fundo = merge_color(0x1b2433, 0x2f4268, max(anim_slot[s] * 0.7, anim_ativo[s]));
        if (lift > 0) desenha_rect_alfa(px + 1, py + 4, 24, 22, 0x000000, 0.4);
        desenha_rect(px, py - lift, 24, 24, 0x0a0e15);
        desenha_rect(px + 1, py - lift + 1, 22, 22, fundo);
        desenha_rect(px + 1, py - lift + 1, 22, 1, merge_color(fundo, 0xffffff, 0.2));
        desenha_rect(px + 1, py - lift + 22, 22, 1, merge_color(fundo, 0x000000, 0.35));
        if (s == 0) desenha_texto("X", px + 12, py - lift + 13, 0xff6b5e, "center", 14);
        else
        {
            var e = global.pecas[ps].esc;
            desenha_peca(ps, (ps == sel) ? var_sel : 0, px + 12 - 8 * e, py - lift + 22 - 16 * e, e, 1);
        }
        if (ps == sel)
        {
            var br = (floor(t * 4) % 2 == 0) ? 0xffd84a : 0xffe9a0;
            desenha_rect(px - 1, py - lift - 1, 26, 1, br); desenha_rect(px - 1, py - lift + 24, 26, 1, br);
            desenha_rect(px - 1, py - lift - 1, 1, 26, br); desenha_rect(px + 24, py - lift - 1, 1, 26, br);
            desenha_rect_alfa(px - 3, py - lift - 3, 30, 30, 0xffd84a, 0.10 + 0.06 * sin(t * 5));
        }
    }
    // dica com o nome da peça sob o mouse
    if (sob >= 0 && !nomeando)
    {
        var nome_s = (sob == 0) ? "Borracha" : global.pecas[global.pecas_vis[sob - 1]].nome;
        var lw = largura_texto(nome_s, 9) + 10;
        var tx = clamp(mx + 8, 2, VW - lw - 2), ty = my + 12;
        desenha_rect(tx - 1, ty - 1, lw + 2, 15, 0x05080e);
        desenha_rect(tx, ty, lw, 13, 0x1d2940);
        desenha_texto(nome_s, tx + 5, ty + 7, 0xf3efe6, "left", 9);
    }

    // botões: o sob o mouse desliza uma barra de destaque; o clicado pisca
    var bsob = botao_sob_mouse();
    for (var n = 0; n < array_length(botoes); n++)
    {
        var by = botao_y(n), bx = botao_x(n);
        anim_botao[n] = lerp(anim_botao[n], (n == bsob) ? 1 : 0, 0.3);
        pulso_botao[n] = max(0, pulso_botao[n] - DT * 6);
        var bh = anim_botao[n];
        desenha_rect_alfa(bx + 1, by + 3, 70, 22, 0x000000, 0.35 * bh);
        desenha_rect(bx, by - round(bh * 2), 70, 24, 0x0a0e15);
        desenha_rect(bx + 1, by - round(bh * 2) + 1, 68, 22, merge_color(0x1b2433, 0x2f4268, bh));
        desenha_rect(bx + 1, by - round(bh * 2) + 1, 68, 1, merge_color(0x1b2433, 0xffffff, 0.2));
        desenha_rect(bx + 1, by - round(bh * 2) + 1, round(bh * 3) + 1, 22, 0xffd84a);
        if (pulso_botao[n] > 0) desenha_rect_alfa(bx, by - round(bh * 2), 70, 24, 0xffffff, pulso_botao[n] * 0.5);
        var bcor = 0xf3efe6;
        if (botoes[n].acao == "salvar" || botoes[n].acao == "copiar") bcor = ed.validada ? 0x4ade80 : 0x5b6578;
        desenha_texto(botoes[n].texto, bx + 35 + round(bh * 2), by - round(bh * 2) + 13, bcor, "center", 9);
    }

    desenha_texto("Clique: pôr  ·  Botão direito: apagar  ·  Roda ou Q/E: trocar peça  ·  R: cor/direção  ·  Esc: voltar", VW / 2, 262, 0x7d8798, "center", 8);

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
