// ===== Menus, telas e cheats =====
// Controles dos menus: setas/WASD movem, Enter/Espaço/E confirmam, Esc volta.

function celula_fase(_n)
{
    return [25 + (_n % 4) * 110, 74 + floor(_n / 4) * 92];
}

function celula_mundo(_n)
{
    return [28 + (_n % 2) * 226, 40 + floor(_n / 2) * 74];
}

function moldura(_x, _y, _w, _h)
{
    rc(_x - 2, _y - 2, _w + 4, 2, 0xffd84a);
    rc(_x - 2, _y + _h, _w + 4, 2, 0xffd84a);
    rc(_x - 2, _y, 2, _h, 0xffd84a);
    rc(_x + _w, _y, 2, _h, 0xffd84a);
}

function titulo(_s, _y, _c, _z)
{
    tx(_s, VW / 2, _y, _c, "center", _z);
}

// objetivos das 3 estrelas (texto)
function objetivos(_L)
{
    var t3 = "";
    if (_L.o3 == "cabo") t3 = "Sem roer cabos";
    else if (_L.o3 == "chave") t3 = "Sem soltar a chave";
    else t3 = "Em até " + string(round(_L.par * 0.65)) + "s";
    return ["Sem morrer", "Em até " + string(_L.par) + "s", t3];
}

// _k: "up" "down" "left" "right" "ok" "esc" "r"
function ui_tecla(_k)
{
    var st = global.st;
    if (st == "title")
    {
        if (_k == "up" || _k == "down") global.mi = 1 - global.mi;
        else if (_k == "ok")
        {
            if (global.mi == 0) global.st = "worlds";
            else inicia_nivel(0, "challenge");
        }
    }
    else if (st == "worlds")
    {
        var n = array_length(global.mundos);
        if (_k == "left") global.ws = max(0, global.ws - 1);
        else if (_k == "right") global.ws = min(n - 1, global.ws + 1);
        else if (_k == "up") global.ws = max(0, global.ws - 2);
        else if (_k == "down") global.ws = min(n - 1, global.ws + 2);
        else if (_k == "ok")
        {
            if (mundo_desbloqueado(global.ws))
            {
                global.wsel = global.ws;
                var l = mundo_fases(global.ws);
                var k = -1;
                for (var i = 0; i < array_length(l); i++)
                {
                    var a = global.SV.stars[l[i]];
                    if (k < 0 && a[0] + a[1] + a[2] == 0) k = i;
                }
                var liberadas = 0;
                for (var i = 0; i < array_length(l); i++) { if (l[i] <= unl_efetivo()) liberadas++; }
                global.si = max(0, min((k < 0) ? 0 : k, liberadas - 1));
                global.st = "select";
            }
        }
        else if (_k == "esc") global.st = "title";
    }
    else if (st == "select")
    {
        var l = mundo_fases(global.wsel);
        if (_k == "left") global.si = max(0, global.si - 1);
        else if (_k == "right") global.si = min(array_length(l) - 1, global.si + 1);
        else if (_k == "up" && global.si >= 4) global.si -= 4;
        else if (_k == "down" && global.si + 4 < array_length(l)) global.si += 4;
        else if (_k == "ok")
        {
            if (l[global.si] <= unl_efetivo()) inicia_nivel(l[global.si], "normal");
        }
        else if (_k == "esc") global.st = "worlds";
    }
    else if (st == "play")
    {
        if (_k == "r") carrega_fase(global.lvl, true);
        else if (_k == "esc")
        {
            if (global.mode == "challenge") global.st = "title";
            else
            {
                global.wsel = global.LV[global.lvl].mundo;
                global.ws = global.wsel;
                global.si = max(0, array_get_index(mundo_fases(global.wsel), global.lvl));
                global.st = "select";
            }
        }
    }
    else if (st == "clear")
    {
        if (global.ct > 0.5)
        {
            if (_k == "ok") proximo_nivel();
            else if (_k == "r") { carrega_fase(global.lvl, false); global.st = "play"; }
            else if (_k == "esc")
            {
                global.wsel = global.LV[global.lvl].mundo;
                global.ws = global.wsel;
                global.si = max(0, array_get_index(mundo_fases(global.wsel), global.lvl));
                global.st = "select";
            }
        }
    }
    else if (st == "win")
    {
        if (global.ct > 0.8 && (_k == "ok" || _k == "esc")) global.st = "title";
    }
}

// ----- cheats: F1 liga/desliga; depois N/B (fase), I (invencível), Y (chave), U (concluir) -----
function cheat_alterna()
{
    global.cheat = !global.cheat;
    if (!global.cheat) global.inv = false;
    toast(global.cheat ? "Cheats ligados (progresso não é salvo)" : "Cheats desligados", 2.5);
}

function cheat_faz(_a)
{
    if (!global.cheat) return;
    var p = global.jog;
    if (_a == "inv")
    {
        global.inv = !global.inv;
        toast(global.inv ? "Invencível ligado" : "Invencível desligado", 2);
        return;
    }
    if (_a == "key")
    {
        if (global.st == "play" && !global.hasKey && global.key != undefined && !p.morto)
        {
            global.key.st = "carried"; global.hasKey = true; global.key.t = 0;
            toast("Chave na boca (cheat)", 2);
        }
        return;
    }
    if (_a == "win")
    {
        if (global.st == "play" && !p.morto) nivel_concluido();
        return;
    }
    var jogando = (global.st == "play" || global.st == "clear");
    var base = 0;
    if (jogando) base = global.lvl;
    else if (global.st == "select") base = mundo_fases(global.wsel)[global.si];
    var d = (_a == "next") ? 1 : -1;
    var alvo = base;
    if (jogando) alvo = max(0, min(array_length(global.LV) - 1, base + d));
    inicia_nivel(alvo, "normal");
}

// lê o teclado e chama o menu/cheat (obj_game chama isso todo quadro)
function ui_le_teclado()
{
    if (keyboard_check_pressed(vk_f1)) cheat_alterna();
    if (global.cheat)
    {
        if (keyboard_check_pressed(ord("N"))) { cheat_faz("next"); return; }
        if (keyboard_check_pressed(ord("B"))) { cheat_faz("prev"); return; }
        if (keyboard_check_pressed(ord("I"))) { cheat_faz("inv"); return; }
        if (keyboard_check_pressed(ord("Y"))) { cheat_faz("key"); return; }
        if (keyboard_check_pressed(ord("U"))) { cheat_faz("win"); return; }
    }
    if (keyboard_check_pressed(vk_up) || keyboard_check_pressed(ord("W"))) ui_tecla("up");
    if (keyboard_check_pressed(vk_down) || keyboard_check_pressed(ord("S"))) ui_tecla("down");
    if (keyboard_check_pressed(vk_left) || keyboard_check_pressed(ord("A"))) ui_tecla("left");
    if (keyboard_check_pressed(vk_right) || keyboard_check_pressed(ord("D"))) ui_tecla("right");
    if (keyboard_check_pressed(vk_enter) || keyboard_check_pressed(vk_space) || keyboard_check_pressed(ord("E"))) ui_tecla("ok");
    if (keyboard_check_pressed(vk_escape)) ui_tecla("esc");
    if (keyboard_check_pressed(ord("R"))) ui_tecla("r");
}

// ----- telas -----
function desenha_ui()
{
    var st = global.st;
    var T0 = global.T0;
    if (st == "title")
    {
        rca(0, 0, VW, VH, 0x05080e, 0.72);
        titulo("RATLOCK", 64, 0xffd84a, 40);
        titulo("Fuja da prisão: pegue a chave e abra a porta", 98, 0xa9b4c4, 11);
        var op = ["JOGAR", "MODO DESAFIO"];
        for (var k = 0; k < 2; k++)
            titulo(((global.mi == k) ? "> " : "  ") + op[k] + ((global.mi == k) ? " <" : "  "), 150 + k * 30, (global.mi == k) ? 0xffd84a : 0xf3efe6, 16);
        var extra = "Estrelas: " + string(total_estrelas()) + "/" + string(array_length(global.LV) * 3) + "  ·  Queijos: " + string(total_queijos()) + "/" + string(total_queijos_max());
        if (global.SV.ch_t >= 0) extra += "  ·  Melhor desafio: " + fmt_tempo(global.SV.ch_t) + " (" + string(global.SV.ch_d) + " mortes)";
        titulo(extra, 212, 0xa9b4c4, 10);
        titulo("Setas + Enter  ·  F1: cheats " + (global.cheat ? "ligados" : "desligados"), 238, 0x7d8798, 10);
    }
    else if (st == "worlds")
    {
        rca(0, 0, VW, VH, 0x05080e, 0.9);
        titulo("MUNDOS", 20, 0xffd84a, 18);
        for (var k = 0; k < array_length(global.mundos); k++)
        {
            var c = celula_mundo(k), x = c[0], y = c[1];
            var lock = !mundo_desbloqueado(k);
            var l = mundo_fases(k);
            rc(x, y, 214, 66, lock ? 0x10141b : 0x1b2433);
            if (k == global.ws) moldura(x, y, 214, 66);
            tx("MUNDO " + string(k + 1), x + 10, y + 11, lock ? 0x4a5568 : 0x7d8798, "left", 9);
            tx(lock ? "Bloqueado" : global.mundos[k].n, x + 10, y + 27, lock ? 0x4a5568 : 0xf3efe6, "left", 15);
            tx(lock ? "Conclua o mundo anterior" : global.mundos[k].d, x + 10, y + 41, lock ? 0x4a5568 : 0xa9b4c4, "left", 8);
            if (!lock)
            {
                estrela(x + 16, y + 55, 5, true);
                tx(string(mundo_estrelas(k)) + "/" + string(array_length(l) * 3), x + 26, y + 55, 0xffd23f, "left", 9);
                icone_queijo(x + 90, y + 55, true);
                tx(string(mundo_queijos(k)) + "/" + string(mundo_queijos_max(k)), x + 100, y + 55, 0xffd23f, "left", 9);
            }
        }
        titulo("Enter: abrir  ·  Esc: voltar", 264, 0x7d8798, 9);
    }
    else if (st == "select")
    {
        rca(0, 0, VW, VH, 0x05080e, 0.9);
        titulo("MUNDO " + string(global.wsel + 1) + " · " + string_upper(global.mundos[global.wsel].n), 32, 0xffd84a, 18);
        var l = mundo_fases(global.wsel);
        for (var n = 0; n < array_length(l); n++)
        {
            var idx = l[n];
            var L = global.LV[idx];
            var c = celula_fase(n), x = c[0], y = c[1];
            var lock = (idx > unl_efetivo());
            rc(x, y, 100, 82, lock ? 0x10141b : 0x1b2433);
            if (n == global.si) moldura(x, y, 100, 82);
            tx(lock ? "--" : string(idx + 1), x + 50, y + 16, lock ? 0x4a5568 : 0xf3efe6, "center", 16);
            tx(lock ? "bloqueada" : L.nome, x + 50, y + 38, lock ? 0x4a5568 : 0xa9b4c4, "center", 8);
            var sv = global.SV.stars[idx];
            for (var q = 0; q < 3; q++) estrela(x + 50 - 20 + q * 20, y + 82 - 16, 7, !lock && sv[q] == 1);
            if (L.cs > 0 && !lock) icone_queijo(x + 100 - 13, y + 13, global.SV.cheese[idx] == 1);
        }
        titulo("Enter: jogar  ·  Esc: mundos", 262, 0x7d8798, 9);
    }
    else if (st == "clear")
    {
        var L = global.LV[global.lvl];
        rca(0, 0, VW, VH, 0x05080e, 0.68);
        titulo("SALA CONCLUÍDA!", 52, 0xffd84a, 26);
        titulo(L.nome, 80, 0xa9b4c4, 11);
        if (global.mode == "normal")
        {
            var ob = objetivos(L);
            for (var k = 0; k < 3; k++)
            {
                estrela(142, 118 + k * 26, 9, global.res[k]);
                tx(ob[k], 162, 118 + k * 26, global.res[k] ? 0xf3efe6 : 0x7d8798, "left", 12);
            }
            if (global.cz >= 0)
            {
                icone_queijo(142, 194, global.cz == 1);
                tx((global.cz == 1) ? "Queijo coletado!" : "Queijo não coletado", 162, 194, (global.cz == 1) ? 0xffd23f : 0x7d8798, "left", 12);
            }
            titulo("Tempo: " + string_format(global.lvTime, 1, 1) + "s  ·  Mortes na sala: " + string(global.lvDeaths), 216, 0xa9b4c4, 10);
            if (global.cheat) titulo("Cheats ligados: progresso não é salvo", 229, 0xffd84a, 9);
            if (global.ct > 0.5)
            {
                var fim = (global.lvl + 1 >= array_length(global.LV) || global.lvl == global.FIN);
                titulo("Enter: " + (fim ? "continuar" : "próxima") + "  ·  R: repetir  ·  Esc: salas", 242, 0x7d8798, 10);
            }
        }
        else titulo("Total: " + fmt_tempo(global.gTime) + "  ·  Mortes: " + string(global.deaths), 130, 0xf3efe6, 14);
    }
    else if (st == "win")
    {
        rca(0, 0, VW, VH, 0x05080e, 0.86);
        titulo("VOCÊ ESCAPOU!", 60, 0xffd84a, 30);
        if (global.mode == "challenge")
        {
            titulo("Tempo total: " + fmt_tempo(global.gTime), 112, 0xf3efe6, 16);
            titulo("Mortes: " + string(global.deaths), 138, 0xf3efe6, 14);
            if (global.newBest) titulo("NOVO RECORDE!", 166, 0x4ade80, 12);
            else titulo("Recorde: " + ((global.SV.ch_t >= 0) ? fmt_tempo(global.SV.ch_t) + " (" + string(global.SV.ch_d) + " mortes)" : "-"), 166, 0xa9b4c4, 12);
        }
        else
        {
            titulo("Estrelas: " + string(total_estrelas()) + "/" + string(array_length(global.LV) * 3), 112, 0xf3efe6, 16);
            titulo("Queijos: " + string(total_queijos()) + "/" + string(total_queijos_max()), 138, 0xffd23f, 14);
            titulo((global.lvl == global.FIN) ? "Mundo novo desbloqueado: COFRE (lasers e pisos)" : "Tente pegar todas as estrelas e queijos", 166, 0xa9b4c4, 11);
        }
        if (global.ct > 0.8) titulo("Enter: voltar ao menu", 226, 0x7d8798, 10);
    }
}
