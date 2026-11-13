// ===== obj_morcego: morcego-tutorial (inspirado no corvo do Celeste) =====
// Fica pendurado onde você colocou na room, com uma caixa de dica acima dizendo a tecla.
// Quando o rato chega perto, ele bate as asas e voa para fora da fase.
//
// Texto da dica: a variável "fala" (Variable Definitions do objeto; dá para mudar por instância
// na room com duplo clique). Se "fala" estiver vazia, usa dica_morcego da fase, senão "A    D".
// spr_morcego: 32x32, origem no centro. Quadros 0-7 = parado, 8-13 = voando.
// Posição: como as outras peças, conta a CÉLULA onde foi colocado (canto da célula de 16x16).
// Ele fica no meio da célula, com os pés em cima do bloco logo abaixo (acerta no 1º quadro).

x = floor(x / TL) * TL + TL / 2;
pousou = false;                  // ainda precisa grudar os pés no chão (a grade só existe depois do Room Start)

tempo = 0;
anim = 0;                        // quadro atual (com fração)
estado = "parado";               // parado -> avistou -> voando
sentido = 1;                     // para onde voa (-1 = esquerda, 1 = direita)
velh = 0; velv = 0;
balao_pulo = 0;                  // deslocamento vertical (balanço / saltinho antes de voar)
depth = -2;

// distância (px) em que o rato "acorda" o morcego
raio_ativa = 40;

// texto da caixa
dica_texto = "";
if (variable_instance_exists(id, "fala") && is_string(fala)) dica_texto = fala;
if (dica_texto == "" && variable_struct_exists(global.info_fase, "dica_morcego")) dica_texto = global.info_fase.dica_morcego;
if (dica_texto == "") dica_texto = "A    D";
