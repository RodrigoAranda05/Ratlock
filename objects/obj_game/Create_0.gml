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
surface_resize(application_surface, JANELA_W, JANELA_H);
display_set_gui_size(JANELA_W, JANELA_H);
randomize();

// A room pode ter qualquer tamanho (múltiplo de 16). A câmera mostra a room inteira, ampliada o máximo
// que couber na janela e centralizada. Rooms pequenas (ex.: 320x176 = 20x11 tiles) ficam grandes na tela.
ajusta_tela = function()
{
    global.colunas = ceil(room_width / TL);
    global.linhas = ceil(room_height / TL);
    var zoom = min(JANELA_W / room_width, JANELA_H / room_height);
    if (zoom >= 3) zoom = floor(zoom);                  // pixel perfeito quando a room é pequena
    var larg = room_width * zoom;
    var alt = room_height * zoom;
    view_enabled = true;
    view_visible[0] = true;
    camera_set_view_pos(view_camera[0], 0, 0);
    camera_set_view_size(view_camera[0], room_width, room_height);
    view_xport[0] = (JANELA_W - larg) / 2;
    view_yport[0] = (JANELA_H - alt) / 2;
    view_wport[0] = larg;
    view_hport[0] = alt;
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

    // listas que os outros objetos consultam
    global.caixas = [];    with (obj_caixa) array_push(global.caixas, id);
    global.cabos = [];     with (obj_cabo) array_push(global.cabos, id);
    global.lampadas = [];  with (obj_lampada) array_push(global.lampadas, id);
    global.barris = [];    with (obj_barril) array_push(global.barris, id);
    global.dutos = [];     with (obj_duto) array_push(global.dutos, id);
    global.inimigos = [];  with (obj_inimigo) array_push(global.inimigos, id);
    global.queijos = [];   with (obj_queijo) array_push(global.queijos, id);
    global.chave = noone;  with (obj_chave) global.chave = id;

    // cada peça que precisa da grade pronta se prepara sozinha
    with (obj_queijo) prepara();            // queijo ao lado de parede falsa é secreto
    with (obj_ventoinha) prepara();         // marca a zona de vento
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
    if (global.cor_ativa >= 0)
    {
        if (tile_sobreposto(p, ocupa_portao_ativo) != undefined) ocupado = true;
        for (var k = 0; k < array_length(global.caixas); k++)
        {
            if (tile_sobreposto(global.caixas[k], ocupa_portao_ativo) != undefined) ocupado = true;
        }
    }
    if (tile_sobreposto(p, ocupa_piso_novo) != undefined) ocupado = true;
    for (var k = 0; k < array_length(global.caixas); k++)
    {
        if (tile_sobreposto(global.caixas[k], ocupa_piso_novo) != undefined) ocupado = true;
    }
    if (!ocupado)
    {
        global.cor_ativa = global.cor_pendente;
        faiscas(p.x + 5, p.y + 8, 10);
        var nomes = ["vermelhas", "azuis", "verdes", "amarelas"];
        mostra_aviso("Portas " + nomes[global.cor_ativa] + " abertas", 2);
    }
}

#endregion
