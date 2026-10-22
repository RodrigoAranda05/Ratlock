// ===== constantes do jogo =====
#macro TL 16            // tamanho do tile em pixels
#macro GW global.colunas  // colunas da sala (vem do tamanho da room)
#macro GH global.linhas   // linhas da sala (vem do tamanho da room)
#macro VW 480           // largura do layout de menus/HUD (desenhado em alta resolução na GUI)
#macro VH 272           // altura do layout de menus/HUD
#macro JANELA_W 1280    // tamanho da janela
#macro JANELA_H 720
#macro DT 0.016666667   // passo fixo: o jogo roda a 60 fps (as velocidades são em px/s)
#macro FPS 60
#macro DEBUG_MODE true  // TAB liga o overlay de debug (veja obj_player)

#macro CANO_E 4            // o cano é fino: sólido de x=4 até x=12 dentro do tile de 16
#macro CANO_D 12

// criador de fases: tamanho fixo da grade (a rm_custom tem 320x176, igual às fases do jogo) e alfabetos do código de compartilhar
#macro CRIADOR_COL 20
#macro CRIADOR_LIN 11
#macro ALFA_B64 "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"
#macro NOME_CHARS " ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
