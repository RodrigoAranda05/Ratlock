// ===== Post Draw: desenha a tela do jogo na janela inteira =====
// A application_surface já tem o tamanho da janela (veja ajusta_tela): a cópia é 1:1, sem suavização.
var _ww = window_get_width();
var _wh = window_get_height();
if (_ww <= 0 || _wh <= 0) exit;
if (_ww != global.tela_w || _wh != global.tela_h) ajusta_tela();      // janela mudou: arruma para o próximo quadro

draw_clear(c_black);
gpu_set_texfilter(false);
gpu_set_blendenable(false);
draw_surface_stretched(application_surface, 0, 0, _ww, _wh);       // mesmo tamanho: 1:1 (durante um redimensionamento, estica)
gpu_set_blendenable(true);
