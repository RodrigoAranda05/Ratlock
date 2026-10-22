// ===== obj_barril: esconderijo (o rato segura S em cima dele) =====
coluna = floor(x / TL);
linha = floor(y / TL);
x = coluna * TL + 3;
y = linha * TL + 2;
depth = 30;
sprite_index = spr_barril;      // o editor mostra spr_ed_barril (origem deslocada); no jogo vale este
