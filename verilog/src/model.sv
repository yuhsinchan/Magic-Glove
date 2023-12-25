module Model (
    input i_clk,
    input i_rst_n,
    input i_start,
    input signed [15:0] i_data[0:39],
    output signed [15:0] o_norm[0:39],
    output signed [23:0] o_cnn[0:29],
    output signed [31:0] o_logits[0:2],
    output [4:0] o_char[0:2],
    output o_finished
);

    localparam S_IDLE = 3'd0;
    localparam S_PREP = 3'd1;
    localparam S_CONV = 3'd2;
    localparam S_FC = 3'd3;
    localparam S_SORT = 3'd4;
    localparam S_DONE = 3'd5;

    localparam bit signed [15:0] kernel_weights[0:9][0:23] = '{
        '{
            -16'h13b2,
            -16'h15cb,
            -16'h1b00,
            16'h2c69,
            16'h2c30,
            16'h2c5e,
            -16'h0b70,
            -16'h0354,
            16'h0385,
            -16'h2905,
            -16'h2852,
            -16'h28ef,
            16'h2051,
            16'h2058,
            16'h1f30,
            -16'h2937,
            -16'h2966,
            -16'h2986,
            -16'h009b,
            -16'h0089,
            -16'h0019,
            16'h1936,
            16'h18cb,
            16'h1810
        },
        '{
            -16'h1297,
            -16'h0fc9,
            -16'h0a19,
            -16'h1670,
            -16'h09b1,
            -16'h1047,
            -16'h1391,
            -16'h1113,
            -16'h1323,
            16'h1034,
            16'h110b,
            16'h0f3c,
            -16'h2546,
            -16'h25be,
            -16'h265a,
            -16'h2c75,
            -16'h2c30,
            -16'h2c56,
            -16'h0545,
            -16'h060a,
            -16'h07c2,
            16'h0721,
            16'h0978,
            16'h0ac6
        },
        '{
            16'h1d2e,
            16'h19dc,
            16'h198f,
            16'h19f6,
            16'h159c,
            16'h1fc8,
            -16'h0e27,
            -16'h0068,
            -16'h0bd4,
            -16'h02ab,
            16'h0514,
            16'h0140,
            -16'h127f,
            -16'h1457,
            -16'h16b3,
            -16'h28ae,
            -16'h28ac,
            -16'h2852,
            16'h2b1b,
            16'h2afb,
            16'h2b63,
            16'h2be8,
            16'h2bed,
            16'h2bd4
        },
        '{
            -16'h1d78,
            -16'h1cb4,
            -16'h1aff,
            -16'h13f5,
            -16'h0454,
            -16'h10e5,
            -16'h09dc,
            -16'h0462,
            -16'h1076,
            -16'h0b93,
            -16'h07ad,
            -16'h07eb,
            -16'h22d2,
            -16'h22f0,
            -16'h230c,
            16'h1f6f,
            16'h1e2c,
            16'h208f,
            16'h2b84,
            16'h2b67,
            16'h2ba1,
            16'h2b23,
            16'h2a5b,
            16'h2ac1
        },
        '{
            16'h276c,
            16'h27ab,
            16'h28b8,
            -16'h092f,
            16'h0cd7,
            16'h00e1,
            -16'h27a6,
            -16'h244d,
            -16'h2767,
            16'h089c,
            16'h0710,
            16'h06e9,
            -16'h2b23,
            -16'h2ae6,
            -16'h2b05,
            -16'h17a2,
            -16'h17fc,
            -16'h16a9,
            16'h2c52,
            16'h2c21,
            16'h2c22,
            -16'h1171,
            -16'h1099,
            -16'h0ef6
        },
        '{
            16'h2b0c,
            16'h2a9e,
            16'h2adc,
            16'h1270,
            16'h1093,
            16'h12b0,
            -16'h272a,
            -16'h2196,
            -16'h27d3,
            16'h1198,
            16'h10ee,
            16'h153f,
            -16'h09ff,
            -16'h0aca,
            -16'h0b95,
            16'h2c82,
            16'h2c78,
            16'h2c6b,
            16'h1b9d,
            16'h1c49,
            16'h1d2c,
            -16'h198c,
            -16'h1728,
            -16'h167d
        },
        '{
            -16'h27d8,
            -16'h2918,
            -16'h29f0,
            16'h00c7,
            -16'h05df,
            16'h15f3,
            -16'h10e3,
            -16'h0215,
            -16'h03db,
            16'h1414,
            16'h117b,
            16'h1541,
            -16'h24d1,
            -16'h252b,
            -16'h2590,
            16'h2ba8,
            16'h2bd5,
            16'h2bc1,
            16'h1117,
            16'h1151,
            16'h12be,
            -16'h26d9,
            -16'h264e,
            -16'h268d
        },
        '{
            -16'h1ca9,
            -16'h1d01,
            -16'h1d95,
            16'h157b,
            16'h17f7,
            16'h1f92,
            -16'h1738,
            -16'h12ae,
            -16'h169e,
            16'h2c5a,
            16'h2c6d,
            16'h2c53,
            16'h1021,
            16'h0fbe,
            16'h0fa5,
            16'h0541,
            16'h06e7,
            16'h0885,
            -16'h2bf2,
            -16'h2be7,
            -16'h2ba3,
            16'h0653,
            16'h051d,
            16'h0402
        },
        '{
            16'h2c28,
            16'h2bea,
            16'h2c0b,
            16'h154a,
            16'h19fe,
            16'h17d6,
            -16'h1563,
            -16'h135f,
            -16'h157d,
            -16'h0f5f,
            -16'h118a,
            -16'h0b00,
            16'h21ac,
            16'h2191,
            16'h2334,
            16'h2b94,
            16'h2b97,
            16'h2b72,
            -16'h2af8,
            -16'h2aba,
            -16'h2abf,
            -16'h0475,
            16'h0047,
            16'h0405
        },
        '{
            16'h060e,
            16'h0812,
            16'h0b6b,
            -16'h008e,
            16'h0f05,
            -16'h0971,
            16'h0ffc,
            16'h0451,
            16'h0a02,
            -16'h0a5c,
            -16'h0716,
            -16'h0b0f,
            -16'h2bfa,
            -16'h2c0b,
            -16'h2c0e,
            16'h2787,
            16'h27a1,
            16'h27ea,
            -16'h26d2,
            -16'h2675,
            -16'h2687,
            16'h1d8b,
            16'h1af1,
            16'h195a
        }
    };

    localparam bit signed [15:0] cnn_bias[0:9] = '{
        16'h08d8,
        16'h0b7e,
        -16'h0b01,
        16'h1462,
        16'h23ea,
        -16'h1e79,
        16'h27a7,
        -16'h03b3,
        -16'h28a4,
        16'h2752
    };


    localparam bit signed [15:0] fc_weights[0:26][0:29] = '{
        '{
            16'h09e6,
            16'h06b3,
            16'h0cdb,
            -16'h112f,
            -16'h0f7e,
            -16'h0e91,
            16'h0a8c,
            16'h09a9,
            16'h0b1e,
            16'h0d97,
            16'h0c3a,
            16'h0c0a,
            -16'h0d7f,
            -16'h0adc,
            -16'h0731,
            16'h0857,
            16'h0835,
            16'h0c04,
            -16'h096c,
            -16'h0921,
            -16'h0952,
            -16'h0702,
            -16'h06ab,
            -16'h04c2,
            16'h1470,
            16'h14d3,
            16'h1386,
            -16'h1587,
            -16'h1653,
            -16'h1881
        },
        '{
            -16'h09d7,
            -16'h0841,
            -16'h089b,
            16'h12bf,
            16'h1204,
            16'h1201,
            -16'h0dc4,
            -16'h0a0f,
            -16'h0cb1,
            -16'h1c9d,
            -16'h1bb8,
            -16'h1b4d,
            16'h0502,
            16'h04a2,
            16'h018a,
            16'h0440,
            16'h06b4,
            16'h0533,
            16'h0812,
            16'h0561,
            16'h02ad,
            16'h1267,
            16'h10f5,
            16'h111a,
            -16'h0252,
            -16'h03c7,
            -16'h0477,
            16'h026b,
            16'h027b,
            16'h03be
        },
        '{
            -16'h0b92,
            -16'h0899,
            -16'h0f27,
            -16'h0f3a,
            -16'h0ddd,
            -16'h0f0a,
            -16'h0a8d,
            -16'h09c3,
            -16'h0c87,
            16'h07b3,
            16'h077c,
            16'h09d6,
            -16'h0ac4,
            -16'h0960,
            -16'h0a54,
            -16'h0bbb,
            -16'h06d1,
            -16'h0c96,
            -16'h0b99,
            -16'h0ac1,
            -16'h0d70,
            -16'h01b5,
            16'h0027,
            -16'h036a,
            16'h0e78,
            16'h0d72,
            16'h0fde,
            -16'h0547,
            -16'h0c9a,
            -16'h05e2
        },
        '{
            -16'h0829,
            -16'h0664,
            -16'h0a73,
            16'h01d6,
            -16'h020e,
            -16'h00c8,
            16'h03f7,
            16'h0782,
            16'h0dc3,
            16'h19df,
            16'h1825,
            16'h1a10,
            16'h08f1,
            -16'h0263,
            16'h0728,
            16'h0991,
            16'h093e,
            16'h1415,
            16'h159e,
            16'h1585,
            16'h16ae,
            -16'h09d3,
            -16'h0bdc,
            -16'h068b,
            16'h09f5,
            16'h0734,
            16'h0727,
            16'h1efd,
            16'h1f7f,
            16'h1e28
        },
        '{
            -16'h0a35,
            -16'h09fe,
            -16'h0a1c,
            -16'h0dec,
            -16'h1138,
            -16'h1368,
            16'h043c,
            16'h026c,
            16'h0113,
            16'h063b,
            16'h0410,
            16'h02b1,
            16'h03ad,
            -16'h026c,
            -16'h075f,
            16'h0bf5,
            16'h0923,
            16'h0776,
            -16'h0420,
            -16'h0b29,
            -16'h0bbf,
            16'h0665,
            16'h01db,
            16'h028b,
            16'h0c5e,
            16'h0c46,
            16'h0c45,
            -16'h0f84,
            -16'h0d83,
            -16'h0cd6
        },
        '{
            16'h0401,
            16'h0293,
            16'h04ba,
            16'h07cb,
            16'h07b3,
            16'h0980,
            16'h029d,
            16'h0152,
            16'h0704,
            -16'h1485,
            -16'h12e3,
            -16'h1265,
            16'h05f4,
            16'h0606,
            16'h0713,
            -16'h0db3,
            -16'h0cf9,
            -16'h0a99,
            -16'h1478,
            -16'h1373,
            -16'h1181,
            16'h0429,
            16'h030d,
            16'h05ca,
            -16'h0c31,
            -16'h0b1d,
            -16'h0bac,
            -16'h0cde,
            -16'h086f,
            -16'h0bcd
        },
        '{
            -16'h06a5,
            -16'h02a3,
            -16'h0226,
            16'h05ac,
            16'h04ba,
            16'h0439,
            -16'h1496,
            -16'h105a,
            -16'h0f54,
            -16'h127e,
            -16'h1115,
            -16'h10e2,
            -16'h059a,
            -16'h0543,
            -16'h0524,
            -16'h089c,
            -16'h0892,
            -16'h093d,
            -16'h15e5,
            -16'h16f3,
            -16'h1802,
            16'h054f,
            16'h0574,
            16'h06a2,
            -16'h0197,
            -16'h01b6,
            -16'h0032,
            -16'h11a2,
            -16'h13a0,
            -16'h14ef
        },
        '{
            -16'h0e06,
            -16'h0b1d,
            -16'h0e70,
            16'h043f,
            16'h011b,
            -16'h004b,
            -16'h114c,
            -16'h0b78,
            -16'h0b63,
            16'h0494,
            16'h056a,
            16'h0c4c,
            16'h070e,
            16'h03bb,
            16'h03f7,
            16'h1815,
            16'h18be,
            16'h17b2,
            16'h1c09,
            16'h1b01,
            16'h19b5,
            -16'h0b82,
            -16'h08b6,
            -16'h08ce,
            -16'h028c,
            -16'h031a,
            -16'h0200,
            16'h0f2c,
            16'h11ed,
            16'h14b7
        },
        '{
            -16'h0e2c,
            -16'h0552,
            -16'h0d7c,
            -16'h0cb4,
            -16'h0cc6,
            -16'h0cd1,
            -16'h1120,
            -16'h0de9,
            -16'h1065,
            -16'h0b9d,
            -16'h0f69,
            -16'h0c98,
            -16'h04e4,
            -16'h08c8,
            -16'h0605,
            16'h0081,
            16'h0bd6,
            16'h058a,
            16'h0a53,
            16'h020d,
            -16'h0909,
            16'h0328,
            16'h08d4,
            16'h05f1,
            16'h043a,
            16'h0191,
            16'h0766,
            -16'h1992,
            -16'h16a2,
            -16'h112d
        },
        '{
            16'h0b0d,
            -16'h0825,
            16'h04ee,
            -16'h12f1,
            -16'h1002,
            -16'h0fb0,
            -16'h1337,
            -16'h143e,
            -16'h162c,
            -16'h10d5,
            -16'h09e3,
            -16'h1512,
            -16'h1cad,
            -16'h05f0,
            -16'h0779,
            16'h0799,
            -16'h0227,
            16'h04ed,
            16'h00df,
            16'h05ec,
            16'h10e9,
            16'h04f3,
            16'h02fc,
            16'h04c3,
            16'h02a5,
            16'h04cb,
            16'h00ff,
            -16'h0f4e,
            -16'h1866,
            -16'h20cc
        },
        '{
            -16'h0de7,
            -16'h0df3,
            -16'h0d7a,
            -16'h01b5,
            -16'h028b,
            -16'h0308,
            -16'h1020,
            -16'h0ef5,
            -16'h0f19,
            -16'h12ff,
            -16'h0ff2,
            -16'h1264,
            -16'h0452,
            16'h025d,
            16'h02ad,
            16'h09d0,
            16'h09fb,
            16'h0abf,
            16'h1cb4,
            16'h1c8b,
            16'h1ca1,
            16'h0b37,
            16'h0aa3,
            16'h09ce,
            -16'h0464,
            -16'h0410,
            -16'h0301,
            16'h2b42,
            16'h2b38,
            16'h2b62
        },
        '{
            16'h0565,
            16'h04b4,
            16'h0526,
            16'h0ae1,
            16'h0ae4,
            16'h0724,
            -16'h02b1,
            -16'h04de,
            -16'h083c,
            -16'h1034,
            -16'h119b,
            -16'h1301,
            16'h02fb,
            16'h02a6,
            -16'h0250,
            -16'h0891,
            -16'h0a66,
            -16'h1108,
            -16'h04d1,
            -16'h04f1,
            -16'h065f,
            -16'h07c7,
            -16'h0742,
            -16'h0c31,
            -16'h0834,
            -16'h08b8,
            -16'h07eb,
            -16'h04a7,
            -16'h03d0,
            16'h0030
        },
        '{
            16'h16d0,
            16'h1590,
            16'h14df,
            16'h1773,
            16'h1625,
            16'h1647,
            -16'h24ac,
            -16'h24e0,
            -16'h2543,
            16'h0afe,
            16'h0ca9,
            16'h0ccc,
            -16'h1ebf,
            -16'h1e63,
            -16'h1e57,
            16'h0086,
            16'h0010,
            -16'h0044,
            16'h1103,
            16'h0f0c,
            16'h1003,
            16'h1aae,
            16'h1a2c,
            16'h1959,
            -16'h0f37,
            -16'h0e05,
            -16'h0dd2,
            16'h0320,
            16'h0355,
            16'h03b8
        },
        '{
            16'h1791,
            16'h1748,
            16'h1797,
            16'h157a,
            16'h1627,
            16'h1706,
            -16'h04f9,
            -16'h0557,
            -16'h0621,
            16'h142c,
            16'h1259,
            16'h128a,
            -16'h01da,
            -16'h0240,
            -16'h0240,
            -16'h153f,
            -16'h14bc,
            -16'h1465,
            16'h0d25,
            16'h0f50,
            16'h0f75,
            -16'h0e26,
            -16'h0d10,
            -16'h0c35,
            -16'h1150,
            -16'h11c2,
            -16'h11ff,
            -16'h1816,
            -16'h1831,
            -16'h192f
        },
        '{
            -16'h080f,
            -16'h0681,
            -16'h04ae,
            -16'h0b24,
            -16'h0a4f,
            -16'h091c,
            -16'h093c,
            -16'h0910,
            -16'h085b,
            16'h0965,
            16'h0531,
            16'h0219,
            -16'h09ea,
            -16'h0a34,
            -16'h0a43,
            -16'h06a8,
            -16'h03c2,
            -16'h00bd,
            -16'h0b23,
            -16'h0762,
            -16'h0747,
            16'h013c,
            16'h0328,
            16'h04d1,
            16'h138c,
            16'h1295,
            16'h11a7,
            -16'h125b,
            -16'h1486,
            -16'h1664
        },
        '{
            -16'h0197,
            -16'h03ae,
            -16'h04ac,
            16'h165a,
            16'h1483,
            16'h114e,
            16'h15fe,
            16'h14f3,
            16'h13fa,
            -16'h1328,
            -16'h12b8,
            -16'h132e,
            -16'h083e,
            -16'h0930,
            -16'h0cf8,
            -16'h0481,
            -16'h03cf,
            -16'h049d,
            -16'h10dc,
            -16'h0fcb,
            -16'h1096,
            16'h075f,
            16'h07d4,
            16'h071c,
            -16'h0f89,
            -16'h0e15,
            -16'h0c29,
            16'h15f5,
            16'h1552,
            16'h1602
        },
        '{
            -16'h14a5,
            -16'h0f0b,
            -16'h1155,
            16'h0f11,
            16'h0eed,
            16'h0e17,
            16'h0386,
            16'h0475,
            16'h044e,
            -16'h1050,
            -16'h10ae,
            -16'h0ff5,
            16'h0a3a,
            16'h08c7,
            16'h086a,
            16'h0376,
            16'h0500,
            16'h00e5,
            16'h1aab,
            16'h1737,
            16'h15ae,
            -16'h093d,
            -16'h0993,
            -16'h09ba,
            -16'h0eeb,
            -16'h0ee4,
            -16'h0e6e,
            -16'h19ba,
            -16'h1805,
            -16'h1649
        },
        '{
            16'h03d6,
            16'h04d3,
            16'h015d,
            16'h0fd5,
            16'h1049,
            16'h0f61,
            16'h10e9,
            16'h11be,
            16'h11a9,
            16'h189c,
            16'h1473,
            16'h13fb,
            16'h0e8a,
            16'h0f1e,
            16'h1037,
            -16'h0969,
            -16'h04a2,
            -16'h0770,
            -16'h0624,
            -16'h04d6,
            -16'h075c,
            -16'h090c,
            -16'h093f,
            -16'h0d60,
            -16'h1027,
            -16'h10f0,
            -16'h1005,
            -16'h02c9,
            -16'h060e,
            -16'h036e
        },
        '{
            -16'h0aa8,
            -16'h0a03,
            -16'h0cf6,
            -16'h1445,
            -16'h120d,
            -16'h11c1,
            -16'h06c6,
            -16'h048a,
            -16'h0470,
            16'h0680,
            16'h089f,
            16'h0e00,
            -16'h0b54,
            -16'h0751,
            -16'h053e,
            16'h083d,
            16'h09a3,
            16'h093e,
            -16'h0a8f,
            -16'h09af,
            -16'h0b87,
            16'h03b0,
            16'h0433,
            16'h03ad,
            16'h11ae,
            16'h1216,
            16'h123f,
            -16'h10fd,
            -16'h1140,
            -16'h0f2a
        },
        '{
            16'h0697,
            16'h0378,
            16'h0255,
            -16'h0cad,
            -16'h0ec6,
            -16'h0fae,
            -16'h03ea,
            -16'h067b,
            -16'h0413,
            16'h1d15,
            16'h1cc0,
            16'h1d4d,
            16'h0602,
            16'h0507,
            16'h0515,
            16'h0ec3,
            16'h09f0,
            16'h0a2c,
            -16'h0125,
            -16'h02ad,
            -16'h0192,
            -16'h0250,
            -16'h04d0,
            -16'h04f6,
            16'h0c0e,
            16'h0c53,
            16'h0c4b,
            -16'h0420,
            -16'h00a9,
            -16'h00fb
        },
        '{
            16'h037d,
            16'h044d,
            16'h05c2,
            16'h117b,
            16'h0fea,
            16'h0f58,
            16'h13ff,
            16'h1235,
            16'h1271,
            16'h1041,
            16'h0c2f,
            16'h0d22,
            16'h0db0,
            16'h0d26,
            16'h0d50,
            -16'h08f1,
            -16'h0b88,
            -16'h0ae1,
            -16'h020a,
            -16'h02c3,
            -16'h02a9,
            -16'h0162,
            -16'h049f,
            -16'h05d3,
            -16'h0435,
            -16'h03b4,
            -16'h03b3,
            -16'h07c4,
            -16'h0688,
            -16'h0719
        },
        '{
            16'h07e2,
            16'h03ff,
            16'h02e3,
            16'h0a4c,
            16'h0b81,
            16'h0cc2,
            16'h191c,
            16'h193f,
            16'h1a06,
            16'h01bd,
            16'h052b,
            16'h065c,
            16'h0984,
            16'h096f,
            16'h0935,
            -16'h097d,
            -16'h0a52,
            -16'h0a04,
            -16'h04b5,
            -16'h0402,
            -16'h0372,
            -16'h09b8,
            -16'h07a2,
            -16'h04fa,
            -16'h0a1e,
            -16'h0b61,
            -16'h0c71,
            -16'h0497,
            -16'h05c0,
            -16'h0796
        },
        '{
            -16'h02e9,
            -16'h045b,
            -16'h01a1,
            16'h0e37,
            16'h1000,
            16'h12e6,
            16'h13d2,
            16'h13ff,
            16'h1501,
            -16'h11bb,
            -16'h11f4,
            -16'h11cf,
            -16'h091e,
            -16'h0731,
            -16'h040f,
            -16'h07e4,
            -16'h0881,
            -16'h07ef,
            -16'h135d,
            -16'h13d0,
            -16'h13ba,
            16'h06c2,
            16'h06c4,
            16'h07bd,
            -16'h027b,
            -16'h0295,
            -16'h035a,
            16'h14e3,
            16'h14f0,
            16'h1562
        },
        '{
            16'h0f1c,
            16'h08e3,
            16'h14e9,
            -16'h11bf,
            -16'h104e,
            -16'h0fd3,
            16'h1402,
            16'h0e8d,
            16'h0b87,
            16'h0c46,
            16'h0d14,
            16'h0bcd,
            -16'h015b,
            -16'h0311,
            -16'h0561,
            16'h0c34,
            16'h0794,
            16'h08c0,
            16'h0b3b,
            16'h0c05,
            16'h0fda,
            16'h06fd,
            16'h026e,
            16'h07ea,
            16'h096a,
            16'h064a,
            -16'h0483,
            -16'h1202,
            -16'h0ff6,
            -16'h11d8
        },
        '{
            16'h09c7,
            -16'h03b6,
            16'h0253,
            -16'h0d22,
            -16'h12ab,
            -16'h1174,
            -16'h0f27,
            -16'h0f96,
            -16'h0bb4,
            -16'h0fc0,
            -16'h0cca,
            -16'h0a2a,
            -16'h02d5,
            -16'h088c,
            -16'h06b3,
            16'h1234,
            16'h06d8,
            16'h0dc3,
            16'h0659,
            16'h0065,
            16'h03a9,
            -16'h037d,
            -16'h04c9,
            -16'h0216,
            16'h02ac,
            16'h0393,
            16'h02c0,
            -16'h1a69,
            -16'h17a5,
            -16'h1a1a
        },
        '{
            -16'h05f2,
            -16'h0683,
            16'h006a,
            -16'h0f1b,
            -16'h0b23,
            -16'h087f,
            16'h09a4,
            16'h0374,
            -16'h017c,
            16'h1676,
            16'h171e,
            16'h1543,
            16'h0184,
            16'h0c10,
            16'h0749,
            -16'h06b6,
            -16'h0911,
            -16'h09bd,
            16'h135d,
            16'h1863,
            16'h19ca,
            -16'h04e0,
            -16'h03d2,
            -16'h05e5,
            -16'h0679,
            -16'h0350,
            -16'h04b7,
            16'h1898,
            16'h17b7,
            16'h181d
        },
        '{
            16'h053e,
            16'h071d,
            16'h04e9,
            16'h0023,
            16'h0157,
            -16'h025c,
            -16'h185e,
            -16'h183e,
            -16'h1892,
            -16'h06ea,
            -16'h06e2,
            -16'h07df,
            -16'h17d6,
            -16'h179f,
            -16'h1893,
            -16'h0e73,
            -16'h0de3,
            -16'h10d7,
            16'h003f,
            16'h00e7,
            16'h0025,
            -16'h0829,
            -16'h07fa,
            -16'h091a,
            -16'h1dd8,
            -16'h1ee1,
            -16'h1ea8,
            16'h0c04,
            16'h0c0e,
            16'h0f59
        }
    };

    localparam bit signed [15:0] fc_bias[0:26] = '{
        -16'h2a85,
        16'h05cc,
        16'h1ba1,
        -16'h17fb,
        16'h186a,
        16'h1d22,
        -16'h0823,
        16'h0aa4,
        16'h065a,
        -16'h295f,
        -16'h1fa4,
        16'h1b58,
        -16'h2b22,
        -16'h2755,
        16'h2d05,
        -16'h1268,
        -16'h26ff,
        -16'h0b91,
        -16'h0756,
        16'h1242,
        16'h10f0,
        16'h15f8,
        -16'h1698,
        -16'h24da,
        -16'h17b6,
        16'h2297,
        16'h2752
    };


    logic norm_start_r, norm_start_w;
    logic cnn_start_r, cnn_start_w;
    logic fc_start_r, fc_start_w;
    logic finish_r, finish_w;

    logic signed [15:0] fc_weight_r[0:29], fc_weight_w[0:29];
    logic signed [15:0] kernel_weight_r[0:23], kernel_weight_w[0:23];
    logic signed [15:0] cnn_bias_r, cnn_bias_w;
    logic signed [23:0] cnn_channel_output[0:2];
    logic signed [15:0] fc_bias_r, fc_bias_w;
    logic signed [31:0] top3_prob_r[0:2], top3_prob_w[0:2], tmp_prob_r, tmp_prob_w;
    logic [4:0]
        top3_char_r[0:2], top3_char_w[0:2], tmp_char_r, tmp_char_w, nn_counter_r, nn_counter_w;
    logic [1:0] sort_counter_r, sort_counter_w;

    logic [0:4] norm_finish;
    logic cnn_finish;
    logic fc_finish;

    logic [2:0] state_r, state_w;

    logic signed [15:0] norm_data  [0:39];
    logic signed [15:0] norm_data_T[0:39];
    logic signed [23:0] cnn_output_r [0:29], cnn_output_w[0:29];
    logic signed [31:0] fc_output;

    // assign o_norm = norm_data;
    // assign o_cnn = cnn_output_r;
    assign o_logits[0] = top3_prob_r[0][31:8];
    assign o_logits[1] = top3_prob_r[1][31:8];
    assign o_logits[2] = top3_prob_r[2][31:8];
    assign o_char = top3_char_r;
    assign o_finished = finish_r;

    assign norm_data_T[0:4] = '{
                                norm_data[0], norm_data[8], norm_data[16], norm_data[24], norm_data[32]
                };
    assign norm_data_T[5:9] = '{
                                norm_data[1], norm_data[9], norm_data[17], norm_data[25], norm_data[33]
                };
    assign norm_data_T[10:14] = '{
                                norm_data[2], norm_data[10], norm_data[18], norm_data[26], norm_data[34]
                };
    assign norm_data_T[15:19] = '{
                                norm_data[3], norm_data[11], norm_data[19], norm_data[27], norm_data[35]
                };
    assign norm_data_T[20:24] = '{
                                norm_data[4], norm_data[12], norm_data[20], norm_data[28], norm_data[36]
                };
    assign norm_data_T[25:29] = '{
                                norm_data[5], norm_data[13], norm_data[21], norm_data[29], norm_data[37]
                };
    assign norm_data_T[30:34] = '{
                                norm_data[6], norm_data[14], norm_data[22], norm_data[30], norm_data[38]
                };
    assign norm_data_T[35:39] = '{
                                norm_data[7], norm_data[15], norm_data[23], norm_data[31], norm_data[39]
                };

    Normalizer norm0 (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_start(norm_start_r),
        .i_data(i_data[0:7]),
        .o_norm(norm_data[0:7]),
        .o_finished(norm_finish[0])
    );

    Normalizer norm1 (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_start(norm_start_r),
        .i_data(i_data[8:15]),
        .o_norm(norm_data[8:15]),
        .o_finished(norm_finish[1])
    );

    Normalizer norm2 (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_start(norm_start_r),
        .i_data(i_data[16:23]),
        .o_norm(norm_data[16:23]),
        .o_finished(norm_finish[2])
    );

    Normalizer norm3 (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_start(norm_start_r),
        .i_data(i_data[24:31]),
        .o_norm(norm_data[24:31]),
        .o_finished(norm_finish[3])
    );

    Normalizer norm4 (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_start(norm_start_r),
        .i_data(i_data[32:39]),
        .o_norm(norm_data[32:39]),
        .o_finished(norm_finish[4])
    );


    Conv conv (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_start(cnn_start_r),
        .i_kernel(kernel_weight_r),
        .i_data(norm_data_T),
        .i_bias(cnn_bias_r),
        .o_weights(cnn_channel_output),
        .o_finished(cnn_finish)
    );

    FC fc (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_start(fc_start_r),
        .i_weight(fc_weight_r),
        .i_data(cnn_output_r),
        .i_bias(fc_bias_r),
        .o_output(fc_output),
        .o_finished(fc_finish)
    );

    always_comb begin
        norm_start_w = norm_start_r;
        cnn_start_w = cnn_start_r;
        fc_start_w = fc_start_r;
        finish_w = finish_r;
        state_w = state_r;
        fc_weight_w = fc_weight_r;
        fc_bias_w = fc_bias_r;
        top3_char_w = top3_char_r;
        top3_prob_w = top3_prob_r;
        tmp_char_w = tmp_char_r;
        tmp_prob_w = tmp_prob_r;
        nn_counter_w = nn_counter_r;
        sort_counter_w = sort_counter_r;
        kernel_weight_w = kernel_weight_r;
        cnn_bias_w = cnn_bias_r;
        cnn_output_w = cnn_output_r;

        case (state_r)
            S_IDLE: begin
                if (i_start) begin
                    state_w = S_PREP;
                    norm_start_w = 1'b1;
                    top3_char_w = '{3{5'b0}};
                    top3_prob_w = '{3{32'b0}};
                end
            end
            S_PREP: begin
                norm_start_w = 1'b0;
                if (norm_finish == {5{1'b1}}) begin
                    state_w = S_CONV;
                    cnn_start_w = 1'b1;
                    nn_counter_w = 0;
                    kernel_weight_w = kernel_weights[0];
                    cnn_bias_w = $signed(cnn_bias[0]);

                    // debug
                    // top3_char_w[0] = norm_data[0][3:0];
                    // top3_char_w[1] = norm_data[1][3:0];
                    // top3_char_w[2] = norm_data[2][3:0];
                    // state_w = S_DONE;
                    // finish_w = 1;
                end
            end
            S_CONV: begin
                cnn_start_w = 1'b0;
                if (cnn_finish == 1'b1) begin
                    if (nn_counter_r < 5'd9) begin
                        case (nn_counter_r)
                            0: begin
                                cnn_output_w[0:2] = cnn_channel_output;
                            end
                            1: begin
                                cnn_output_w[3:5] = cnn_channel_output;
                            end
                            2: begin
                                cnn_output_w[6:8] = cnn_channel_output;
                            end
                            3: begin
                                cnn_output_w[9:11] = cnn_channel_output;
                            end
                            4: begin
                                cnn_output_w[12:14] = cnn_channel_output;
                            end
                            5: begin
                                cnn_output_w[15:17] = cnn_channel_output;
                            end
                            6: begin
                                cnn_output_w[18:20] = cnn_channel_output;
                            end
                            7: begin
                                cnn_output_w[21:23] = cnn_channel_output;
                            end
                            8: begin
                                cnn_output_w[24:26] = cnn_channel_output;
                            end
                            9: begin
                                cnn_output_w[27:29] = cnn_channel_output;
                            end
                        endcase
                        kernel_weight_w = kernel_weights[nn_counter_r+1];
                        cnn_bias_w = $signed(cnn_bias_r[nn_counter_r+1]);
                        nn_counter_w = nn_counter_r + 1;
                        cnn_start_w = 1'b1;
                    end 
                    else begin
                        cnn_output_w[27:29] = cnn_channel_output;
                        fc_start_w = 1'b1;
                        state_w = S_FC;
                        fc_weight_w = fc_weights[0];
                        fc_bias_w = $signed(fc_bias[0]);
                        nn_counter_w = 5'd0;
                    end
                end
            end
            S_FC: begin
                fc_start_w = 1'b0;
                if (fc_finish == 1'b1) begin
                    state_w = S_SORT;
                    tmp_char_w = nn_counter_r;
                    tmp_prob_w = fc_output;
                    sort_counter_w = 2'b0;
                    nn_counter_w = nn_counter_r + 1;
                end
            end
            S_SORT: begin
                if ($signed(tmp_prob_r) > $signed(top3_prob_r[sort_counter_r])) begin
                // if ($signed(tmp_prob_r) > 0) begin
                    top3_char_w[sort_counter_r] = tmp_char_r;
                    top3_prob_w[sort_counter_r] = $signed(tmp_prob_r);
                    tmp_char_w = top3_char_r[sort_counter_r];
                    tmp_prob_w = $signed(top3_prob_r[sort_counter_r]);
                end
                if (sort_counter_r == 2'd2 || (tmp_char_r == top3_char_r[sort_counter_r])) begin
                    if (nn_counter_r < 5'd27) begin
                        state_w = S_FC;
                        fc_start_w = 1'b1;
                        fc_weight_w = fc_weights[nn_counter_r];
                        fc_bias_w = $signed(fc_bias[nn_counter_r]);
                    end else begin
                        state_w  = S_DONE;
                        finish_w = 1'b1;
                    end
                end
                sort_counter_w = sort_counter_r + 1;
            end
            S_DONE: begin
                finish_w = 1'b0;
                state_w  = S_IDLE;
                fc_weight_w = '{30{1'b0}};
                fc_bias_w   = 0;
                kernel_weight_w = '{24{1'b0}};
                cnn_bias_w = 0;
                tmp_char_w = 0;
                tmp_prob_w = 0;
            end
        endcase
    end

    always_ff @(posedge i_clk or posedge i_rst_n) begin
        if (i_rst_n) begin
            norm_start_r <= 0;
            cnn_start_r <= 0;
            fc_start_r <= 0;
            finish_r <= 0;
            state_r <= S_IDLE;
            fc_weight_r <= '{30{1'b0}};
            fc_bias_r <= 0;
            top3_char_r <= '{0, 0, 0};
            top3_prob_r <= '{0, 0, 0};
            tmp_char_r <= 0;
            tmp_prob_r <= 0;
            nn_counter_r <= 0;
            sort_counter_r <= 0;
            kernel_weight_r <= '{24{1'b0}};
            cnn_bias_r <= 0;
            cnn_output_r <= '{30{1'b0}};
        end else begin
            norm_start_r <= norm_start_w;
            cnn_start_r <= cnn_start_w;
            fc_start_r <= fc_start_w;
            finish_r <= finish_w;
            state_r <= state_w;
            fc_weight_r <= fc_weight_w;
            fc_bias_r <= fc_bias_w;
            top3_char_r <= top3_char_w;
            top3_prob_r <= top3_prob_w;
            tmp_char_r <= tmp_char_w;
            tmp_prob_r <= tmp_prob_w;
            nn_counter_r <= nn_counter_w;
            sort_counter_r <= sort_counter_w;
            kernel_weight_r <= kernel_weight_w;
            cnn_bias_r <= cnn_bias_w;
            cnn_output_r <= cnn_output_w;
        end
    end
endmodule
