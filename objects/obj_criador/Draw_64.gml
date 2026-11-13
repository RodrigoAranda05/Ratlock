// ===== criador: desenho das telas =====
if (global.estado == "lista_custom" || global.estado == "editor")
{
    gui_comeca();
    if (global.estado == "lista_custom") desenha_lista();
    else desenha_editor();
    gui_termina();
}
desenha_transicao();      // por último: escurece os ícones do editor junto com o resto
