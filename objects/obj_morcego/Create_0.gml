// A folha tem 14 quadros de 32x32: 8 parados e 6 de voo.
folha_morcego = spr_morcego;
if (!variable_instance_exists(id, "fala")) fala = "ESPAÇO";
// A instância fica no canto do tile; use o centro como ponto de desenho e interação.
x += 8;
y += 8;
image_speed = 0;
tempo_anim = 0;
quadro_bat = 0;
perto = false;
fugindo = false;
tempo_voo = 0;
vel_voo_x = 0;
vel_voo_y = 0;


