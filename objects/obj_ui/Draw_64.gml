// ===== GUI: HUD e menus em alta resolução =====
// O layout é 480x272 (VW x VH); a matriz amplia para a janela e o texto sai com a resolução da janela.
gui_comeca();
if (room != rm_menu && instance_exists(obj_player)) desenha_hud();
desenha_menus();
if (global.pausa) desenha_pause_menu();
gui_termina();
if (room != rm_criador) desenha_transicao();      // no editor ela é desenhada pelo obj_criador (por cima dos ícones)
