// ===== obj_celula: pai de tudo que ocupa um tile da grade =====
// A room põe a instância no canto do tile. Cada filho define o seu "simbolo" e, ao abrir a fase,
// o obj_game monta com eles a grade de colisão (global.grade). Os símbolos estão em scr_colisao.
coluna = floor(x / TL);
linha = floor(y / TL);
simbolo = ".";
depth = 50;
image_speed = 0;

// número fixo por tile, só para variar o visual
var _v = sin(coluna * 12.9 + linha * 78.2) * 43758.5453;
sorteio = _v - floor(_v);
