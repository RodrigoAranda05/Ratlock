// ===== GUI: HUD e menus em alta resolução =====
// O layout é 480x272 (VW x VH); a matriz amplia para a janela e o texto sai com a resolução da janela.
gui_comeca();
if (room != rm_menu && instance_exists(obj_player)) desenha_hud();
desenha_menus();
gui_termina();
