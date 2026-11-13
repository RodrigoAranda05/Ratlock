// ===== constantes do jogo =====
#macro TL 16            // tamanho do tile em pixels
#macro GW global.colunas  // colunas da sala (vem do tamanho da room)
#macro GH global.linhas   // linhas da sala (vem do tamanho da room)
#macro VW 480           // largura do layout de menus/HUD (desenhado em alta resolução na GUI)
#macro VH 272           // altura do layout de menus/HUD
// Resolução base do jogo = fase de 22x12 blocos (352x192). As janelas oferecidas são múltiplos inteiros
// dela (704x384, 1056x576, 1408x768, 1760x960...), assim a fase sai pixel-perfect e enche a janela.
// Menus e editor (480x272) são esticados para encher a mesma janela: nenhuma tela fica com borda preta.
#macro BASE_W 352
#macro BASE_H 192
#macro JANELA_W 1408    // janela inicial (antes de ler a configuração salva)
#macro JANELA_H 768
#macro DT 0.016666667   // passo fixo: o jogo roda a 60 fps (as velocidades são em px/s)
#macro FPS 60
#macro DEBUG_MODE true  // TAB liga o overlay de debug (veja obj_player)


// criador de fases: tamanho fixo da grade (a rm_custom tem CRIADOR_COL*TL x CRIADOR_LIN*TL, igual às fases do jogo)
#macro CRIADOR_COL 22
#macro CRIADOR_LIN 12
#macro ALFA_B64 "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"
#macro NOME_CHARS " ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
