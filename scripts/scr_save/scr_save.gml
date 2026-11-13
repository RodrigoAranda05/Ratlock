// ===== progresso salvo (ratlock.ini) e contas por mundo =====

function carrega_save()
{
    ini_open("ratlock.ini");
    global.save = {
        liberadas: ini_read_real("geral", "unl", 0),
        desafio_tempo: ini_read_real("geral", "ch_t", -1),
        desafio_mortes: ini_read_real("geral", "ch_d", 0),
        estrelas: [],
        queijo: [],
        feita: []           // 1 = a fase já foi concluída alguma vez (mesmo sem estrela)
    };
    global.stats = {
        tempo: ini_read_real("stats", "tempo", 0),          // segundos jogando
        mortes: ini_read_real("stats", "mortes", 0),
        conclusoes: ini_read_real("stats", "clears", 0),    // vezes que passou de fase (conta repetições)
        fases_criadas: ini_read_real("stats", "criadas", 0) // fases que o jogador validou no criador
    };
    for (var i = 0; i < array_length(global.fases); i++)
    {
        var s = ini_read_string("estrelas", string(i), "000");
        array_push(global.save.estrelas, [real(string_char_at(s, 1)), real(string_char_at(s, 2)), real(string_char_at(s, 3))]);
        array_push(global.save.queijo, ini_read_real("queijo", string(i), 0));
        // saves antigos não tinham "feita": vale o que dá para deduzir (estrela, queijo ou fase já liberada depois dela)
        var s2 = global.save.estrelas[i];
        var deduz = (s2[0] + s2[1] + s2[2] > 0 || global.save.queijo[i] > 0 || i < global.save.liberadas) ? 1 : 0;
        array_push(global.save.feita, ini_read_real("feita", string(i), deduz));
    }
    ini_close();
    carrega_config();
    carrega_rank();
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
        ini_write_real("feita", string(i), global.save.feita[i]);
    }
    ini_write_real("stats", "tempo", global.stats.tempo);
    ini_write_real("stats", "mortes", global.stats.mortes);
    ini_write_real("stats", "clears", global.stats.conclusoes);
    ini_write_real("stats", "criadas", global.stats.fases_criadas);
    ini_close();
    grava_config();
}

// ---------- números da tela de estatísticas ----------
function total_feitas()
{
    var n = 0;
    for (var i = 0; i < array_length(global.fases); i++) n += global.save.feita[i];
    return n;
}

function total_perfeitas()
{
    var n = 0;
    for (var i = 0; i < array_length(global.fases); i++)
    {
        var a = global.save.estrelas[i];
        if (a[0] + a[1] + a[2] == 3) n++;
    }
    return n;
}

function mundo_feitas(_w)
{
    var l = fases_do_mundo(_w), n = 0;
    for (var i = 0; i < array_length(l); i++) n += global.save.feita[l[i]];
    return n;
}

function mundos_completos()
{
    var n = 0;
    for (var w = 0; w < array_length(global.mundos); w++)
    {
        if (mundo_feitas(w) == array_length(fases_do_mundo(w))) n++;
    }
    return n;
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

#region ranking do modo desafio (local; a função rank_envia_steam é o gancho para o ranking online)

#macro RANK_MAX 10

function carrega_rank()
{
    global.rank = [];
    global.rank_pos = -1;           // posição da última corrida no ranking (-1 = fora)
    ini_open("ratlock.ini");
    var n = ini_read_real("rank", "n", 0);
    for (var i = 0; i < n; i++)
    {
        array_push(global.rank, {
            tempo: ini_read_real("rank", "t" + string(i), 0),
            mortes: ini_read_real("rank", "m" + string(i), 0),
            data: ini_read_string("rank", "d" + string(i), "")
        });
    }
    ini_close();
}

function grava_rank()
{
    ini_open("ratlock.ini");
    ini_write_real("rank", "n", array_length(global.rank));
    for (var i = 0; i < array_length(global.rank); i++)
    {
        ini_write_real("rank", "t" + string(i), global.rank[i].tempo);
        ini_write_real("rank", "m" + string(i), global.rank[i].mortes);
        ini_write_string("rank", "d" + string(i), global.rank[i].data);
    }
    ini_close();
}

function texto_data()
{
    var d = date_current_datetime();
    var dia = date_get_day(d), mes = date_get_month(d);
    return ((dia < 10) ? "0" : "") + string(dia) + "/" + ((mes < 10) ? "0" : "") + string(mes) + "/" + string(date_get_year(d));
}

// registra uma corrida terminada: menor tempo primeiro, empate = menos mortes. Devolve a posição (0 = primeiro) ou -1
function rank_registra(_tempo, _mortes)
{
    var nova = {tempo: _tempo, mortes: _mortes, data: texto_data()};
    var pos = array_length(global.rank);
    for (var i = 0; i < array_length(global.rank); i++)
    {
        var r = global.rank[i];
        if (_tempo < r.tempo || (_tempo == r.tempo && _mortes < r.mortes)) { pos = i; break; }
    }
    var lista = [];
    for (var i = 0; i < pos; i++) array_push(lista, global.rank[i]);
    array_push(lista, nova);
    for (var i = pos; i < array_length(global.rank); i++) array_push(lista, global.rank[i]);
    var corte = [];
    for (var i = 0; i < min(RANK_MAX, array_length(lista)); i++) array_push(corte, lista[i]);
    global.rank = corte;
    global.rank_pos = (pos < RANK_MAX) ? pos : -1;
    grava_rank();
    rank_envia_steam(_tempo, _mortes);
    return global.rank_pos;
}

// GANCHO PARA A STEAM: quando o jogo estiver na Steam, envie a pontuação aqui
// (por exemplo steam_upload_score("desafio", real(round(_tempo * 1000))) e leia o ranking online com steam_download_scores).
function rank_envia_steam(_tempo, _mortes)
{
}

#endregion

// apaga todo o progresso, estatísticas e ranking (as fases criadas pelo jogador ficam)
function apaga_progresso()
{
    global.save.liberadas = 0;
    global.save.desafio_tempo = -1;
    global.save.desafio_mortes = 0;
    for (var i = 0; i < array_length(global.fases); i++)
    {
        global.save.estrelas[i] = [0, 0, 0];
        global.save.queijo[i] = 0;
        global.save.feita[i] = 0;
    }
    global.stats = {tempo: 0, mortes: 0, conclusoes: 0, fases_criadas: global.stats.fases_criadas};
    global.rank = [];
    global.rank_pos = -1;
    grava_save();
    grava_rank();
}

function todas_fases_completas()
{
    return total_feitas() >= array_length(global.fases);
}
