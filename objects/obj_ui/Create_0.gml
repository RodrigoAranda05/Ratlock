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

// toca os sons do menu em volta da lógica de tecla_menu_base
tecla_menu = function(_k)
{
    var tela = global.estado;
    var antes = global.sair_op * 1000000000 + global.sair_confirma * 3000000000 + global.menu_cursor + global.mundo_cursor * 100 + global.fase_cursor * 10000 + global.cfg_cursor * 1000000 + global.des_cursor * 100000000;
    var bloq = (tela == "worlds" && !mundo_liberado(global.mundo_cursor)) || (tela == "select" && fases_do_mundo(global.mundo_sel)[global.fase_cursor] > fases_liberadas());
    tecla_menu_base(_k);
    if (tela != "title" && tela != "worlds" && tela != "select" && tela != "stats" && tela != "config" && tela != "desafio" && tela != "rank") return;
    if (_k == "ok") { if (bloq) toca_som("snd_pouso", 0.6, 0.7); else toca_som("snd_menu_ok"); }
    else if (_k == "esc") toca_som("snd_menu_volta");
    else if (_k != "r" && antes != global.sair_op * 1000000000 + global.sair_confirma * 3000000000 + global.menu_cursor + global.mundo_cursor * 100 + global.fase_cursor * 10000 + global.cfg_cursor * 1000000 + global.des_cursor * 100000000) toca_som("snd_menu_move");
}

tecla_menu_base = function(_k)
{
    var tela = global.estado;
    // --- pausa durante a fase ---
    if (tela == "play" && global.pausa)
    {
        if (_k == "r") { global.pausa = false; global.fase_nova = true; vai_para(-1, "play"); return; }
        if (global.pausa_sair_confirma)
        {
            if (_k == "left" || _k == "right" || _k == "up" || _k == "down") global.sair_op = 1 - global.sair_op;
            else if (_k == "ok") { if (global.sair_op == 0) { grava_save(); game_end(); } else global.pausa_sair_confirma = false; }
            else if (_k == "esc") global.pausa_sair_confirma = false;
            return;
        }
        if (_k == "up") global.pausa_cursor = (global.pausa_cursor + 4) % 5;
        else if (_k == "down") global.pausa_cursor = (global.pausa_cursor + 1) % 5;
        else if (_k == "esc") global.pausa = false;
        else if (_k == "ok")
        {
            if (global.pausa_cursor == 0) global.pausa = false;
            else if (global.pausa_cursor == 1) { global.pausa = false; global.fase_nova = true; vai_para(-1, "play"); }
            else if (global.pausa_cursor == 2) { global.cfg_cursor = 0; global.pausa = false; global.estado = "config"; global.volta_para_pausa = true; }
            else if (global.pausa_cursor == 3) { global.pausa = false; grava_save(); vai_para(rm_menu, "title"); }
            else { global.pausa_sair_confirma = true; global.sair_op = 1; }
        }
        return;
    }
    if (tela == "play")
    {
        if (_k == "r") { global.fase_nova = true; vai_para(-1, "play"); }
        else if (_k == "esc")
        {
            // testando uma fase criada: Esc volta direto para o editor (sem passar pelo menu de pausa)
            if (global.modo == "teste") { sai_custom(); return; }
            // jogando uma fase custom: Esc volta direto para a lista de fases
            if (global.modo == "custom") { sai_custom(); return; }
            global.pausa = true;
            global.pausa_cursor = 0;
            global.pausa_sair_confirma = false;
        }
        return;
    }
    if (tela == "title" && global.sair_confirma)
    {
        if (_k == "left" || _k == "right" || _k == "up" || _k == "down") global.sair_op = 1 - global.sair_op;
        else if (_k == "ok") { if (global.sair_op == 0) { grava_save(); game_end(); } else global.sair_confirma = false; }
        else if (_k == "esc") global.sair_confirma = false;
        return;
    }
    if (tela == "title")
    {
        if (_k == "esc") { global.sair_confirma = true; global.sair_op = 1; }
        else if (_k == "up") global.menu_cursor = (global.menu_cursor + 5) % 6;
        else if (_k == "down") global.menu_cursor = (global.menu_cursor + 1) % 6;
        else if (_k == "ok")
        {
            if (global.menu_cursor == 0) global.estado = "worlds";
            else if (global.menu_cursor == 1) { global.des_cursor = 0; global.estado = "desafio"; }
            else if (global.menu_cursor == 2) { global.modo = "normal"; vai_para(rm_criador, "lista_custom"); }
            else if (global.menu_cursor == 3) global.estado = "stats";
            else if (global.menu_cursor == 4) { global.cfg_cursor = 0; global.estado = "config"; }
            else { global.sair_confirma = true; global.sair_op = 1; }
        }
    }
    else if (tela == "config")
    {
        var c = global.cfg_cursor;
        if (_k == "up" || _k == "down")
        {
            global.cfg_cursor = (c + ((_k == "up") ? 6 : 1)) % 7;
            global.cfg_confirma = false;
        }
        else if ((_k == "left" || _k == "right") && c < 2)
        {
            var d = (_k == "left") ? -0.1 : 0.1;
            if (c == 0) global.config.musica = clamp(round((global.config.musica + d) * 10) / 10, 0, 1);
            else
            {
                global.config.sons = clamp(round((global.config.sons + d) * 10) / 10, 0, 1);
                toca_som("snd_estrela", 0.8);       // amostra do volume novo
            }
            grava_config();
        }
        else if ((_k == "left" || _k == "right" || _k == "ok") && c == 2)
        {
            global.config.tela = !global.config.tela;
            window_set_fullscreen(global.config.tela);
            if (!global.config.tela) aplica_resolucao();
            grava_config();
        }
        else if ((_k == "left" || _k == "right" || _k == "ok") && c == 3)
        {
            var nr = array_length(global.resolucoes);
            global.config.res = (global.config.res + ((_k == "left") ? nr - 1 : 1)) % nr;
            aplica_resolucao();
            grava_config();
        }
        else if ((_k == "left" || _k == "right" || _k == "ok") && c == 4)
        {
            global.config.flash = !global.config.flash;
            grava_config();
        }
        else if (_k == "ok" && c == 5)
        {
            if (global.cfg_confirma) { apaga_progresso(); global.cfg_confirma = false; mostra_aviso("Progresso apagado", 2.5); }
            else global.cfg_confirma = true;
        }
        else if ((_k == "ok" && c == 6) || _k == "esc") { grava_config(); global.cfg_confirma = false; if (global.volta_para_pausa) { global.volta_para_pausa = false; global.estado = "play"; global.pausa = true; } else global.estado = "title"; }
    }
    else if (tela == "desafio")
    {
        if (_k == "up") global.des_cursor = (global.des_cursor + 2) % 3;
        else if (_k == "down") global.des_cursor = (global.des_cursor + 1) % 3;
        else if (_k == "esc") global.estado = "title";
        else if (_k == "ok")
        {
            if (global.des_cursor == 0) inicia_fase(0, "challenge");
            else if (global.des_cursor == 1)
            {
                if (todas_fases_completas()) { global.rank_pos = -1; global.estado = "rank"; }
                else { mostra_aviso("Zere todas as fases para abrir o ranking", 2.5); toca_som("snd_pouso", 0.6, 0.7); }
            }
            else global.estado = "title";
        }
    }
    else if (tela == "rank")
    {
        if (_k == "ok" || _k == "esc") global.estado = "desafio";
    }
    else if (tela == "stats")
    {
        if (_k == "ok" || _k == "esc") global.estado = "title";
    }
    else if (tela == "worlds")
    {
        var n = array_length(global.mundos);
        // o rato precisa chegar no mundo antes de andar para outro
        if (global.mapa.anda && _k != "esc") return;
        // o mapa é um caminho: esquerda/cima voltam um mundo, direita/baixo avançam
        if (_k == "left" || _k == "up") global.mundo_cursor = max(0, global.mundo_cursor - 1);
        else if (_k == "right" || _k == "down") global.mundo_cursor = min(n - 1, global.mundo_cursor + 1);
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
        var nl = array_length(l);
        if (_k == "left") global.fase_cursor = max(0, global.fase_cursor - 1);
        else if (_k == "right") global.fase_cursor = min(nl - 1, global.fase_cursor + 1);
        else if (_k == "ok")
        {
            var fi = l[global.fase_cursor];
            if (fi <= fases_liberadas()) inicia_fase(fi, "normal");
        }
        else if (_k == "esc") global.estado = "worlds";
    }

    else if (tela == "clear")
    {
        if (global.tempo_tela > 0.5)
        {
            if (_k == "ok") proxima_fase();
            else if (_k == "r") { global.fase_nova = true; vai_para(-1, "play"); }
            else if (_k == "esc")
            {
                if (global.modo == "teste" || global.modo == "custom") { sai_custom(); return; }
                global.mundo_sel = global.info_fase.mundo;
                global.mundo_cursor = global.mundo_sel;
                global.fase_cursor = max(0, array_get_index(fases_do_mundo(global.mundo_sel), global.fase_atual));
                vai_para(rm_menu, "select");
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

prev_ult = -1;
prev_ini = 0;

desenha_menus = function()
{
    var tela = global.estado;
    var agora = global.tempo_jogo;
    if (tela == "title")
    {
        var tt = agora;
        // véu escuro na esquerda (volta ao tamanho menor)
        desenha_rect_alfa(0, 0, 220, VH, 0x05080f, 0.7);
        desenha_rect_alfa(220, 0, 16, VH, 0x05080f, 0.3);
        // --- lado direito: porta no chão, rato à direita da porta ---
        var dx = 232, dy = 150;              // porta 3x (24x28 -> 72x84); mais à esquerda para caber o rato à direita
        var rx = 370, ry = 234;              // rato: origem (10,20); pés em ry; ry=234 põe no chão
        desenha_rect_alfa(dx + 4, 232, 64, 4, 0x000000, 0.4);
        desenha_rect_alfa(rx - 26, 232, 52, 3, 0x000000, 0.35);
        for (var q = 0; q < 3; q++)
        {
            desenha_rect_alfa(dx + q * 6, 232 - q * 2, 72 - q * 12, 2, 0xffd890, 0.14);
        }
        desenha_brilho(dx + 36, dy + 46, 60, 0.28 + 0.06 * sin(tt * 2));
        draw_sprite_ext(spr_porta, 1, dx, dy, 3, 3, 0, c_white, 1);
        // rato olhando para a porta (escala x negativa)
        var passo = floor(tt * 7) % 4;
        draw_sprite_ext(spr_rato_andando, passo, rx, ry, -3, 3, 0, c_white, 1);
        // linhas de velocidade atrás do rato (à direita dele)
        for (var k = 0; k < 3; k++)
        {
            var lxs = rx + 32 + k * 10 - ((floor(tt * 12) + k) % 3) * 3;
            desenha_rect_alfa(lxs, 200 + k * 6, 12 - k * 2, 1, 0xdfe8ff, 0.5);
        }
        // chave dourada acima da porta
        var kx = dx + 20 + sin(tt * 1.6) * 3;
        var ky = 86 + cos(tt * 2.1) * 4;
        desenha_brilho(kx + 8, ky + 8, 22, 0.5);
        draw_sprite_ext(spr_chave, 0, kx, ky, 2, 2, sin(tt * 1.3) * 10 - 10, c_white, 1);
        desenha_estrela(kx - 8, ky + 24, false);
        desenha_estrela(kx + 36, ky + 2, false);
        // morcegos voando
        var mb = [[232, 36, 0.4], [300, 20, 0.55], [392, 60, 0.6], [232, 100, 0.45]];
        for (var b = 0; b < 4; b++)
        {
            var bx = mb[b][0] + sin(tt * mb[b][2]) * 6;
            var by = mb[b][1] + cos(tt * mb[b][2] * 1.3) * 4;
            var fase = floor(tt * 3 + b) % 2;
            desenha_morcego(bx, by, fase);
        }
        // logo: menor e bem à esquerda (dentro do véu escuro)
        var escala = 0.32;
        var lx = 2;
        var ly = 10;
        gpu_set_texfilter(true);
        draw_sprite_ext(spr_logo, 0, lx, ly + sin(tt * 1.5) * 1.2, escala, escala, 0, c_white, 1);
        gpu_set_texfilter(false);
        // menu
        var cur = global.menu_cursor;
        var itens = ["JOGAR", "MODO DESAFIO", "CRIAR FASES", "ESTATÍSTICAS", "CONFIGURAÇÕES", "SAIR"];
        desenha_menu_home(14, 88, 22, itens, cur);
        desenha_dicas(260, [["Setas", "escolher"], ["Enter", "confirmar"], ["Esc", "sair"]]);
        if (global.sair_confirma) desenha_popup_sair();
    }
    else if (tela == "stats")
    {
        desenha_stats();
    }
    else if (tela == "config")
    {
        desenha_fundo_menu_tela(0.74);
        desenha_titulo_faixa("CONFIGURAÇÕES", "Áudio, vídeo e progresso");
        var rot = ["Música", "Efeitos sonoros", "Tela cheia", "Resolução da janela", "Flashes de tela"];
        for (var k = 0; k < 5; k++)
        {
            var yy = 44 + k * 26;
            desenha_cartao(60, yy, 360, 22, global.cfg_cursor == k, false);
            desenha_texto(rot[k], 74, yy + 11, 0xf3efe6, "left", 11, 140);
            if (k < 2)
            {
                var v = (k == 0) ? global.config.musica : global.config.sons;
                desenha_slider(222, yy + 7, v, (k == 0) ? 0xb070ff : 0xffd84a);
                desenha_texto(string(round(v * 100)) + "%", 410, yy + 11, 0xa9b4c4, "right", 9);
            }
            else if (k == 3)
            {
                var rr = global.resolucoes[global.config.res];
                desenha_texto(string(rr[0]) + " x " + string(rr[1]), 410, yy + 11, global.config.tela ? 0x7d8798 : 0xffd84a, "right", 11, 130);
            }
            else
            {
                var on = (k == 2) ? global.config.tela : global.config.flash;
                desenha_texto(on ? "LIGADO" : "DESLIGADO", 410, yy + 11, on ? 0x4ade80 : 0x7d8798, "right", 11);
            }
        }
        // ações finais: mesmo estilo do menu principal (losango dourado + sublinhado)
        var acoes = [global.cfg_confirma ? "CONFIRMAR? (ENTER)" : "APAGAR PROGRESSO", "VOLTAR"];
        desenha_menu_home(VW / 2 - 80, 188, 24, acoes, global.cfg_cursor - 5);
        desenha_dicas(254, [["Setas", "escolher e ajustar"], ["Enter", "alternar"], ["Esc", "voltar"]]);
    }
    else if (tela == "desafio")
    {
        desenha_fundo_menu_tela(0.7);
        desenha_titulo_faixa("MODO DESAFIO", "Zere todas as fases em sequência");
        // cena à direita: rato correndo, chave brilhando
        desenha_rect_alfa(350, 232, 60, 3, 0x000000, 0.35);
        desenha_brilho(380, 190, 70, 0.28 + 0.05 * sin(agora * 2));
        draw_sprite_ext(spr_rato_andando, floor(agora * 7) % 4, 380, 234, 3, 3, 0, c_white, 1);
        draw_sprite_ext(spr_chave, 0, 320, 90 + cos(agora * 2.1) * 4, 2, 2, sin(agora * 1.3) * 10 - 10, c_white, 1);
        // informação à esquerda
        var melhor = (global.save.desafio_tempo >= 0) ? formata_tempo(global.save.desafio_tempo) + "  (" + string(global.save.desafio_mortes) + " mortes)" : "ainda sem recorde";
        desenha_texto("O tempo não para e cada morte conta.", 22, 68, 0xc8d3ea, "left", 10, 240);
        desenha_texto("Seu melhor:", 22, 88, 0xa9b4c4, "left", 9, 240);
        desenha_texto(melhor, 22, 98, 0xffd84a, "left", 11, 240);
        desenha_texto("Corridas no ranking: " + string(array_length(global.rank)) + " / " + string(RANK_MAX), 22, 118, 0x9aa7bd, "left", 8, 240);
        // menu de ações, estilo home
        var acoes = ["INICIAR DESAFIO", (todas_fases_completas() ? "RANKING" : "~RANKING"), "VOLTAR"];
        desenha_menu_home(22, 148, 22, acoes, global.des_cursor);
        if (!todas_fases_completas()) desenha_texto("Zere todas as fases para abrir o ranking", 22, 226, 0x9aa7c0, "left", 8, 240);
        desenha_dicas(256, [["Setas", "escolher"], ["Enter", "confirmar"], ["Esc", "voltar"]]);
    }
    else if (tela == "rank")
    {
        desenha_fundo_menu_tela(0.8);
        desenha_titulo_faixa("RANKING", "Melhores corridas do modo desafio");
        desenha_texto("TEMPO", 140, 52, 0x9aa7bd, "left", 8);
        desenha_texto("MORTES", 270, 52, 0x9aa7bd, "left", 8);
        desenha_texto("DATA", 408, 52, 0x9aa7bd, "right", 8);
        for (var k = 0; k < RANK_MAX; k++)
        {
            var yy = 62 + k * 18;
            var meu = (k == global.rank_pos);
            var tem = (k < array_length(global.rank));
            desenha_linha_rank(70, yy, 350, 16, k, meu);
            var cor = meu ? 0x3a2600 : (tem ? 0xf3efe6 : 0x6c7790);
            if (tem)
            {
                desenha_texto(formata_tempo(global.rank[k].tempo), 140, yy + 8.5, cor, "left", 10);
                desenha_texto(string(global.rank[k].mortes), 270, yy + 8.5, cor, "left", 10);
                desenha_texto(global.rank[k].data, 408, yy + 8.5, cor, "right", 8);
            }
            else desenha_texto("---", 140, yy + 8.5, cor, "left", 10);
        }
        desenha_texto("Ranking local. O ranking online (Steam) vem depois.", VW / 2, 247, 0x9aa7bd, "center", 8);
        desenha_dicas(262, [["Enter", "voltar"]]);
    }
    else if (tela == "worlds")
    {
        var nm = array_length(global.mundos);
        desenha_fundo_menu_tela(0.72);
        desenha_titulo_faixa("MUNDOS", "Escolha uma ala da prisão");

        // --- lista de mundos à esquerda, estilo da home ---
        var rot = array_create(nm);
        for (var k = 0; k < nm; k++)
            rot[k] = (!mundo_liberado(k) ? "~" : "") + string(k + 1) + ". " + global.mundos[k].n;
        desenha_menu_home(14, 72, 22, rot, global.mundo_cursor);

        // --- detalhe do mundo escolhido à direita ---
        var kc = global.mundo_cursor;
        var liberado = mundo_liberado(kc);
        var mc = global.mundos[kc];
        var nf = array_length(fases_do_mundo(kc));
        var feitas = mundo_feitas(kc);
        var estrelas = mundo_estrelas(kc);
        var est_max = nf * 3;
        var qmax = mundo_queijos_max(kc);
        var queijos = mundo_queijos(kc);

        // painel escuro de detalhe, borda dourada fininha
        var dx = 232, dy = 62, dw = 236, dh = 180;
        desenha_rect_alfa(dx, dy, dw, dh, 0x0a0e1a, 0.86);
        desenha_rect(dx, dy, dw, 1, 0xffd84a);
        desenha_rect(dx, dy + dh - 1, dw, 1, 0xffd84a);
        desenha_rect(dx, dy, 1, dh, 0xffd84a);
        desenha_rect(dx + dw - 1, dy, 1, dh, 0xffd84a);
        desenha_rect_alfa(dx + 1, dy + 1, dw - 2, 1, 0xffffff, 0.22);

        if (liberado)
        {
            desenha_texto("MUNDO " + string(kc + 1), dx + 12, dy + 16, 0x9aa7bd, "left", 9, dw - 24);
            desenha_texto(mc.n, dx + 12, dy + 34, 0xffd84a, "left", 16, dw - 24);
            desenha_texto(mc.d, dx + 12, dy + 56, 0xc8d3ea, "left", 9, dw - 24);
            // linhas de progresso
            desenha_texto("Fases concluídas", dx + 12, dy + 86, 0xa9b4c4, "left", 9, dw - 24);
            desenha_texto(string(feitas) + " / " + string(nf), dx + dw - 12, dy + 86, 0xf3efe6, "right", 11, 80);
            desenha_rect(dx + 12, dy + 100, dw - 24, 3, 0x0a0a16);
            desenha_rect(dx + 12, dy + 100, floor((dw - 24) * feitas / max(1, nf)), 3, 0x4ade80);

            desenha_texto("Estrelas", dx + 12, dy + 114, 0xa9b4c4, "left", 9, dw - 24);
            desenha_texto(string(estrelas) + " / " + string(est_max), dx + dw - 12, dy + 114, 0xf3efe6, "right", 11, 80);
            desenha_rect(dx + 12, dy + 128, dw - 24, 3, 0x0a0a16);
            desenha_rect(dx + 12, dy + 128, floor((dw - 24) * estrelas / max(1, est_max)), 3, 0xffd84a);

            desenha_texto("Queijos", dx + 12, dy + 142, 0xa9b4c4, "left", 9, dw - 24);
            desenha_texto(string(queijos) + " / " + string(qmax), dx + dw - 12, dy + 142, 0xf3efe6, "right", 11, 80);
            desenha_rect(dx + 12, dy + 156, dw - 24, 3, 0x0a0a16);
            desenha_rect(dx + 12, dy + 156, floor((dw - 24) * queijos / max(1, qmax)), 3, 0xf5a623);
        }
        else
        {
            desenha_texto("BLOQUEADO", dx + 12, dy + 16, 0x9aa7bd, "left", 9, dw - 24);
            desenha_texto("Mundo " + string(kc + 1), dx + 12, dy + 34, 0x7d8798, "left", 16, dw - 24);
            desenha_cadeado(dx + dw / 2, dy + dh / 2 - 6, 0x7d8798);
            desenha_texto("Conclua o mundo anterior para abrir.", dx + 12, dy + dh / 2 + 24, 0xa9b4c4, "center", 9, dw - 24);
        }

        desenha_dicas(262, [["Setas", "escolher"], ["Enter", "entrar"], ["Esc", "voltar"]]);
    }

    else if (tela == "select")
    {
        var l = fases_do_mundo(global.mundo_sel);
        var nl = array_length(l);
        // fundo da cela (spr_mapa agora é o mesmo fundo do menu) + véu escuro
        draw_sprite(spr_mapa, 1 + (global.mundo_sel % 5), 0, 0);
        desenha_rect_alfa(0, 0, VW, VH, 0x05080f, 0.74);
        var fi = l[global.fase_cursor];
        if (prev_ult != fi) { prev_ult = fi; prev_ini = agora; }
        var lockf = (fi > fases_liberadas());
        // título em faixa dourada com o nome do mundo
        desenha_titulo_faixa(global.mundos[global.mundo_sel].n, "Escolha a fase");
        // fileira de ícones no alto (abaixados para caber a faixa)
        var passo = 32;
        for (var n = 0; n < nl; n++)
        {
            var idx = l[n];
            var lock = (idx > fases_liberadas());
            var est = lock ? 0 : (global.save.feita[idx] ? 2 : 1);
            var sv = global.save.estrelas[idx];
            desenha_icone_fase(VW / 2 + (n - (nl - 1) / 2) * passo, 56, idx + 1, est, n == global.fase_cursor, sv[0] + sv[1] + sv[2]);
        }
        desenha_previa_fase(fi, lockf, clamp((agora - prev_ini) / 0.18, 0, 1));
        // setas laterais douradas
        var pul = sin(agora * 6) * 1.5;
        var ca = (global.fase_cursor > 0) ? 0xffd84a : 0x3a4252, cb = (global.fase_cursor < nl - 1) ? 0xffd84a : 0x3a4252;
        draw_set_colour(cor_rgb(ca)); draw_triangle(66 - pul, 150, 74 - pul, 142, 74 - pul, 158, false);
        draw_set_colour(cor_rgb(cb)); draw_triangle(414 + pul, 150, 406 + pul, 142, 406 + pul, 158, false);
        draw_set_colour(c_white);
        // barra de rodapé plana com linha dourada (mesmo clima do menu principal)
        var Lf = global.fases[fi];
        desenha_rect_alfa(0, 226, VW, 30, 0x0a0e1a, 0.92);
        desenha_rect(0, 224, VW, 2, 0xffd84a);
        desenha_texto("Fase " + string(fi + 1) + " · " + (lockf ? "???" : Lf.nome), 10, 236, 0xffd84a, "left", 12);
        desenha_texto("Mundo " + string(global.mundo_sel + 1) + " · " + global.mundos[global.mundo_sel].n + "   " + string(round(100 * mundo_feitas(global.mundo_sel) / nl)) + "%", 10, 248, 0x9aa7bd, "left", 8);
        if (!lockf)
        {
            var sv2 = global.save.estrelas[fi];
            for (var q = 0; q < 3; q++) desenha_estrela(VW - 66 + q * 12, 236, sv2[q] == 1);
            desenha_texto("Par " + string(Lf.tempo_par) + "s" + ((Lf.tem_queijo > 0) ? "   queijo " + (global.save.queijo[fi] ? "sim" : "não") : ""), VW - 10, 248, 0x9aa7bd, "right", 8);
        }
        desenha_dicas(262, [["Setas", "escolher"], ["Enter", "jogar"], ["Esc", "mapa"]]);
    }

    // fase concluída no modo normal: tela no estilo Alien Escape (scr_desenho.desenha_tela_vitoria)
    else if (tela == "clear" && global.modo == "normal") desenha_tela_vitoria();
    else if (tela == "clear")
    {
        var L = global.info_fase;
        desenha_rect_alfa(0, 0, VW, VH, 0x03060b, 0.72);
        desenha_cartao(70, 26, 340, 232, false, false);
        desenha_titulo_secao("SALA CONCLUÍDA!", 50, 24);
        titulo(L.nome, 80, 0xa9b4c4, 11);
        if (global.modo == "teste" || global.modo == "custom")
        {
            if (global.modo == "teste")
            {
                var valida = (global.ed != undefined && global.ed.validada);
                var sem_queijo = (global.queijo_fase == 0);
                titulo(valida ? "FASE VALIDADA!" : (sem_queijo ? "Fase NÃO validada (faltou o queijo)" : "Fase NÃO validada (cheats usados)"), 124, valida ? 0x4ade80 : 0xff6b5e, 16);
                titulo(valida ? "Agora você pode salvar e compartilhar esta fase." : (sem_queijo ? "Pegue o queijo e chegue à porta para validar." : "Zere a fase sem cheats para poder salvar."), 148, 0xa9b4c4, 11);
            }
            else titulo("Fase do jogador", 130, 0xa9b4c4, 14);
            titulo("Tempo: " + string_format(global.tempo_fase, 1, 1) + "s  ·  Mortes na sala: " + string(global.mortes_fase), 190, 0xa9b4c4, 10);
            if (global.tempo_tela > 0.5) desenha_dicas(242, [["Enter", (global.modo == "teste") ? "voltar ao editor" : "voltar à lista"], ["R", "repetir"]]);
        }
        else if (global.modo == "normal")
        {
            var metas = objetivos(L);
            for (var k = 0; k < 3; k++)
            {
                desenha_painel(128, 107 + k * 26, 224, 22, global.estrelas_fase[k] ? 0.85 : 0.5, global.estrelas_fase[k] ? 0xb8962f : 0x2d3c56);
                desenha_estrela(142, 118 + k * 26, global.estrelas_fase[k]);
                desenha_texto(metas[k], 160, 118 + k * 26, global.estrelas_fase[k] ? 0xf3efe6 : 0x7d8798, "left", 11);
            }
            if (global.queijo_fase >= 0)
            {
                desenha_painel(128, 183, 224, 22, (global.queijo_fase == 1) ? 0.85 : 0.5, (global.queijo_fase == 1) ? 0xb8962f : 0x2d3c56);
                desenha_icone_queijo(142, 194, global.queijo_fase == 1);
                desenha_texto((global.queijo_fase == 1) ? "Queijo coletado!" : "Queijo não coletado", 160, 194, (global.queijo_fase == 1) ? 0xffd23f : 0x7d8798, "left", 11);
            }
            titulo("Tempo: " + string_format(global.tempo_fase, 1, 1) + "s  ·  Mortes na sala: " + string(global.mortes_fase), 216, 0xa9b4c4, 10);
            if (global.cheat) titulo("Cheats ligados: progresso não é salvo", 229, 0xffd84a, 9);
            if (global.tempo_tela > 0.5)
            {
                var fim = (global.fase_atual + 1 >= array_length(global.fases) || global.fase_atual == global.fase_final);
                desenha_dicas(242, [["Enter", fim ? "continuar" : "próxima"], ["R", "repetir"], ["Esc", "salas"]]);
            }
        }
        else titulo("Total: " + formata_tempo(global.tempo_total) + "  ·  Mortes: " + string(global.mortes), 130, 0xf3efe6, 14);
    }
    else if (tela == "win")
    {
        desenha_fundo_tela(2);
        desenha_cartao(60, 28, 360, 216, false, false);
        desenha_titulo_secao("VOCÊ ESCAPOU!", 62, 28);
        if (global.modo == "challenge")
        {
            titulo("Tempo total: " + formata_tempo(global.tempo_total), 112, 0xf3efe6, 16);
            titulo("Mortes: " + string(global.mortes), 138, 0xf3efe6, 14);
            if (global.rank_pos >= 0) titulo("Ranking: #" + string(global.rank_pos + 1), 192, 0xffd84a, 12);
            if (global.novo_recorde) titulo("NOVO RECORDE!", 166, 0x4ade80, 12);
            else titulo("Recorde: " + ((global.save.desafio_tempo >= 0) ? formata_tempo(global.save.desafio_tempo) + " (" + string(global.save.desafio_mortes) + " mortes)" : "-"), 166, 0xa9b4c4, 12);
        }
        else
        {
            titulo("Estrelas: " + string(total_estrelas()) + "/" + string(array_length(global.fases) * 3), 112, 0xf3efe6, 16);
            titulo("Queijos: " + string(total_queijos()) + "/" + string(total_queijos_max()), 138, 0xffd23f, 14);
            titulo((global.fase_atual == global.fase_final) ? "Mundo novo desbloqueado: COFRE (lasers e blocos de cor)" : "Tente pegar todas as estrelas e queijos", 166, 0xa9b4c4, 11);
        }
        if (global.tempo_tela > 0.8) desenha_dicas(226, [["Enter", "voltar ao menu"]]);
    }
}


// tela de estatísticas: progresso do jogo e números gerais
desenha_stats = function()
{
    desenha_fundo_menu_tela(0.72);
    desenha_titulo_faixa("ESTATÍSTICAS", "Seu progresso na prisão");
    var nfases = array_length(global.fases);
    var feitas = total_feitas();
    var estrelas = total_estrelas();
    var queijos = total_queijos();

    // coluna da esquerda: progresso, com barra
    var linhas_esq = [
        {t: "Fases concluídas", v: string(feitas) + " / " + string(nfases), f: feitas / nfases, c: 0x4ade80},
        {t: "Estrelas", v: string(estrelas) + " / " + string(nfases * 3), f: estrelas / (nfases * 3), c: 0xffd23f},
        {t: "Queijos", v: string(queijos) + " / " + string(total_queijos_max()), f: queijos / max(1, total_queijos_max()), c: 0xf5a623},
        {t: "Fases com 3 estrelas", v: string(total_perfeitas()) + " / " + string(nfases), f: total_perfeitas() / nfases, c: 0x7cc4ff}
    ];
    for (var k = 0; k < array_length(linhas_esq); k++)
    {
        var l = linhas_esq[k];
        var yy = 56 + k * 32;
        desenha_cartao(30, yy, 200, 28, false, false);
        desenha_texto(l.t, 42, yy + 9, 0xc4cee0, "left", 9, 100);
        desenha_texto(l.v, 218, yy + 9, 0xffffff, "right", 11, 90);
        desenha_barra(42, yy + 20, 176, 3, l.f, l.c);
    }

    // coluna da direita: números gerais
    var melhor = (global.save.desafio_tempo >= 0) ? formata_tempo(global.save.desafio_tempo) + " (" + string(global.save.desafio_mortes) + " mortes)" : "-";
    var linhas_dir = [
        {t: "Tempo jogado", v: formata_duracao(global.stats.tempo)},
        {t: "Mortes", v: string(global.stats.mortes)},
        {t: "Vezes que passou de fase", v: string(global.stats.conclusoes)},
        {t: "Fases criadas por você", v: string(global.stats.fases_criadas)},
    ];
    for (var k = 0; k < array_length(linhas_dir); k++)
    {
        var l = linhas_dir[k];
        var yy = 56 + k * 32;
        desenha_cartao(250, yy, 200, 28, false, false);
        desenha_texto(l.t, 264, yy + 14, 0xc4cee0, "left", 9, 120);
        desenha_texto(l.v, 438, yy + 14, 0xffffff, "right", 11, 80);
    }
    desenha_cartao(30, 188, 420, 22, true, false);
    desenha_texto("Melhor modo desafio", 50, 199, 0xc4cee0, "left", 9, 150);
    desenha_texto(melhor, 430, 199, 0xffd84a, "right", 11, 240);

    // estrelas por mundo
    var n = array_length(global.mundos);
    var larg = floor(420 / n);
    for (var w = 0; w < n; w++)
    {
        var xx = 30 + w * larg;
        desenha_cartao(xx + 1, 214, larg - 2, 30, false, false);
        var maximo = array_length(fases_do_mundo(w)) * 3;
        desenha_texto(global.mundos[w].n, xx + larg / 2, 223, 0xf3efe6, "center", 8, larg - 18);
        desenha_barra(xx + 10, 231, larg - 20, 3, mundo_estrelas(w) / max(1, maximo), 0xffd23f);
        desenha_texto(string(mundo_feitas(w)) + "/" + string(array_length(fases_do_mundo(w))) + " fases", xx + larg / 2, 239, 0x9aa7bd, "center", 7, larg - 18);
    }
    desenha_dicas(262, [["Enter", "voltar"], ["Esc", "voltar"]]);
}

desenha_hud = function()
{
    // HUD removida a pedido: nada de MORTES/tempo, FASE, alarme, ícones
    // (chave/queijo/cor) nem popups de aviso durante o jogo.
    // Apenas a linha de cheats fica, como ferramenta de debug interna.
    if (global.cheat)
    {
        desenha_texto("CHEATS" + (global.invencivel ? " · INVENCIVEL" : "") + "   N/B: fase · I: invencivel · Y: chave · U: concluir", 6, VH - 7, 0xffd84a, "left", 8);
    }
    // silencia qualquer aviso que ainda esteja em contagem
    if (global.aviso_tempo > 0) global.aviso_tempo = 0;
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

// transição de tela em persianas: fecha (0.45 s), troca de room, abre (0.5 s)
atualiza_transicao = function()
{
    var tr = global.trans;
    if (tr.fase == "sai")
    {
        tr.t = min(1, tr.t + DT / 0.45);
        if (tr.t >= 1)
        {
            tr.fase = "espera";
            tr.origem = room;
            if (tr.estado != undefined) global.estado = tr.estado;
            if (tr.destino == -1) room_restart(); else room_goto(tr.destino);
        }
    }
    else if (tr.fase == "espera")
    {
        // garantia: se a room mudou e o Room Start não clareou, clareia aqui
        if (room != tr.origem) { tr.fase = "entra"; tr.t = 1; }
    }
    else if (tr.fase == "entra")
    {
        tr.t = max(0, tr.t - DT / 0.5);
        if (tr.t <= 0) tr.fase = "off";
    }
}

// o rato do mapa anda até o nó escolhido (na troca de tela ele já nasce no nó)
atualiza_mapa = function()
{
    var tela = global.estado;
    global.mapa.anda = false;
    return;
    if (tela != "worlds") { global.mapa.estado = ""; return; }
    var alvo;
    alvo = pos_no_mapa(global.mundo_cursor, array_length(global.mundos));
    var oy = -30;
    var m = global.mapa;
    if (m.estado != tela) { m.estado = tela; m.rx = alvo[0]; m.ry = alvo[1] + oy; m.anda = false; return; }
    var dx = alvo[0] - m.rx, dy = (alvo[1] + oy) - m.ry;
    var d = point_distance(0, 0, dx, dy);
    if (d < 2.5) { m.rx = alvo[0]; m.ry = alvo[1] + oy; m.anda = false; return; }
    var v = min(d, 150 * DT);
    m.rx += dx / d * v;
    m.ry += dy / d * v;
    m.anda = true;
    if (abs(dx) > 1) m.face = sign(dx);
}

// partículas: faíscas que os outros objetos criam com faiscas()
atualiza_particulas = function()
{
    var vivas = [];
    for (var q = 0; q < array_length(global.particulas); q++)
    {
        var fagulha = global.particulas[q];
        fagulha.l -= DT;
        fagulha.vy += fagulha.g * DT;
        fagulha.x += fagulha.vx * DT;
        fagulha.y += fagulha.vy * DT;
        if (fagulha.l > 0) array_push(vivas, fagulha);
    }
    global.particulas = vivas;
}

#endregion
