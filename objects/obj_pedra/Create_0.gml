// ===== obj_pedra: bloco de pedra (sólido) =====
// Os blocos NÃO se ligam: cada um tem o desenho do seu formato.
// forma (Variable Definitions, já existe antes do Create): 0 = 16x16 (padrão), 1 = 32x32, 2 = 16x32 em pé, 3 = 32x16 deitado.
// Nos formatos grandes o objeto fica no canto de cima-esquerda e ocupa vários tiles da grade.
event_inherited();
simbolo = "S";

aplica_forma = function()
{
    larg = pedra_larg(forma);
    alt = pedra_alt(forma);
    sprite_index = pedra_sprite(forma);
}
aplica_forma();
