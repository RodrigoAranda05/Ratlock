// ===== GUI: HUD e menus em alta resolução =====
// O layout é 480x272 (VW x VH); a matriz amplia para a janela e o texto sai com a resolução da janela.
var k = min(JANELA_W / VW, JANELA_H / VH);
var gx = (JANELA_W - VW * k) / 2;
var gy = (JANELA_H - VH * k) / 2;
matrix_set(matrix_world, matrix_build(gx, gy, 0, 0, 0, 0, k, k, 1));
if (room != rm_menu && instance_exists(obj_player)) desenha_hud();
desenha_menus();
matrix_set(matrix_world, matrix_build_identity());
draw_set_alpha(1);
draw_set_colour(c_white);
