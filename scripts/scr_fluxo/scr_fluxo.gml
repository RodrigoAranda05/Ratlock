// ===== fluxo do jogo: começar fase, passar de fase, fim =====

function inicia_fase(_i, _m)
{
    global.modo = _m;
    global.mundo_sel = global.fases[_i].mundo;
    global.mundo_cursor = global.mundo_sel;
    if (_m == "challenge") { global.mortes = 0; global.tempo_total = 0; }
    global.fase_nova = true;
    global.fase_atual = _i;
    global.estado = "play";
    room_goto(global.salas[_i]);
}

function proxima_fase()
{
    if (global.fase_atual < 0)      // sala de teste fora da lista: volta ao menu
    {
        global.estado = "worlds";
        room_goto(rm_menu);
        return;
    }
    if (global.fase_atual + 1 >= array_length(global.fases) || (global.modo == "normal" && global.fase_atual == global.fase_final)) fim_jogo();
    else
    {
        global.fase_nova = true;
        global.fase_atual += 1;
        global.estado = "play";
        room_goto(global.salas[global.fase_atual]);
    }
}

function fim_jogo()
{
    global.novo_recorde = false;
    if (global.modo == "challenge" && !global.cheat)
    {
        if (global.save.desafio_tempo < 0 || global.tempo_total < global.save.desafio_tempo)
        {
            global.save.desafio_tempo = global.tempo_total;
            global.save.desafio_mortes = global.mortes;
            global.novo_recorde = true;
            grava_save();
        }
    }
    global.estado = "win";
    global.tempo_tela = 0;
    room_goto(rm_menu);
}

function fase_concluida()
{
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

    if (global.modo == "normal" && !global.cheat && global.fase_atual >= 0)
    {
        if (global.queijo_fase == 1) global.save.queijo[global.fase_atual] = 1;
        // atenção: em GML arrays são copiados ao modificar, então grava direto no array original
        for (var q = 0; q < 3; q++)
        {
            if (global.estrelas_fase[q]) global.save.estrelas[global.fase_atual][q] = 1;
        }
        global.save.liberadas = max(global.save.liberadas, min(array_length(global.fases) - 1, global.fase_atual + 1));
        grava_save();
    }
    global.estado = "clear";
    global.tempo_tela = 0;
}
