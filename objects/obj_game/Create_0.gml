// ===== obj_game: controlador do jogo =====
// Persistente: nasce na rm_menu e vive por todas as rooms. Ele só cuida do que não pertence a nenhum
// objeto: montar a fase quando a room abre e ditar a ordem em que o mundo anda a cada quadro.
// A lógica de cada coisa fica no objeto dela (obj_ventoinha, obj_laser, obj_caixa, obj_chave...).
//   scr_macros   -> TL, GW, GH, DT...          scr_globais -> variáveis globais (inicia_globais)
//   scr_fases    -> dados das fases            scr_colisao -> grade e colisão   scr_save -> progresso
//
// TESTAR UMA ROOM NOVA: pode colocar um obj_game nela e rodar direto; se já existe um (vindo do menu),
// o de dentro da room se destrói sozinho.

if (instance_number(obj_game) > 1)
{
    instance_destroy();
    exit;
}

persistent = true;
depth = -10000;

#region janela

gpu_set_texfilter(false);           // pixel perfeito, sem suavizar
window_set_size(JANELA_W, JANELA_H);
window_center();
display_set_gui_maximise(1, 1, 0, 0);    // GUI = janela inteira, 1 unidade = 1 pixel (sem deslocamento)
// A tela do jogo (application_surface) é desenhada por NÓS no Post Draw (Draw_77), ocupando a janela
// inteira. Deixar o GameMaker desenhar sozinho esticava/deslocava a imagem.
application_surface_draw_enable(false);
global.tela_w = JANELA_W; global.tela_h = JANELA_H;     // tamanho da janela usado na última arrumação
randomize();

// Arruma câmera, surface e GUI para o tamanho ATUAL da janela (chamado no Room Start e sempre que a
// janela muda de tamanho, pelo Post Draw). A room inteira é desenhada direto no tamanho da janela, sem
// suavização (pixel art nítida). Com a janela num múltiplo de 352x192 (a fase 22x12) cada pixel do jogo
// vira um quadrado exato (pixel-perfect); menus e rooms de outro tamanho enchem a janela do mesmo jeito.
ajusta_tela = function()
{
    global.colunas = ceil(room_width / TL);
    global.linhas = ceil(room_height / TL);
    var ww = max(1, window_get_width());
    var wh = max(1, window_get_height());
    global.tela_w = ww; global.tela_h = wh;
    view_enabled = true;
    view_visible[0] = true;
    camera_set_view_pos(view_camera[0], 0, 0);
    camera_set_view_size(view_camera[0], room_width, room_height);
    view_xport[0] = 0;
    view_yport[0] = 0;
    view_wport[0] = ww;
    view_hport[0] = wh;
    surface_resize(application_surface, ww, wh);
    // GUI cobrindo a janela inteira a partir do canto (0,0). Com display_set_gui_size o GameMaker
    // encaixava a GUI na proporção da surface e ela ficava deslocada (faixa sem véu na esquerda).
    display_set_gui_maximise(1, 1, 0, 0);
}

#endregion


#region inicialização

inicia_globais();
carrega_fases();
carrega_save();
carrega_pecas();
carrega_custom();
instance_create_depth(0, 0, -10000, obj_ui);
instance_create_depth(0, 0, -10001, obj_criador);

#endregion


#region montar a fase

// Pintar pedra no Room Editor: crie uma layer de tiles chamada tl_pedra com o tileset ts_pedra e pinte com QUALQUER tile.
// Ao abrir a fase, cada tile pintado vira pedra na grade (colisão) e o jogo troca o desenho pelo bloco certo
// (teto, chão, parede, canto ou ligação), olhando os vizinhos, inclusive as pedras que são objetos. O tile 0 do tileset é o vazio.
junta_tiles_pedra = function()
{
    if (!layer_exists("tl_pedra")) return;
    var _mapa = layer_tilemap_get_id("tl_pedra");
    if (_mapa == -1) return;
    var _cols = min(tilemap_get_width(_mapa), GW);
    var _lins = min(tilemap_get_height(_mapa), GH);
    var _pintados = [];
    for (var j = 0; j < _lins; j++)
    {
        for (var i = 0; i < _cols; i++)
        {
            if (tile_get_index(tilemap_get(_mapa, i, j)) == 0) continue;
            if (global.grade[j][i] == ".") global.grade[j][i] = "S";
            array_push(_pintados, [i, j]);
        }
    }
    for (var k = 0; k < array_length(_pintados); k++)
    {
        var c = _pintados[k][0];
        var l = _pintados[k][1];
        tilemap_set(_mapa, 1 + quadro_pedra(c, l), c, l);   // +1: o tile 0 é o vazio
    }
}

// chamado no Room Start: com as instâncias da room criadas, monta a grade e as listas do jogo
monta_fase = function()
{
    // grade de colisão: cada célula devolve o símbolo do seu objeto
    global.grade = [];
    global.mapa_vento = [];
    for (var j = 0; j < GH; j++)
    {
        var fileira_grade = [];
        var fileira_vento = [];
        for (var i = 0; i < GW; i++)
        {
            array_push(fileira_grade, ".");
            array_push(fileira_vento, "");
        }
        array_push(global.grade, fileira_grade);
        array_push(global.mapa_vento, fileira_vento);
    }
    with (obj_celula)
    {
        if (coluna >= 0 && coluna < GW && linha >= 0 && linha < GH) global.grade[linha][coluna] = simbolo;
    }

    // pedras pintadas no Room Editor (layer de tiles "tl_pedra"): entram na grade e escolhem o bloco pelos vizinhos
    junta_tiles_pedra();

    // listas que os outros objetos consultam
    global.caixas = [];    with (obj_caixa) array_push(global.caixas, id);
    global.cabos = [];     with (obj_cabo) array_push(global.cabos, id);
    global.lampadas = [];  with (obj_lampada) array_push(global.lampadas, id);
    global.barris = [];    with (obj_barril) array_push(global.barris, id);
    global.dutos = [];     with (obj_duto) array_push(global.dutos, id);
    global.inimigos = [];  with (obj_inimigo) array_push(global.inimigos, id);
    global.queijos = [];   with (obj_queijo) array_push(global.queijos, id);
    global.chave = noone;  with (obj_chave) global.chave = id;
    global.morcegos = [];  with (obj_morcego) array_push(global.morcegos, id);

    // Tutorial-Celeste: se a fase tem uma dica de morcego configurada e ninguém
    // colocou um morcego no editor, cria um automaticamente a 6 tiles à frente
    // do rato, grudado no teto (ou flutuando a 3 tiles do chão, se não houver teto).
    var _dica_fase = "";
    if (variable_struct_exists(global.info_fase, "dica_morcego")) _dica_fase = global.info_fase.dica_morcego;
    if (_dica_fase != "" && array_length(global.morcegos) == 0 && instance_exists(global.jogador))
    {
        var _px = global.jogador.x + global.jogador.w * 0.5;
        var _py = global.jogador.y + global.jogador.h;
        var _dir = 1;                                            // procura primeiro para a direita
        var _ci = floor(_px / TL) + 6 * _dir;
        if (_ci < 2 || _ci > GW - 3) { _dir = -_dir; _ci = floor(_px / TL) + 6 * _dir; }
        _ci = clamp(_ci, 2, GW - 3);
        var _base_lin = floor(_py / TL);
        // procura um teto próximo (de -4 a +2 linhas): célula vazia com parede logo acima
        var _cj = -1;
        for (var _dj = -4; _dj <= 2; _dj++)
        {
            var _lj = _base_lin + _dj;
            if (_lj < 1 || _lj >= GH - 1) continue;
            if (tile_em(_ci, _lj) == "." && tile_em(_ci, _lj - 1) != ".")
            {
                _cj = _lj;
                break;
            }
        }
        if (_cj == -1) _cj = clamp(_base_lin - 3, 1, GH - 2);
        var _mcg = instance_create_layer(_ci * TL, _cj * TL, "Instances", obj_morcego);   // canto da célula, como na room
        array_push(global.morcegos, _mcg);
    }

    // cada peça que precisa da grade pronta se prepara sozinha
    global.plat_span = [];
    for (var j = 0; j < GH; j++)
    {
        var fileira_span = [];
        for (var i = 0; i < GW; i++) array_push(fileira_span, [0, TL]);
        array_push(global.plat_span, fileira_span);
    }
    with (obj_cano) liga();                 // emenda os canos vizinhos
    with (obj_plataforma) liga();           // ponta, meio ou solta
    // fios automáticos: de cada caixa de energia um fio sobe até o teto e outro desce até o chão (só desenho)
    with (obj_cabo)
    {
        for (var j = linha - 1; j >= 0 && tile_em(coluna, j) == "."; j--) instance_create_layer(coluna * TL, j * TL, "Instances", obj_fio);
        for (var j = linha + 1; j < GH && tile_em(coluna, j) == "."; j++) instance_create_layer(coluna * TL, j * TL, "Instances", obj_fio);
    }
    with (obj_ventoinha) prepara();         // marca a zona de vento
    // fase que começa sem energia: todos os cabos estão desligados
    if (array_length(global.cabos) > 0)
    {
        var _todos_off = true;
        for (var q = 0; q < array_length(global.cabos); q++) if (!global.cabos[q].roido) _todos_off = false;
        if (_todos_off) global.luz_ligada = false;
    }
    // botão marcado como "comeca_ativo": só o primeiro (na ordem de criação) vale
    with (obj_botao)
    {
        if (comeca_ativo && global.cor_ativa < 0) { global.cor_ativa = cor; global.cor_pendente = cor; }
    }
    with (obj_duto) prepara();              // liga cada duto ao seu par
    with (obj_inimigo) prepara_patrulha();  // até onde o chão é reto

    instance_create_depth(0, 0, -10, obj_luz);
}

#endregion


#region o mundo anda (chamado no End Step, depois que o rato se moveu)

// ordem do quadro: dutos -> inimigos -> mundo -> contadores -> espinhos -> chave -> porta
passo_fase = function()
{
    var p = global.jogador;
    if (p.morto) return;
    p.verifica_dutos();
    with (obj_inimigo) atualiza();
    passo_mundo();
    global.tempo_fase += DT;
    global.tempo_total += DT;
    if (p.toca_espinho()) p.morre();
    if (instance_exists(global.chave)) global.chave.atualiza();
    with (obj_porta) atualiza();
}

// lasers, queijos, botões, cor ativa, caixas, câmeras e poças
passo_mundo = function()
{
    global.relogio_laser += DT;
    with (obj_laser) atualiza();
    with (obj_queijo) atualiza();
    with (obj_botao) atualiza();
    troca_cor_pendente();
    with (obj_caixa) atualiza();
    with (obj_camera) atualiza();

    // poças ficam eletrificadas enquanto houver cabo ligado
    global.energia = false;
    for (var q = 0; q < array_length(global.cabos); q++)
    {
        if (!global.cabos[q].roido) global.energia = true;
    }
    with (obj_poca) atualiza();
}

// um botão foi apertado: troca a cor ativa, mas só se ninguém estiver dentro do que vai fechar
troca_cor_pendente = function()
{
    if (global.cor_pendente < 0 || global.cor_pendente == global.cor_ativa) return;
    var p = global.jogador;
    var ocupado = false;
    if (tile_sobreposto(p, ocupa_portao_pendente) != undefined) ocupado = true;
    for (var k = 0; k < array_length(global.caixas); k++)
    {
        if (tile_sobreposto(global.caixas[k], ocupa_portao_pendente) != undefined) ocupado = true;
    }
    if (!ocupado)
    {
        global.cor_ativa = global.cor_pendente;
        faiscas(p.x + p.w / 2, p.y + p.h - 3, 10);
        toca_som("snd_botao");
        toca_som("snd_cor", 0.5);
        var nomes = ["vermelhas", "azuis", "verdes", "amarelas"];
        mostra_aviso("Blocos " + nomes[global.cor_ativa] + " ativos", 2);
    }
}

#endregion
