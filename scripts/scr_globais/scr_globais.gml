// ===== variáveis globais =====
// Chamada uma vez pelo obj_game. Tudo que mais de um objeto precisa ler fica aqui.

function inicia_globais()
{
    global.debug = false;

    // tamanho da fase atual em tiles (obj_game acerta isso a cada room) e fonte de alta resolução
    global.colunas = 30;
    global.linhas = 17;
    cria_fonte();

    // tempo, avisos e telas
    global.tempo_jogo = 0;          // relógio de animação (nunca para)
    global.piscada = 0;             // flash branco da tela
    global.aviso_texto = "";
    global.aviso_tempo = 0;
    global.tempo_tela = 0;          // tempo desde que a tela atual abriu
    global.estado = "title";        // title, worlds, select, play, clear, win, lista_custom, editor
    global.modo = "normal";         // normal, challenge, teste (testando no editor) ou custom (fase do jogador)
    global.menu_cursor = 0;
    global.mundo_cursor = 0;
    global.mundo_sel = 0;
    global.fase_cursor = 0;
    global.fase_rolagem = 0;        // primeira linha de fases visível na seleção
    global.mundo_rolagem = 0;       // primeira linha de mundos visível

    // criador de fases
    global.ed = undefined;          // fase que está no editor: {nome, grade, validada, slot}
    global.custom_salvas = [];      // fases do jogador (criadas ou importadas), todas já validadas
    global.custom_atual = undefined;    // fase criada que está rodando na rm_custom
    global.trapaceou = false;       // usou cheat durante o teste (então não vale como validação)

    global.tempo_gravar = 20;       // segundos até gravar as estatísticas de novo
    global.stats = {tempo: 0, mortes: 0, conclusoes: 0, fases_criadas: 0};

    // cheats
    global.cheat = false;
    global.invencivel = false;

    // contadores
    global.mortes = 0;              // mortes no modo desafio
    global.tempo_total = 0;
    global.mortes_fase = 0;
    global.tempo_fase = 0;
    global.cabos_roidos = 0;
    global.chaves_soltas = 0;
    global.estrelas_fase = [false, false, false];
    global.queijo_fase = -1;
    global.novo_recorde = false;

    // estado da fase que está rodando
    global.fase_atual = 0;          // índice em global.fases (-1 = sala de teste fora da lista)
    global.info_fase = undefined;   // struct com nome, tempo_par, dica... da fase atual
    global.fase_nova = true;        // true = zera os contadores da fase ao abrir a room
    global.cor_ativa = -1;          // cor dos portões/pisos abertos (-1 nenhuma)
    global.cor_pendente = -1;
    global.luz_ligada = true;
    global.tem_chave = false;
    global.alarme = false;
    global.relogio_laser = 0;
    global.energia = true;          // poças eletrificadas

    // o que a fase em andamento tem (montado pelo obj_game.monta_fase no Room Start)
    global.grade = [];              // grade de colisão: um caractere por tile
    global.mapa_vento = [];
    global.particulas = [];
    global.caixas = [];
    global.cabos = [];
    global.lampadas = [];
    global.barris = [];
    global.dutos = [];
    global.inimigos = [];
    global.queijos = [];
    global.chave = noone;
    global.jogador = noone;

    // entradas lidas pelo obj_player e usadas pelo controle do jogo
    global.teclas = {
        esq: false, dir: false, cima: false, baixo: false, agarra: false, roi: false,
        pulo_apertou: false, agarra_apertou: false, solta_apertou: false
    };
}
