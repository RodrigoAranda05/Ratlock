// ===== fluxo do jogo: começar fase, passar de fase, fim =====

// troca de room com transição (o estado do jogo só muda quando a room troca): escurece, troca (o obj_game clareia ao abrir a nova room). _sala = -1 reinicia a room atual.
function vai_para(_sala, _estado = undefined)
{
    if (global.trans.fase != "off" && global.trans.fase != "entra") return;
    global.trans.fase = "sai";
    global.trans.t = 0;
    global.trans.destino = _sala;
    global.trans.estado = _estado;        // a tela só muda de estado quando a room trocar (senão o editor/menu pisca vazio)
}

// transição em persianas: faixas verticais pretas descem e sobem alternadas, em onda da esquerda para a direita.
// Desenhada por último, por cima de tudo (inclusive os ícones do editor).
function desenha_transicao()
{
    if (global.trans.fase == "off") return;
    var p = clamp(global.trans.t, 0, 1);
    var n = 16;
    var _gw = gui_largura(), _gh = gui_altura();   // GUI = janela inteira
    var larg = _gw / n;
    var atraso = 0.55;
    draw_set_colour(c_black);
    draw_set_alpha(1);
    for (var i = 0; i < n; i++)
    {
        var local = clamp((p * (1 + atraso) - (i / (n - 1)) * atraso), 0, 1);
        var e = local * local * (3 - 2 * local);
        if (e <= 0) continue;
        var h = _gh * e;
        var y0 = (i % 2 == 0) ? 0 : _gh - h;
        draw_rectangle(floor(i * larg) - 1, y0 - 1, ceil((i + 1) * larg) + 1, y0 + h + 1, false);
    }
    draw_set_colour(c_white);
}

// durante a saída o mundo fica parado
function transicao_saindo()
{
    return global.trans.fase == "sai" || global.trans.fase == "espera";
}

function inicia_fase(_i, _m)
{
    global.modo = _m;
    global.mundo_sel = global.fases[_i].mundo;
    global.mundo_cursor = global.mundo_sel;
    if (_m == "challenge") { global.mortes = 0; global.tempo_total = 0; }
    global.fase_nova = true;
    global.fase_atual = _i;
    vai_para(global.salas[_i], "play");
}

// joga uma fase do criador: "teste" (vindo do editor, valida a fase) ou "custom" (fase salva/importada)
function inicia_custom(_f, _modo)
{
    global.custom_atual = _f;
    global.modo = _modo;
    global.trapaceou = false;
    global.fase_nova = true;
    global.fase_atual = -1;
    vai_para(rm_custom, "play");
}

// volta da fase criada: o teste volta ao editor, a fase salva volta à lista
function sai_custom()
{
    vai_para(rm_criador, (global.modo == "teste") ? "editor" : "lista_custom");
}

function proxima_fase()
{
    if (global.modo == "teste" || global.modo == "custom")
    {
        sai_custom();
        return;
    }
    if (global.fase_atual < 0)      // sala de teste fora da lista: volta ao menu
    {
        vai_para(rm_menu, "worlds");
        return;
    }
    if (global.fase_atual + 1 >= array_length(global.fases) || (global.modo == "normal" && global.fase_atual == global.fase_final)) fim_jogo();
    else
    {
        global.fase_nova = true;
        global.fase_atual += 1;
        vai_para(global.salas[global.fase_atual], "play");
    }
}

function fim_jogo()
{
    global.novo_recorde = false;
    global.rank_pos = -1;
    if (global.modo == "challenge" && !global.cheat)
    {
        rank_registra(global.tempo_total, global.mortes);
        if (global.save.desafio_tempo < 0 || global.tempo_total < global.save.desafio_tempo)
        {
            global.save.desafio_tempo = global.tempo_total;
            global.save.desafio_mortes = global.mortes;
            global.novo_recorde = true;
            grava_save();
        }
    }
    global.tempo_tela = 0;
    vai_para(rm_menu, "win");
}

function fase_concluida()
{
    // a chave foi usada para abrir a porta: o rato aparece sem a chave na boca a partir daqui
    global.tem_chave = false;
    var L = global.info_fase;
    var r3 = false;
    if (L.objetivo3 == "cabo") r3 = (global.cabos_roidos == 0);
    else if (L.objetivo3 == "chave") r3 = (global.chaves_soltas == 0);
    else r3 = (global.tempo_fase <= L.tempo_par * 0.65);
    global.estrelas_fase = [global.mortes_fase == 0, global.tempo_fase <= L.tempo_par, r3];

    var todos = (array_length(global.queijos) > 0);
    for (var q = 0; q < array_length(global.queijos); q++)
    {
        if (!global.queijos[q].pego) todos = false;
    }
    global.queijo_fase = (array_length(global.queijos) > 0) ? (todos ? 1 : 0) : -1;

    if (!global.cheat && global.modo != "teste")
    {
        global.stats.conclusoes++;
        if (global.modo != "normal") grava_save();      // no modo normal o grava_save logo abaixo já grava
    }
    if (global.modo == "normal" && !global.cheat && global.fase_atual >= 0)
    {
        global.save.feita[global.fase_atual] = 1;
        if (global.queijo_fase == 1) global.save.queijo[global.fase_atual] = 1;
        // atenção: em GML arrays são copiados ao modificar, então grava direto no array original
        for (var q = 0; q < 3; q++)
        {
            if (global.estrelas_fase[q]) global.save.estrelas[global.fase_atual][q] = 1;
        }
        global.save.liberadas = max(global.save.liberadas, min(array_length(global.fases) - 1, global.fase_atual + 1));
        grava_save();
    }
    // terminou o teste no editor sem trapacear: a fase está validada e pode ser salva/compartilhada
    // se a fase tem queijo, ele precisa ter sido pego no teste: assim não dá para criar um queijo impossível
    if (global.modo == "teste" && !global.cheat && !global.trapaceou && global.ed != undefined)
    {
        if (global.queijo_fase == 0) { global.ed.validada = false; mostra_aviso("Pegue o queijo no teste para validar a fase", 4); }
        else global.ed.validada = true;
    }
    global.estado = "clear";
    global.tempo_tela = 0;
    global.vit_som = [false, false, false];      // as estrelas da tela de vitória tocam o som uma vez cada
    toca_som("snd_clear");
}
