event_inherited();
// VARIÁVEL DA ROOM: "numero" (1 ou 2). Só existe um par de dutos por fase: entrando em um, o rato sai no outro.
simbolo = string(numero);
sprite_index = spr_duto;
destino = noone;        // duto de saída (ligado em prepara)
x += 8;                 // o duto vira um ponto no centro do tile
y += 8;

// chamado pelo obj_game quando todos os dutos da fase já existem
prepara = function()
{
    var numero_par = (numero % 2 == 1) ? numero + 1 : numero - 1;
    with (obj_duto)
    {
        if (id != other.id && numero == numero_par) other.destino = id;
    }
}
