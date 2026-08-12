`timescale 1ns/1ps

package rns_pkg;

    // Modulos de la base
    localparam int M1 = 3;
    localparam int M2 = 5;
    localparam int M3 = 7;

    // Rango dinamico
    localparam int M  = M1 * M2 * M3;    // 105

    // Ancho de cada canal: log2 m_i
    localparam int W1 = 2;               // modulo 3 -> residuos 0..2
    localparam int W2 = 3;               // modulo 5 -> residuos 0..4
    localparam int W3 = 3;               // modulo 7 -> residuos 0..6

    // Ancho del dominio binario: log2 105
    localparam int WBIN = 7;

    // Constantes de la base del Teorema Chino del Resto
    localparam int C1 = 70;
    localparam int C2 = 21;
    localparam int C3 = 15;

    // Ancho del acumulador del reconstructor.
    // Cota superior de la suma: 70*2 + 21*4 + 15*6 = 314 -> 9 bits.
    localparam int ACCW = 9;

endpackage