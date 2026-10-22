// ===== obj_ui: menus, HUD e efeitos de tela =====
// Persistente, criado pelo obj_game. Lê o teclado dos menus, desenha o HUD, as partículas, as zonas de vento
// e as telas (título, mundos, seleção de fase, sala concluída, fim). O estado vem de global.estado.

if (instance_number(obj_ui) > 1) { instance_destroy(); exit; }
persistent = true;
depth = -10000;

#region menus e cheats

// As listas rolam: só aparecem LINHAS_FASE linhas de fases e LINHAS_MUNDO linhas de mundos por vez,
// e a rolagem acompanha o cursor. Funciona com qualquer quantidade de fases/mundos.
#macro COLUNAS_FASE 4
#macro LINHAS_FASE 2
#macro COLUNAS_MUNDO 2
#macro LINHAS_MUNDO 3

celula_fase = function(_n)
{
    return [25 + (_n % COLUNAS_FASE) * 110, 74 + (floor(_n / COLUNAS_FASE) - global.fase_rolagem) * 92];
}

celula_mundo = function(_n)
{
    return [28 + (_n % COLUNAS_MUNDO) * 226, 40 + (floor(_n / COLUNAS_MUNDO) - global.mundo_rolagem) * 74];
}

// deixa a linha do cursor dentro da janela de rolagem
ajusta_rolagem = function()
{
    var lin = floor(global.fase_cursor / COLUNAS_FASE);
    if (lin < global.fase_rolagem) global.fase_rolagem = lin;
    if (lin >= global.fase_rolagem + LINHAS_FASE) global.fase_rolagem = lin - LINHAS_FASE + 1;
    var lm = floor(global.mundo_cursor / COLUNAS_MUNDO);
    if (lm < global.mundo_rolagem) global.mundo_rolagem = lm;
    if (lm >= global.mundo_rolagem + LINHAS_MUNDO) global.mundo_rolagem = lm - LINHAS_MUNDO + 1;
}

// setinha de "tem mais para cima/baixo": _dir -1 aponta para cima, 1 para baixo
desenha_seta_rolagem = function(_x, _y, _dir)
{
    for (var k = 0; k < 4; k++)
    {
        var larg = 1 + k * 2;
        var yy = (_dir < 0) ? _y + k : _y + 3 - k;
        desenha_rect(_x - floor(larg / 2), yy, larg, 1, 0xffd84a);
    }
}

moldura = function(_x, _y, _w, _h)
{
    desenha_moldura(_x, _y, _w, _h);
}

titulo = function(_s, _y, _c, _z)
{
    desenha_texto(_s, VW / 2, _y, _c, "center", _z);
}

objetivos = function(_L)
{
    var t3 = "";
    if (_L.objetivo3 == "cabo") t3 = "Sem roer cabos";
    else if (_L.objetivo3 == "chave") t3 = "Sem soltar a chave";
    else t3 = "Em até " + string(round(_L.tempo_par * 0.65)) + "s";
    return ["Sem morrer", "Em até " + string(_L.tempo_par) + "s", t3];
}

tecla_menu = function(_k)
{
    var tela = global.estado;
    if (tela == "title")
    {
        if (_k == "up") global.menu_cursor = (global.menu_cursor + 2) % 3;
        else if (_k == "down") global.menu_cursor = (global.menu_cursor + 1) % 3;
        else if (_k == "ok")
        {
            if (global.menu_cursor == 0) global.estado = "worlds";
            else if (global.menu_cursor == 1) inicia_fase(0, "challenge");
            else { global.estado = "lista_custom"; global.modo = "normal"; room_goto(rm_criador); }
        }
    }
    else if (tela == "worlds")
    {
        var n = array_length(global.mundos);
        if (_k == "left") global.mundo_cursor = max(0, global.mundo_cursor - 1);
        else if (_k == "right") global.mundo_cursor = min(n - 1, global.mundo_cursor + 1);
        else if (_k == "up") global.mundo_cursor = max(0, global.mundo_cursor - COLUNAS_MUNDO);
        else if (_k == "down") global.mundo_cursor = min(n - 1, global.mundo_cursor + COLUNAS_MUNDO);
        else if (_k == "ok")
        {
            if (mundo_liberado(global.mundo_cursor))
            {
                global.mundo_sel = global.mundo_cursor;
                var l = fases_do_mundo(global.mundo_cursor);
                var k = -1;
                for (var i = 0; i < array_length(l); i++)
                {
                    var a = global.save.estrelas[l[i]];
                    if (k < 0 && a[0] + a[1] + a[2] == 0) k = i;
                }
                var liberadas = 0;
                for (var i = 0; i < array_length(l); i++) { if (l[i] <= fases_liberadas()) liberadas++; }
                global.fase_cursor = max(0, min((k < 0) ? 0 : k, liberadas - 1));
                global.estado = "select";
            }
        }
        else if (_k == "esc") global.estado = "title";
    }
    else if (tela == "select")
    {
        var l = fases_do_mundo(global.mundo_sel);
        if (_k == "left") global.fase_cursor = max(0, global.fase_cursor - 1);
        else if (_k == "right") global.fase_cursor = min(array_length(l) - 1, global.fase_cursor + 1);
        else if (_k == "up" && global.fase_cursor >= COLUNAS_FASE) global.fase_cursor -= COLUNAS_FASE;
        else if (_k == "down" && global.fase_cursor + COLUNAS_FASE < array_length(l)) global.fase_cursor += COLUNAS_FASE;
        else if (_k == "down" && floor(global.fase_cursor / COLUNAS_FASE) < floor((array_length(l) - 1) / COLUNAS_FASE)) global.fase_cursor = array_length(l) - 1;
        else if (_k == "ok")
        {
            if (l[global.fase_cursor] <= fases_liberadas()) inicia_fase(l[global.fase_cursor], "normal");
        }
        else if (_k == "esc") global.estado = "worlds";
    }
    else if (tela == "play")
    {
        if (_k == "r") { global.fase_nova = false; room_restart(); }
        else if (_k == "esc")
        {
            if (global.modo == "teste" || global.modo == "custom") sai_custom();
            else if (global.modo == "challenge") { global.estado = "title"; room_goto(rm_menu); }
            else
            {
                global.mundo_sel = global.info_fase.mundo;
                global.mundo_cursor = global.mundo_sel;
                global.fase_cursor = max(0, array_get_index(fases_do_mundo(global.mundo_sel), global.fase_atual));
                global.estado = "select";
                room_goto(rm_menu);
            }
        }
    }
    else if (tela == "clear")
    {
        if (global.tempo_tela > 0.5)
        {
            if (_k == "ok") proxima_fase();
            else if (_k == "r") { global.fase_nova = true; global.estado = "play"; room_restart(); }
            else if (_k == "esc")
            {
                if (global.modo == "teste" || global.modo == "custom") { sai_custom(); return; }
                global.mundo_sel = global.info_fase.mundo;
                global.mundo_cursor = global.mundo_sel;
                global.fase_cursor = max(0, array_get_index(fases_do_mundo(global.mundo_sel), global.fase_atual));
                global.estado = "select";
                room_goto(rm_menu);
            }
        }
    }
    else if (tela == "win")
    {
        if (global.tempo_tela > 0.8 && (_k == "ok" || _k == "esc")) global.estado = "title";
    }
}

cheat_alterna = function()
{
    global.cheat = !global.cheat;
    global.trapaceou = true;            // se o teste de uma fase criada passar por aqui, ela não valida
    if (!global.cheat) global.invencivel = false;
    mostra_aviso(global.cheat ? "Cheats ligados (progresso não é salvo)" : "Cheats desligados", 2.5);
}

cheat_faz = function(_a)
{
    if (!global.cheat) return;
    var p = global.jogador;
    if (_a == "inv")
    {
        global.invencivel = !global.invencivel;
        mostra_aviso(global.invencivel ? "Invencível ligado" : "Invencível desligado", 2);
        return;
    }
    if (_a == "key")
    {
        if (global.estado == "play" && !global.tem_chave && instance_exists(global.chave) && !p.morto)
        {
            global.chave.estado = "carried";
            global.tem_chave = true;
            global.chave.tempo_livre = 0;
            mostra_aviso("Chave na boca (cheat)", 2);
        }
        return;
    }
    if (_a == "win")
    {
        if (global.estado == "play" && !p.morto) fase_concluida();
        return;
    }
    var jogando = (global.estado == "play" || global.estado == "clear");
    var base = 0;
    if (jogando) base = global.fase_atual;
    else if (global.estado == "select") base = fases_do_mundo(global.mundo_sel)[global.fase_cursor];
    var d = (_a == "next") ? 1 : -1;
    var alvo = base;
    if (jogando) alvo = max(0, min(array_length(global.fases) - 1, base + d));
    inicia_fase(alvo, "normal");
}

le_teclado = function()
{
    if (global.estado == "lista_custom" || global.estado == "editor") return;     // o obj_criador cuida dessas telas
    ajusta_rolagem();
    if (keyboard_check_pressed(vk_f1)) cheat_alterna();
    if (global.cheat)
    {
        if (keyboard_check_pressed(ord("N"))) { cheat_faz("next"); return; }
        if (keyboard_check_pressed(ord("B"))) { cheat_faz("prev"); return; }
        if (keyboard_check_pressed(ord("I"))) { cheat_faz("inv"); return; }
        if (keyboard_check_pressed(ord("Y"))) { cheat_faz("key"); return; }
        if (keyboard_check_pressed(ord("U"))) { cheat_faz("win"); return; }
    }
    if (keyboard_check_pressed(vk_up) || keyboard_check_pressed(ord("W"))) tecla_menu("up");
    if (keyboard_check_pressed(vk_down) || keyboard_check_pressed(ord("S"))) tecla_menu("down");
    if (keyboard_check_pressed(vk_left) || keyboard_check_pressed(ord("A"))) tecla_menu("left");
    if (keyboard_check_pressed(vk_right) || keyboard_check_pressed(ord("D"))) tecla_menu("right");
    if (keyboard_check_pressed(vk_enter) || keyboard_check_pressed(vk_space) || keyboard_check_pressed(ord("E"))) tecla_menu("ok");
    if (keyboard_check_pressed(vk_escape)) tecla_menu("esc");
    if (keyboard_check_pressed(ord("R"))) tecla_menu("r");
}

desenha_menus = function()
{
    var tela = global.estado;
    var agora = global.tempo_jogo;
    if (tela == "title")
    {
        // o fundo (spr_fundo_menu na rm_menu) já tem o logo e o subtítulo
        var opcoes = ["JOGAR", "MODO DESAFIO", "CRIAR FASES"];
        for (var k = 0; k < 3; k++)
            titulo(((global.menu_cursor == k) ? "> " : "  ") + opcoes[k] + ((global.menu_cursor == k) ? " <" : "  "), 130 + k * 26, (global.menu_cursor == k) ? 0xffd84a : 0xf3efe6, 16);
        var extra = "Estrelas: " + string(total_estrelas()) + "/" + string(array_length(global.fases) * 3) + "  ·  Queijos: " + string(total_queijos()) + "/" + string(total_queijos_max());
        if (global.save.desafio_tempo >= 0) extra += "  ·  Melhor desafio: " + formata_tempo(global.save.desafio_tempo) + " (" + string(global.save.desafio_mortes) + " mortes)";
        titulo(extra, 212, 0xa9b4c4, 10);
        titulo("Setas + Enter  ·  F1: cheats " + (global.cheat ? "ligados" : "desligados"), 238, 0x7d8798, 10);
    }
    else if (tela == "worlds")
    {
        desenha_rect_alfa(0, 0, VW, VH, 0x05080e, 0.9);
        titulo("MUNDOS", 20, 0xffd84a, 18);
        ajusta_rolagem();
        for (var k = 0; k < array_length(global.mundos); k++)
        {
            var lin_m = floor(k / COLUNAS_MUNDO);
            if (lin_m < global.mundo_rolagem || lin_m >= global.mundo_rolagem + LINHAS_MUNDO) continue;
            var c = celula_mundo(k), cel_x = c[0], cel_y = c[1];
            var lock = !mundo_liberado(k);
            var l = fases_do_mundo(k);
            desenha_rect(cel_x, cel_y, 214, 66, lock ? 0x10141b : 0x1b2433);
            if (k == global.mundo_cursor) moldura(cel_x, cel_y, 214, 66);
            desenha_texto("MUNDO " + string(k + 1), cel_x + 10, cel_y + 11, lock ? 0x4a5568 : 0x7d8798, "left", 9);
            desenha_texto(lock ? "Bloqueado" : global.mundos[k].n, cel_x + 10, cel_y + 27, lock ? 0x4a5568 : 0xf3efe6, "left", 15);
            desenha_texto(lock ? "Conclua o mundo anterior" : global.mundos[k].d, cel_x + 10, cel_y + 41, lock ? 0x4a5568 : 0xa9b4c4, "left", 8);
            if (!lock)
            {
                desenha_estrela(cel_x + 16, cel_y + 55, true);
                desenha_texto(string(mundo_estrelas(k)) + "/" + string(array_length(l) * 3), cel_x + 26, cel_y + 55, 0xffd23f, "left", 9);
                desenha_icone_queijo(cel_x + 90, cel_y + 55, true);
                desenha_texto(string(mundo_queijos(k)) + "/" + string(mundo_queijos_max(k)), cel_x + 100, cel_y + 55, 0xffd23f, "left", 9);
            }
        }
        if (global.mundo_rolagem > 0) desenha_seta_rolagem(VW / 2, 34, -1);
        if (global.mundo_rolagem + LINHAS_MUNDO < ceil(array_length(global.mundos) / COLUNAS_MUNDO)) desenha_seta_rolagem(VW / 2, 256, 1);
        titulo("Enter: abrir  ·  Esc: voltar", 266, 0x7d8798, 9);
    }
    else if (tela == "select")
    {
        desenha_rect_alfa(0, 0, VW, VH, 0x05080e, 0.9);
        titulo("MUNDO " + string(global.mundo_sel + 1) + " · " + string_upper(global.mundos[global.mundo_sel].n), 32, 0xffd84a, 18);
        var l = fases_do_mundo(global.mundo_sel);
        ajusta_rolagem();
        for (var n = 0; n < array_length(l); n++)
        {
            var lin_f = floor(n / COLUNAS_FASE);
            if (lin_f < global.fase_rolagem || lin_f >= global.fase_rolagem + LINHAS_FASE) continue;
            var idx = l[n];
            var L = global.fases[idx];
            var c = celula_fase(n), cel_x = c[0], cel_y = c[1];
            var lock = (idx > fases_liberadas());
            desenha_rect(cel_x, cel_y, 100, 82, lock ? 0x10141b : 0x1b2433);
            if (n == global.fase_cursor) moldura(cel_x, cel_y, 100, 82);
            desenha_texto(lock ? "--" : string(idx + 1), cel_x + 50, cel_y + 16, lock ? 0x4a5568 : 0xf3efe6, "center", 16);
            desenha_texto(lock ? "bloqueada" : L.nome, cel_x + 50, cel_y + 38, lock ? 0x4a5568 : 0xa9b4c4, "center", 8);
            var sv = global.save.estrelas[idx];
            for (var q = 0; q < 3; q++) desenha_estrela(cel_x + 50 - 20 + q * 20, cel_y + 82 - 16, !lock && sv[q] == 1);
            if (L.tem_queijo > 0 && !lock) desenha_icone_queijo(cel_x + 100 - 13, cel_y + 13, global.save.queijo[idx] == 1);
        }
        if (global.fase_rolagem > 0) desenha_seta_rolagem(VW / 2, 52, -1);
        if (global.fase_rolagem + LINHAS_FASE < ceil(array_length(l) / COLUNAS_FASE)) desenha_seta_rolagem(VW / 2, 252, 1);
        titulo("Enter: jogar  ·  Esc: mundos", 264, 0x7d8798, 9);
    }
    else if (tela == "clear")
    {
        var L = global.info_fase;
        desenha_rect_alfa(0, 0, VW, VH, 0x05080e, 0.68);
        titulo("SALA CONCLUÍDA!", 52, 0xffd84a, 26);
        titulo(L.nome, 80, 0xa9b4c4, 11);
        if (global.modo == "teste" || global.modo == "custom")
        {
            if (global.modo == "teste")
            {
                var valida = (global.ed != undefined && global.ed.validada);
                titulo(valida ? "FASE VALIDADA!" : "Fase NÃO validada (cheats usados)", 124, valida ? 0x4ade80 : 0xff6b5e, 16);
                titulo(valida ? "Agora você pode salvar e compartilhar esta fase." : "Zere a fase sem cheats para poder salvar.", 148, 0xa9b4c4, 11);
            }
            else titulo("Fase do jogador", 130, 0xa9b4c4, 14);
            titulo("Tempo: " + string_format(global.tempo_fase, 1, 1) + "s  ·  Mortes na sala: " + string(global.mortes_fase), 190, 0xa9b4c4, 10);
            if (global.tempo_tela > 0.5) titulo("Enter: " + ((global.modo == "teste") ? "voltar ao editor" : "voltar à lista") + "  ·  R: repetir", 242, 0x7d8798, 10);
        }
        else if (global.modo == "normal")
        {
            var metas = objetivos(L);
            for (var k = 0; k < 3; k++)
            {
                desenha_estrela(142, 118 + k * 26, global.estrelas_fase[k]);
                desenha_texto(metas[k], 162, 118 + k * 26, global.estrelas_fase[k] ? 0xf3efe6 : 0x7d8798, "left", 12);
            }
            if (global.queijo_fase >= 0)
            {
                desenha_icone_queijo(142, 194, global.queijo_fase == 1);
                desenha_texto((global.queijo_fase == 1) ? "Queijo coletado!" : "Queijo não coletado", 162, 194, (global.queijo_fase == 1) ? 0xffd23f : 0x7d8798, "left", 12);
            }
            titulo("Tempo: " + string_format(global.tempo_fase, 1, 1) + "s  ·  Mortes na sala: " + string(global.mortes_fase), 216, 0xa9b4c4, 10);
            if (global.cheat) titulo("Cheats ligados: progresso não é salvo", 229, 0xffd84a, 9);
            if (global.tempo_tela > 0.5)
            {
                var fim = (global.fase_atual + 1 >= array_length(global.fases) || global.fase_atual == global.fase_final);
                titulo("Enter: " + (fim ? "continuar" : "próxima") + "  ·  R: repetir  ·  Esc: salas", 242, 0x7d8798, 10);
            }
        }
        else titulo("Total: " + formata_tempo(global.tempo_total) + "  ·  Mortes: " + string(global.mortes), 130, 0xf3efe6, 14);
    }
    else if (tela == "win")
    {
        desenha_rect_alfa(0, 0, VW, VH, 0x05080e, 0.86);
        titulo("VOCÊ ESCAPOU!", 60, 0xffd84a, 30);
        if (global.modo == "challenge")
        {
            titulo("Tempo total: " + formata_tempo(global.tempo_total), 112, 0xf3efe6, 16);
            titulo("Mortes: " + string(global.mortes), 138, 0xf3efe6, 14);
            if (global.novo_recorde) titulo("NOVO RECORDE!", 166, 0x4ade80, 12);
            else titulo("Recorde: " + ((global.save.desafio_tempo >= 0) ? formata_tempo(global.save.desafio_tempo) + " (" + string(global.save.desafio_mortes) + " mortes)" : "-"), 166, 0xa9b4c4, 12);
        }
        else
        {
            titulo("Estrelas: " + string(total_estrelas()) + "/" + string(array_length(global.fases) * 3), 112, 0xf3efe6, 16);
            titulo("Queijos: " + string(total_queijos()) + "/" + string(total_queijos_max()), 138, 0xffd23f, 14);
            titulo((global.fase_atual == global.fase_final) ? "Mundo novo desbloqueado: COFRE (lasers e pisos)" : "Tente pegar todas as estrelas e queijos", 166, 0xa9b4c4, 11);
        }
        if (global.tempo_tela > 0.8) titulo("Enter: voltar ao menu", 226, 0x7d8798, 10);
    }
}

desenha_hud = function()
{
    var agora = global.tempo_jogo;
    var L = global.info_fase;
    desenha_rect(0, 0, VW, 16, 0x0e131b);
    desenha_rect(0, 16, VW, 1, 0x2a3446);
    desenha_texto("MORTES: " + string(global.mortes), 6, 9, 0xf3efe6, "left", 10);
    if (instance_exists(obj_botao))
    {
        desenha_rect(5, 20, 14, 8, 0x000000);
        desenha_rect(6, 21, 12, 6, (global.cor_ativa >= 0) ? cor_do_botao(global.cor_ativa) : 0x333333);
    }
    if (global.alarme) desenha_texto("ALARME", VW / 2, 9, (floor(agora * 6) % 2 == 1) ? 0xff4030 : 0xffd84a, "center", 10);
    if (global.modo == "challenge") desenha_texto("TOTAL " + formata_tempo(global.tempo_total), 84, 9, 0xa9b4c4, "left", 10);
    else if (global.modo == "teste" || global.modo == "custom") desenha_texto(string(floor(global.tempo_fase)) + "s", 84, 9, 0xa9b4c4, "left", 10);
    else desenha_texto(string(floor(global.tempo_fase)) + "s/" + string(L.tempo_par) + "s", 84, 9, 0xa9b4c4, "left", 10);
    desenha_texto(((global.fase_atual >= 0) ? string(global.fase_atual + 1) + "/" + string(array_length(global.fases)) + " " : "") + string_upper(L.nome), VW - 6, 9, 0xf3efe6, "right", 10);
    if (global.tem_chave)
    {
        desenha_rect(VW - 22, 22, 5, 5, 0xffd23f);
        desenha_rect(VW - 18, 24, 7, 2, 0xffd23f);
    }
    if (array_length(global.queijos) > 0)
    {
        var algum = false;
        for (var q = 0; q < array_length(global.queijos); q++) { if (global.queijos[q].pego) algum = true; }
        desenha_icone_queijo(VW - 34, 26, algum);
    }
    if (global.cheat)
    {
        desenha_texto("CHEATS" + (global.invencivel ? " · INVENCIVEL" : "") + "   N/B: fase · I: invencivel · Y: chave · U: concluir", 6, VH - 7, 0xffd84a, "left", 8);
    }
    if (global.aviso_tempo > 0 && global.estado == "play")
    {
        var s = global.aviso_texto;
        var w = largura_texto(s, 10);
        if (w > VW - 24)
        {
            // quebra em duas linhas
            var metade = floor(string_length(s) / 2);
            var pos = metade;
            while (pos > 1 && string_char_at(s, pos) != " ") pos--;
            var linha1 = string_copy(s, 1, pos - 1);
            var linha2 = string_copy(s, pos + 1, string_length(s));
            var larg_caixa = max(largura_texto(linha1, 10), largura_texto(linha2, 10)) + 14;
            desenha_rect_alfa(VW / 2 - larg_caixa / 2, VH - 18 - 30, larg_caixa, 30, 0x0a0e14, 0.85);
            desenha_texto(linha1, VW / 2, VH - 18 - 30 + 9, 0xffe9a0, "center", 10);
            desenha_texto(linha2, VW / 2, VH - 18 - 30 + 22, 0xffe9a0, "center", 10);
        }
        else
        {
            desenha_rect_alfa(VW / 2 - w / 2 - 7, VH - 18 - 17, w + 14, 17, 0x0a0e14, 0.85);
            desenha_texto(s, VW / 2, VH - 18 - 17 + 9, 0xffe9a0, "center", 10);
        }
    }
}

cor_do_botao = function(_n)
{
    switch (_n)
    {
        case 0: return 0xe5484d;
        case 1: return 0x3b82f6;
        case 2: return 0x22c55e;
    }
    return 0xeab308;
}

// zonas de vento (setas animadas): o sprite aponta pra direita e gira conforme a ventoinha
desenha_vento = function()
{
    var quadro = floor(global.tempo_jogo * 12) % 4;
    for (var j = 0; j < GH; j++)
    {
        for (var i = 0; i < GW; i++)
        {
            var c = global.mapa_vento[j][i];
            if (c == "") continue;
            var angulo = 0;
            if (c == "U" || c == "n") angulo = 90;
            else if (c == "u") angulo = 270;
            else if (c == "r" || c == "Y") angulo = 180;
            var puxando = (string_pos(c, "unry") > 0);
            draw_sprite_ext(spr_vento, quadro, i * TL + 8, j * TL + 8, 1, 1, angulo, cor_rgb(puxando ? 0xffd6aa : 0xe1f2ff), 1);
        }
    }
}

// partículas: faíscas que os outros objetos criam com faiscas()
atualiza_particulas = function()
{
    var vivas = [];
    for (var q = 0; q < array_length(global.particulas); q++)
    {
        var fagulha = global.particulas[q];
        fagulha.l -= DT;
        fagulha.vy += 300 * DT;
        fagulha.x += fagulha.vx * DT;
        fagulha.y += fagulha.vy * DT;
        if (fagulha.l > 0) array_push(vivas, fagulha);
    }
    global.particulas = vivas;
}

#endregion
