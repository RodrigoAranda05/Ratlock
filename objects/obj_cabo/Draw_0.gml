// caixa de energia (fios sobem e descem): com raio enquanto tem energia, cinza depois de roída
draw_sprite(spr_cabo, 2 + (roido ? 7 : 0), coluna * TL, linha * TL);
if (!roido && floor(global.tempo_jogo * 6) % 3 == 0 && random(1) < 0.3) faiscas(x, y, 1);
