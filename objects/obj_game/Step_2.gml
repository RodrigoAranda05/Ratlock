// ===== End Step: o mundo anda depois que o rato se moveu (o obj_player roda no Step) =====
global.tempo_jogo += DT;
global.piscada = max(0, global.piscada - DT);
global.aviso_tempo -= DT;

if (global.estado == "play" && instance_exists(global.jogador))
{
    passo_fase();
    if (!global.cheat) global.stats.tempo += DT;
    global.tempo_gravar -= DT;
    if (global.tempo_gravar <= 0) { global.tempo_gravar = 20; grava_save(); }      // guarda tempo e mortes de vez em quando
}
else if (global.estado == "clear")
{
    global.tempo_tela += DT;
    if (global.modo == "challenge" && global.tempo_tela > 1.3) proxima_fase();
}
else global.tempo_tela += DT;

