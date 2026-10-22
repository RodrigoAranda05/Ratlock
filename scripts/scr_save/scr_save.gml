// ===== progresso salvo (ratlock.ini) e contas por mundo =====

function carrega_save()
{
    ini_open("ratlock.ini");
    global.save = {
        liberadas: ini_read_real("geral", "unl", 0),
        desafio_tempo: ini_read_real("geral", "ch_t", -1),
        desafio_mortes: ini_read_real("geral", "ch_d", 0),
        estrelas: [],
        queijo: []
    };
    for (var i = 0; i < array_length(global.fases); i++)
    {
        var s = ini_read_string("estrelas", string(i), "000");
        array_push(global.save.estrelas, [real(string_char_at(s, 1)), real(string_char_at(s, 2)), real(string_char_at(s, 3))]);
        array_push(global.save.queijo, ini_read_real("queijo", string(i), 0));
    }
    ini_close();
}

function grava_save()
{
    ini_open("ratlock.ini");
    ini_write_real("geral", "unl", global.save.liberadas);
    ini_write_real("geral", "ch_t", global.save.desafio_tempo);
    ini_write_real("geral", "ch_d", global.save.desafio_mortes);
    for (var i = 0; i < array_length(global.fases); i++)
    {
        var a = global.save.estrelas[i];
        ini_write_string("estrelas", string(i), string(a[0]) + string(a[1]) + string(a[2]));
        ini_write_real("queijo", string(i), global.save.queijo[i]);
    }
    ini_close();
}

function fases_liberadas()
{
    return global.cheat ? 999 : global.save.liberadas;
}

function fases_do_mundo(_w)
{
    var r = [];
    for (var i = 0; i < array_length(global.fases); i++)
    {
        if (global.fases[i].mundo == _w) array_push(r, i);
    }
    return r;
}

function mundo_liberado(_w)
{
    return fases_do_mundo(_w)[0] <= fases_liberadas();
}

function mundo_estrelas(_w)
{
    var l = fases_do_mundo(_w), n = 0;
    for (var i = 0; i < array_length(l); i++)
    {
        var a = global.save.estrelas[l[i]];
        n += a[0] + a[1] + a[2];
    }
    return n;
}

function mundo_queijos(_w)
{
    var l = fases_do_mundo(_w), n = 0;
    for (var i = 0; i < array_length(l); i++) n += global.save.queijo[l[i]];
    return n;
}

function mundo_queijos_max(_w)
{
    var l = fases_do_mundo(_w), n = 0;
    for (var i = 0; i < array_length(l); i++)
    {
        if (global.fases[l[i]].tem_queijo > 0) n++;
    }
    return n;
}

function total_estrelas()
{
    var n = 0;
    for (var i = 0; i < array_length(global.fases); i++)
    {
        var a = global.save.estrelas[i];
        n += a[0] + a[1] + a[2];
    }
    return n;
}

function total_queijos()
{
    var n = 0;
    for (var i = 0; i < array_length(global.fases); i++) n += global.save.queijo[i];
    return n;
}

function total_queijos_max()
{
    var n = 0;
    for (var i = 0; i < array_length(global.fases); i++)
    {
        if (global.fases[i].tem_queijo > 0) n++;
    }
    return n;
}
