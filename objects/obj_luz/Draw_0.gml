// sem energia: escurece a sala; com energia: brilho nas lâmpadas
if (!global.luz_ligada && array_length(global.lampadas) > 0) desenha_rect_alfa(0, 0, room_width, room_height, 0x020510, 0.55);
gpu_set_blendmode(bm_add);
if (global.luz_ligada)
{
    for (var q = 0; q < array_length(global.lampadas); q++) desenha_brilho(global.lampadas[q].x, global.lampadas[q].y + 6, 70, 0.2);
}
for (var q = 0; q < array_length(global.inimigos); q++)
{
    var e = global.inimigos[q];
    if (e.tipo == "N") desenha_brilho(e.x + 6, e.y + 14, 58, global.luz_ligada ? 0.18 : 0.5);
}
gpu_set_blendmode(bm_normal);
