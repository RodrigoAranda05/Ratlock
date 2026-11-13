// ===== som: efeitos e música =====
// Os arquivos ficam em Sounds (snd_*). Tudo passa por aqui, então o volume de música e de efeitos
// (global.config, de 0 a 1, ajustado em CONFIGURAÇÕES) vale para o jogo inteiro.
// Se um som não existir no projeto, ele é simplesmente ignorado.

#region configurações salvas

function inicia_audio()
{
    global.config = {musica: 0.7, sons: 0.8, tela: false, flash: true, res: 0};
    global.mus = {h: -1, nome: "", velho: -1, velho_t: 0, vol: -1};
}

function carrega_config()
{
    ini_open("ratlock.ini");
    global.config.musica = clamp(ini_read_real("config", "musica", 0.7), 0, 1);
    global.config.sons = clamp(ini_read_real("config", "sons", 0.8), 0, 1);
    global.config.tela = (ini_read_real("config", "tela", 0) == 1);
    global.config.flash = (ini_read_real("config", "flash", 1) == 1);
    var rw = ini_read_real("config", "res_w", 1280);
    ini_close();
    monta_resolucoes();
    global.config.res = 0;
    for (var q = 0; q < array_length(global.resolucoes); q++) { if (global.resolucoes[q][0] == rw) global.config.res = q; }
    window_set_fullscreen(global.config.tela);
    aplica_resolucao();
}

// tamanhos de janela oferecidos (16:9): só os que cabem na tela do jogador
function monta_resolucoes()
{
    var cand = [[1280, 720], [1600, 900], [1920, 1080], [2560, 1440]];
    global.resolucoes = [];
    for (var q = 0; q < array_length(cand); q++)
    {
        if (q == 0 || (cand[q][0] <= display_get_width() && cand[q][1] <= display_get_height() - 40)) array_push(global.resolucoes, cand[q]);
    }
}

// muda o tamanho da janela; o jogo é desenhado em 1280x720 e a imagem é ampliada/reduzida junto (sem mexer no resto)
function aplica_resolucao()
{
    if (global.config.tela) return;       // em tela cheia o jogo já ocupa a tela toda
    var r = global.resolucoes[clamp(global.config.res, 0, array_length(global.resolucoes) - 1)];
    window_set_size(r[0], r[1]);
    window_center();
}

function grava_config()
{
    ini_open("ratlock.ini");
    ini_write_real("config", "musica", global.config.musica);
    ini_write_real("config", "sons", global.config.sons);
    ini_write_real("config", "tela", global.config.tela ? 1 : 0);
    ini_write_real("config", "flash", global.config.flash ? 1 : 0);
    ini_write_real("config", "res_w", global.resolucoes[clamp(global.config.res, 0, array_length(global.resolucoes) - 1)][0]);
    ini_close();
}

#endregion

#region efeitos sonoros

// toca um efeito (nome do asset). _vol multiplica o volume dos efeitos; _pitch muda o tom
function toca_som(_nome, _vol = 1, _pitch = 1)
{
    if (global.config.sons <= 0.001) return -1;
    var s = asset_get_index(_nome);
    if (s == -1) return -1;
    var h = audio_play_sound(s, 10, false);
    audio_sound_gain(h, _vol * global.config.sons, 0);
    if (_pitch != 1) audio_sound_pitch(h, _pitch);
    return h;
}

#endregion

#region música

// qual faixa deve tocar agora: no jogo a do jogo, em todo o resto a do menu
function musica_alvo()
{
    if (global.config.musica <= 0.001) return "";
    if (global.estado == "play" || global.estado == "clear") return "snd_musica_jogo";
    return "snd_musica_menu";
}

// chamada todo passo pelo obj_ui: troca de faixa com fade e segue o volume da configuração
function atualiza_musica()
{
    var m = global.mus;
    if (m.velho != -1)
    {
        m.velho_t -= DT;
        if (m.velho_t <= 0) { audio_stop_sound(m.velho); m.velho = -1; }
    }
    var alvo = musica_alvo();
    if (m.nome != alvo)
    {
        if (m.h != -1)
        {
            if (m.velho != -1) audio_stop_sound(m.velho);
            audio_sound_gain(m.h, 0, 400);
            m.velho = m.h;
            m.velho_t = 0.45;
            m.h = -1;
        }
        m.nome = alvo;
        m.vol = -1;
        var s = (alvo == "") ? -1 : asset_get_index(alvo);
        if (s != -1)
        {
            m.h = audio_play_sound(s, 1, true);
            audio_sound_gain(m.h, 0, 0);
        }
    }
    if (m.h != -1)
    {
        var v = global.config.musica * ((alvo == "snd_musica_jogo") ? 0.55 : 0.8);
        if (abs(v - m.vol) > 0.001)
        {
            audio_sound_gain(m.h, v, (m.vol < 0) ? 700 : 120);
            m.vol = v;
        }
    }
}

#endregion
