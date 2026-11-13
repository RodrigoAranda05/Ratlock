// ===== mundo: vento, partículas e flash (coordenadas da room) =====
if (room != rm_menu && instance_exists(obj_player))
{
    desenha_vento();
    for (var q = 0; q < array_length(global.particulas); q++)
    {
        var fagulha = global.particulas[q];
        desenha_particula(fagulha);
    }
    if (global.piscada > 0 && global.config.flash) desenha_rect_alfa(0, 0, room_width, room_height, 0xffffff, global.piscada * 0.5);
}
