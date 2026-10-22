// faísca na água quando há energia
image_index = (global.energia && sin(global.tempo_jogo * 14 + coluna * 3 + linha) > 0.1) ? 1 : 0;
