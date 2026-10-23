// ===== dados das fases =====
// global.fases guarda os dados de cada fase (nome, tempo para a 2ª estrela...). A room de cada fase só
// tem as instâncias; o obj_game monta o resto ao abrir a room.
//
// COMO CRIAR UMA FASE NOVA: crie a room com o nome rm_fase_30 (depois rm_fase_31...), ponha nela um obj_player,
// um obj_chave e um obj_porta, e desenhe o cenário com os obj_cano / obj_pedra... alinhados à grade de 16 px.
// Ela entra sozinha na lista abaixo (mundo "Cofre"). Para dar nome e tempo, adicione uma linha em global.fases.

function carrega_fases()
{
    global.mundos = [
        {n: "Celas", d: "Os primeiros passos do rato"},
        {n: "Circuitos", d: "Botões, caixas, cabos e água"},
        {n: "Vigilância", d: "Guardas, cão e câmeras"},
        {n: "Sopro", d: "Ventoinhas e a grande fuga"},
        {n: "Cofre", d: "Lasers, pisos de cor e verticais"}
    ];

        global.fases = [
        {mundo: 0, nome: "A Cela", tempo_par: 25, objetivo3: "chave", tem_queijo: 1},
        {mundo: 0, nome: "Garras", tempo_par: 35, objetivo3: "chave", tem_queijo: 1},
        {mundo: 0, nome: "Dutos", tempo_par: 15, objetivo3: "chave", tem_queijo: 1},
        {mundo: 0, nome: "Chave na Boca", tempo_par: 20, objetivo3: "rapido", tem_queijo: 1},
        {mundo: 1, nome: "Cores", tempo_par: 20, objetivo3: "chave", tem_queijo: 1},
        {mundo: 1, nome: "Vai e Volta", tempo_par: 25, objetivo3: "chave", tem_queijo: 1},
        {mundo: 1, nome: "Caixas", tempo_par: 30, objetivo3: "chave", tem_queijo: 1},
        {mundo: 1, nome: "Cabos", tempo_par: 30, objetivo3: "chave", tem_queijo: 1},
        {mundo: 1, nome: "Poças", tempo_par: 30, objetivo3: "chave", tem_queijo: 1},
        {mundo: 1, nome: "Caixa e Botão", tempo_par: 25, objetivo3: "chave", tem_queijo: 1},
        {mundo: 2, nome: "Patrulha", tempo_par: 25, objetivo3: "chave", tem_queijo: 1},
        {mundo: 2, nome: "Cão Farejador", tempo_par: 25, objetivo3: "chave", tem_queijo: 1},
        {mundo: 2, nome: "Câmera", tempo_par: 30, objetivo3: "cabo", tem_queijo: 1},
        {mundo: 2, nome: "Lanterna", tempo_par: 30, objetivo3: "cabo", tem_queijo: 1},
        {mundo: 2, nome: "Sentinela", tempo_par: 25, objetivo3: "cabo", tem_queijo: 1},
        {mundo: 2, nome: "Escudo", tempo_par: 25, objetivo3: "chave", tem_queijo: 1},
        {mundo: 2, nome: "Faro e Olhos", tempo_par: 25, objetivo3: "chave", tem_queijo: 1},
        {mundo: 3, nome: "Vento", tempo_par: 25, objetivo3: "chave", tem_queijo: 1},
        {mundo: 3, nome: "Ventania", tempo_par: 20, objetivo3: "chave", tem_queijo: 1},
        {mundo: 3, nome: "Sucção", tempo_par: 20, objetivo3: "chave", tem_queijo: 1},
        {mundo: 3, nome: "Quartel", tempo_par: 30, objetivo3: "cabo", tem_queijo: 1},
        {mundo: 3, nome: "A Fuga", tempo_par: 30, objetivo3: "chave", tem_queijo: 1},
        {mundo: 4, nome: "Raios", tempo_par: 30, objetivo3: "chave", tem_queijo: 1},
        {mundo: 4, nome: "Pontes", tempo_par: 30, objetivo3: "chave", tem_queijo: 1},
        {mundo: 4, nome: "Torre", tempo_par: 25, objetivo3: "chave", tem_queijo: 1},
        {mundo: 4, nome: "Apagão", tempo_par: 35, objetivo3: "chave", tem_queijo: 1},
        {mundo: 4, nome: "Cofre Duplo", tempo_par: 30, objetivo3: "chave", tem_queijo: 1},
        {mundo: 4, nome: "Eletricista", tempo_par: 35, objetivo3: "chave", tem_queijo: 1},
        {mundo: 4, nome: "Câmara Final", tempo_par: 30, objetivo3: "chave", tem_queijo: 1},
        {mundo: 4, nome: "Subsolo", tempo_par: 30, objetivo3: "chave", tem_queijo: 1}
    ];

    global.fase_final = 21;         // fase que fecha o mundo 4 (mostra a tela final)

    // procura as rooms rm_fase_01, rm_fase_02... até a primeira que não existir
    global.salas = [];
    var _n = 1;
    while (true)
    {
        var _sala = asset_get_index("rm_fase_" + ((_n < 10) ? "0" : "") + string(_n));
        if (_sala == -1 || !room_exists(_sala)) break;
        array_push(global.salas, _sala);
        _n++;
    }

    // rooms extras (rm_fase_30...) ganham dados padrão
    while (array_length(global.fases) < array_length(global.salas))
    {
        array_push(global.fases, fase_padrao(global.salas[array_length(global.fases)]));
    }
    global.info_fase = global.fases[0];
}

// dados de uma fase que ninguém cadastrou em global.fases
function fase_padrao(_sala)
{
    return {mundo: 4, nome: string_replace(room_get_name(_sala), "rm_", ""), tempo_par: 120, objetivo3: "chave", tem_queijo: 0};
}
