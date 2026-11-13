import Machine
import Cells
open X86

/-! `p16` as assembled: 460 instructions. Written from the lifter's rows. -/

set_option maxRecDepth 100000
namespace Code_p16

def table : List (Nat × Instr × Nat) := [
  (0x18000, .nop, 0x18004),
  (0x18004, .push .rbp, 0x18005),
  (0x18005, .mov 64 (.reg .rbp) (.reg .rsp), 0x18008),
  (0x18008, .push .rbx, 0x18009),
  (0x18009, .push .r12, 0x1800B),
  (0x1800B, .push .r13, 0x1800D),
  (0x1800D, .push .r14, 0x1800F),
  (0x1800F, .push .r15, 0x18011),
  (0x18011, .and 64 (.reg .rsp) (.imm 0xFFFFFFFFFFFFFFC0), 0x18015),
  (0x18015, .sub 64 (.reg .rsp) (.imm 0x100), 0x1801C),
  (0x1801C, .mov 8 (.mem .rsp 0x0) (.imm 0x0), 0x18020),
  (0x18020, .mov 64 (.reg .r12) (.reg .rdi), 0x18023),
  (0x18023, .mov 64 (.reg .r13) (.reg .rsi), 0x18026),
  (0x18026, .mov 64 (.reg .r14) (.reg .rdx), 0x18029),
  (0x18029, .mov 64 (.reg .r15) (.reg .r9), 0x1802C),
  (0x1802C, .mov 64 (.reg .rbx) (.reg .r8), 0x1802F),
  (0x1802F, .mov 64 (.reg .r9) (.reg .rcx), 0x18032),
  (0x18032, .zbroadcast 0 (.mem .r14 0x0), 0x18038),
  (0x18038, .zbroadcast 1 (.mem .r14 0x4), 0x1803F),
  (0x1803F, .zbroadcast 2 (.mem .r14 0x8), 0x18046),
  (0x18046, .zbroadcast 3 (.mem .r14 0xC), 0x1804D),
  (0x1804D, .zbroadcast 4 (.mem .r14 0x10), 0x18054),
  (0x18054, .zbroadcast 5 (.mem .r14 0x14), 0x1805B),
  (0x1805B, .zbroadcast 6 (.mem .r14 0x18), 0x18062),
  (0x18062, .zbroadcast 7 (.mem .r14 0x1C), 0x18069),
  (0x18069, .xor 32 (.reg .r14) (.reg .r14), 0x1806C),
  (0x1806C, .movzx8 .r8 (.reg .rbx), 0x18070),
  (0x18070, .mov 32 (.reg .r10) (.reg .rbx), 0x18073),
  (0x18073, .shr32 .r10 8, 0x18077),
  (0x18077, .and 32 (.reg .r10) (.imm 0xFF), 0x1807E),
  (0x1807E, .or 32 (.reg .r10) (.reg .r8), 0x18081),
  (0x18081, .mov 32 (.reg .rdi) (.reg .rbx), 0x18083),
  (0x18083, .shr32 .rdi 16, 0x18086),
  (0x18086, .and 32 (.reg .rdi) (.imm 0xFF), 0x1808C),
  (0x1808C, .mov 32 (.reg .rsi) (.reg .rbx), 0x1808E),
  (0x1808E, .shr32 .rsi 24, 0x18091),
  (0x18091, .mov 64 (.reg .rax) (.mem .r12 0x0), 0x18095),
  (0x18095, .zloadi 16 .rax .r14 0x0, 0x1809C),
  (0x1809C, .mov 64 (.reg .rax) (.mem .r12 0x8), 0x180A1),
  (0x180A1, .zloadi 17 .rax .r14 0x0, 0x180A8),
  (0x180A8, .mov 64 (.reg .rax) (.mem .r12 0x10), 0x180AD),
  (0x180AD, .zloadi 18 .rax .r14 0x0, 0x180B4),
  (0x180B4, .mov 64 (.reg .rax) (.mem .r12 0x18), 0x180B9),
  (0x180B9, .zloadi 19 .rax .r14 0x0, 0x180C0),
  (0x180C0, .mov 64 (.reg .rax) (.mem .r12 0x20), 0x180C5),
  (0x180C5, .zloadi 20 .rax .r14 0x0, 0x180CC),
  (0x180CC, .mov 64 (.reg .rax) (.mem .r12 0x28), 0x180D1),
  (0x180D1, .zloadi 21 .rax .r14 0x0, 0x180D8),
  (0x180D8, .mov 64 (.reg .rax) (.mem .r12 0x30), 0x180DD),
  (0x180DD, .zloadi 22 .rax .r14 0x0, 0x180E4),
  (0x180E4, .mov 64 (.reg .rax) (.mem .r12 0x38), 0x180E9),
  (0x180E9, .zloadi 23 .rax .r14 0x0, 0x180F0),
  (0x180F0, .mov 64 (.reg .rax) (.mem .r12 0x40), 0x180F5),
  (0x180F5, .zloadi 24 .rax .r14 0x0, 0x180FC),
  (0x180FC, .mov 64 (.reg .rax) (.mem .r12 0x48), 0x18101),
  (0x18101, .zloadi 25 .rax .r14 0x0, 0x18108),
  (0x18108, .mov 64 (.reg .rax) (.mem .r12 0x50), 0x1810D),
  (0x1810D, .zloadi 26 .rax .r14 0x0, 0x18114),
  (0x18114, .mov 64 (.reg .rax) (.mem .r12 0x58), 0x18119),
  (0x18119, .zloadi 27 .rax .r14 0x0, 0x18120),
  (0x18120, .mov 64 (.reg .rax) (.mem .r12 0x60), 0x18125),
  (0x18125, .zloadi 28 .rax .r14 0x0, 0x1812C),
  (0x1812C, .mov 64 (.reg .rax) (.mem .r12 0x68), 0x18131),
  (0x18131, .zloadi 29 .rax .r14 0x0, 0x18138),
  (0x18138, .mov 64 (.reg .rax) (.mem .r12 0x70), 0x1813D),
  (0x1813D, .zloadi 30 .rax .r14 0x0, 0x18144),
  (0x18144, .mov 64 (.reg .rax) (.mem .r12 0x78), 0x18149),
  (0x18149, .zloadi 31 .rax .r14 0x0, 0x18150),
  (0x18150, .zunpckldq 8 16 17, 0x18156),
  (0x18156, .zunpckhdq 16 16 17, 0x1815C),
  (0x1815C, .zunpckldq 17 18 19, 0x18162),
  (0x18162, .zunpckhdq 18 18 19, 0x18168),
  (0x18168, .zunpckldq 19 20 21, 0x1816E),
  (0x1816E, .zunpckhdq 20 20 21, 0x18174),
  (0x18174, .zunpckldq 21 22 23, 0x1817A),
  (0x1817A, .zunpckhdq 22 22 23, 0x18180),
  (0x18180, .zunpckldq 23 24 25, 0x18186),
  (0x18186, .zunpckhdq 24 24 25, 0x1818C),
  (0x1818C, .zunpckldq 25 26 27, 0x18192),
  (0x18192, .zunpckhdq 26 26 27, 0x18198),
  (0x18198, .zunpckldq 27 28 29, 0x1819E),
  (0x1819E, .zunpckhdq 28 28 29, 0x181A4),
  (0x181A4, .zunpckldq 29 30 31, 0x181AA),
  (0x181AA, .zunpckhdq 30 30 31, 0x181B0),
  (0x181B0, .zunpcklqdq 31 8 17, 0x181B6),
  (0x181B6, .zunpckhqdq 8 8 17, 0x181BC),
  (0x181BC, .zunpcklqdq 17 16 18, 0x181C2),
  (0x181C2, .zunpckhqdq 16 16 18, 0x181C8),
  (0x181C8, .zunpcklqdq 18 19 21, 0x181CE),
  (0x181CE, .zunpckhqdq 19 19 21, 0x181D4),
  (0x181D4, .zunpcklqdq 21 20 22, 0x181DA),
  (0x181DA, .zunpckhqdq 20 20 22, 0x181E0),
  (0x181E0, .zunpcklqdq 22 23 25, 0x181E6),
  (0x181E6, .zunpckhqdq 23 23 25, 0x181EC),
  (0x181EC, .zunpcklqdq 25 24 26, 0x181F2),
  (0x181F2, .zunpckhqdq 24 24 26, 0x181F8),
  (0x181F8, .zunpcklqdq 26 27 29, 0x181FE),
  (0x181FE, .zunpckhqdq 27 27 29, 0x18204),
  (0x18204, .zunpcklqdq 29 28 30, 0x1820A),
  (0x1820A, .zunpckhqdq 28 28 30, 0x18210),
  (0x18210, .zshufi32x4 30 31 18 136, 0x18217),
  (0x18217, .zshufi32x4 31 31 18 221, 0x1821E),
  (0x1821E, .zshufi32x4 18 17 21 136, 0x18225),
  (0x18225, .zshufi32x4 17 17 21 221, 0x1822C),
  (0x1822C, .zshufi32x4 21 8 19 136, 0x18233),
  (0x18233, .zshufi32x4 8 8 19 221, 0x1823A),
  (0x1823A, .zshufi32x4 19 16 20 136, 0x18241),
  (0x18241, .zshufi32x4 16 16 20 221, 0x18248),
  (0x18248, .zshufi32x4 20 22 26 136, 0x1824F),
  (0x1824F, .zshufi32x4 22 22 26 221, 0x18256),
  (0x18256, .zshufi32x4 26 25 29 136, 0x1825D),
  (0x1825D, .zshufi32x4 25 25 29 221, 0x18264),
  (0x18264, .zshufi32x4 29 23 27 136, 0x1826B),
  (0x1826B, .zshufi32x4 23 23 27 221, 0x18272),
  (0x18272, .zshufi32x4 27 24 28 136, 0x18279),
  (0x18279, .zshufi32x4 24 24 28 221, 0x18280),
  (0x18280, .zshufi32x4 28 30 20 136, 0x18287),
  (0x18287, .zshufi32x4 30 30 20 221, 0x1828E),
  (0x1828E, .zshufi32x4 20 18 26 136, 0x18295),
  (0x18295, .zshufi32x4 18 18 26 221, 0x1829C),
  (0x1829C, .zshufi32x4 26 21 29 136, 0x182A3),
  (0x182A3, .zshufi32x4 21 21 29 221, 0x182AA),
  (0x182AA, .zshufi32x4 29 19 27 136, 0x182B1),
  (0x182B1, .zshufi32x4 19 19 27 221, 0x182B8),
  (0x182B8, .zshufi32x4 27 31 22 136, 0x182BF),
  (0x182BF, .zshufi32x4 31 31 22 221, 0x182C6),
  (0x182C6, .zshufi32x4 22 17 25 136, 0x182CD),
  (0x182CD, .zshufi32x4 17 17 25 221, 0x182D4),
  (0x182D4, .zshufi32x4 25 8 23 136, 0x182DB),
  (0x182DB, .zshufi32x4 8 8 23 221, 0x182E2),
  (0x182E2, .zshufi32x4 23 16 24 136, 0x182E9),
  (0x182E9, .zshufi32x4 16 16 24 221, 0x182F0),
  (0x182F0, .mov 32 (.reg .rax) (.reg .r10), 0x182F3),
  (0x182F3, .mov 32 (.reg .rdx) (.imm 0x40), 0x182F8),
  (0x182F8, .cmp 64 (.reg .r13) (.imm 0x1), 0x182FC),
  (0x182FC, .jne 0x18302, 0x182FE),
  (0x182FE, .or 32 (.reg .rax) (.reg .rdi), 0x18300),
  (0x18300, .mov 32 (.reg .rdx) (.reg .rsi), 0x18302),
  (0x18302, .zbroadcast 9 (.imm 0x6A09E667), 0x1830C),
  (0x1830C, .zbroadcast 10 (.imm 0xBB67AE85), 0x18316),
  (0x18316, .zbroadcast 11 (.imm 0x3C6EF372), 0x18320),
  (0x18320, .zbroadcast 12 (.imm 0xA54FF53A), 0x1832A),
  (0x1832A, .zbroadcast 13 (.reg .r9), 0x18330),
  (0x18330, .mov 64 (.reg .rcx) (.reg .r9), 0x18333),
  (0x18333, .shr64 .rcx 32, 0x18337),
  (0x18337, .zbroadcast 14 (.reg .rcx), 0x1833D),
  (0x1833D, .zbroadcast 15 (.reg .rdx), 0x18343),
  (0x18343, .zbroadcast 24 (.reg .rax), 0x18349),
  (0x18349, .mov 32 (.reg .r11) (.imm 0x7), 0x1834F),
  (0x1834F, .nop, 0x18359),
  (0x18359, .nop, 0x18360),
  (0x18360, .zpaddd 0 0 28, 0x18366),
  (0x18366, .zpaddd 1 1 20, 0x1836C),
  (0x1836C, .zpaddd 2 2 27, 0x18372),
  (0x18372, .zpaddd 3 3 22, 0x18378),
  (0x18378, .zpaddd 0 0 4, 0x1837E),
  (0x1837E, .zpaddd 1 1 5, 0x18384),
  (0x18384, .zpaddd 2 2 6, 0x1838A),
  (0x1838A, .zpaddd 3 3 7, 0x18390),
  (0x18390, .zpxord 13 13 0, 0x18396),
  (0x18396, .zpxord 14 14 1, 0x1839C),
  (0x1839C, .zpxord 15 15 2, 0x183A2),
  (0x183A2, .zpxord 24 24 3, 0x183A8),
  (0x183A8, .zprord 13 13 16, 0x183AF),
  (0x183AF, .zprord 14 14 16, 0x183B6),
  (0x183B6, .zprord 15 15 16, 0x183BD),
  (0x183BD, .zprord 24 24 16, 0x183C4),
  (0x183C4, .zpaddd 9 9 13, 0x183CA),
  (0x183CA, .zpaddd 10 10 14, 0x183D0),
  (0x183D0, .zpaddd 11 11 15, 0x183D6),
  (0x183D6, .zpaddd 12 12 24, 0x183DC),
  (0x183DC, .zpxord 4 4 9, 0x183E2),
  (0x183E2, .zpxord 5 5 10, 0x183E8),
  (0x183E8, .zpxord 6 6 11, 0x183EE),
  (0x183EE, .zpxord 7 7 12, 0x183F4),
  (0x183F4, .zprord 4 4 12, 0x183FB),
  (0x183FB, .zprord 5 5 12, 0x18402),
  (0x18402, .zprord 6 6 12, 0x18409),
  (0x18409, .zprord 7 7 12, 0x18410),
  (0x18410, .zpaddd 0 0 26, 0x18416),
  (0x18416, .zpaddd 1 1 29, 0x1841C),
  (0x1841C, .zpaddd 2 2 25, 0x18422),
  (0x18422, .zpaddd 3 3 23, 0x18428),
  (0x18428, .zpaddd 0 0 4, 0x1842E),
  (0x1842E, .zpaddd 1 1 5, 0x18434),
  (0x18434, .zpaddd 2 2 6, 0x1843A),
  (0x1843A, .zpaddd 3 3 7, 0x18440),
  (0x18440, .zpxord 13 13 0, 0x18446),
  (0x18446, .zpxord 14 14 1, 0x1844C),
  (0x1844C, .zpxord 15 15 2, 0x18452),
  (0x18452, .zpxord 24 24 3, 0x18458),
  (0x18458, .zprord 13 13 8, 0x1845F),
  (0x1845F, .zprord 14 14 8, 0x18466),
  (0x18466, .zprord 15 15 8, 0x1846D),
  (0x1846D, .zprord 24 24 8, 0x18474),
  (0x18474, .zpaddd 9 9 13, 0x1847A),
  (0x1847A, .zpaddd 10 10 14, 0x18480),
  (0x18480, .zpaddd 11 11 15, 0x18486),
  (0x18486, .zpaddd 12 12 24, 0x1848C),
  (0x1848C, .zpxord 4 4 9, 0x18492),
  (0x18492, .zpxord 5 5 10, 0x18498),
  (0x18498, .zpxord 6 6 11, 0x1849E),
  (0x1849E, .zpxord 7 7 12, 0x184A4),
  (0x184A4, .zprord 4 4 7, 0x184AB),
  (0x184AB, .zprord 5 5 7, 0x184B2),
  (0x184B2, .zprord 6 6 7, 0x184B9),
  (0x184B9, .zprord 7 7 7, 0x184C0),
  (0x184C0, .zpaddd 0 0 30, 0x184C6),
  (0x184C6, .zpaddd 1 1 18, 0x184CC),
  (0x184CC, .zpaddd 2 2 31, 0x184D2),
  (0x184D2, .zpaddd 3 3 17, 0x184D8),
  (0x184D8, .zpaddd 0 0 5, 0x184DE),
  (0x184DE, .zpaddd 1 1 6, 0x184E4),
  (0x184E4, .zpaddd 2 2 7, 0x184EA),
  (0x184EA, .zpaddd 3 3 4, 0x184F0),
  (0x184F0, .zpxord 24 24 0, 0x184F6),
  (0x184F6, .zpxord 13 13 1, 0x184FC),
  (0x184FC, .zpxord 14 14 2, 0x18502),
  (0x18502, .zpxord 15 15 3, 0x18508),
  (0x18508, .zprord 24 24 16, 0x1850F),
  (0x1850F, .zprord 13 13 16, 0x18516),
  (0x18516, .zprord 14 14 16, 0x1851D),
  (0x1851D, .zprord 15 15 16, 0x18524),
  (0x18524, .zpaddd 11 11 24, 0x1852A),
  (0x1852A, .zpaddd 12 12 13, 0x18530),
  (0x18530, .zpaddd 9 9 14, 0x18536),
  (0x18536, .zpaddd 10 10 15, 0x1853C),
  (0x1853C, .zpxord 5 5 11, 0x18542),
  (0x18542, .zpxord 6 6 12, 0x18548),
  (0x18548, .zpxord 7 7 9, 0x1854E),
  (0x1854E, .zpxord 4 4 10, 0x18554),
  (0x18554, .zprord 5 5 12, 0x1855B),
  (0x1855B, .zprord 6 6 12, 0x18562),
  (0x18562, .zprord 7 7 12, 0x18569),
  (0x18569, .zprord 4 4 12, 0x18570),
  (0x18570, .zpaddd 0 0 21, 0x18576),
  (0x18576, .zpaddd 1 1 19, 0x1857C),
  (0x1857C, .zpaddd 2 2 8, 0x18582),
  (0x18582, .zpaddd 3 3 16, 0x18588),
  (0x18588, .zpaddd 0 0 5, 0x1858E),
  (0x1858E, .zpaddd 1 1 6, 0x18594),
  (0x18594, .zpaddd 2 2 7, 0x1859A),
  (0x1859A, .zpaddd 3 3 4, 0x185A0),
  (0x185A0, .zpxord 24 24 0, 0x185A6),
  (0x185A6, .zpxord 13 13 1, 0x185AC),
  (0x185AC, .zpxord 14 14 2, 0x185B2),
  (0x185B2, .zpxord 15 15 3, 0x185B8),
  (0x185B8, .zprord 24 24 8, 0x185BF),
  (0x185BF, .zprord 13 13 8, 0x185C6),
  (0x185C6, .zprord 14 14 8, 0x185CD),
  (0x185CD, .zprord 15 15 8, 0x185D4),
  (0x185D4, .zpaddd 11 11 24, 0x185DA),
  (0x185DA, .zpaddd 12 12 13, 0x185E0),
  (0x185E0, .zpaddd 9 9 14, 0x185E6),
  (0x185E6, .zpaddd 10 10 15, 0x185EC),
  (0x185EC, .zpxord 5 5 11, 0x185F2),
  (0x185F2, .zpxord 6 6 12, 0x185F8),
  (0x185F8, .zpxord 7 7 9, 0x185FE),
  (0x185FE, .zpxord 4 4 10, 0x18604),
  (0x18604, .zprord 5 5 7, 0x1860B),
  (0x1860B, .zprord 6 6 7, 0x18612),
  (0x18612, .zprord 7 7 7, 0x18619),
  (0x18619, .zprord 4 4 7, 0x18620),
  (0x18620, .dec32 .r11, 0x18623),
  (0x18623, .je 0x18977, 0x18629),
  (0x18629, .zpaddd 0 0 20, 0x1862F),
  (0x1862F, .zpaddd 1 1 29, 0x18635),
  (0x18635, .zpaddd 2 2 23, 0x1863B),
  (0x1863B, .zpaddd 3 3 27, 0x18641),
  (0x18641, .zpaddd 0 0 4, 0x18647),
  (0x18647, .zpaddd 1 1 5, 0x1864D),
  (0x1864D, .zpaddd 2 2 6, 0x18653),
  (0x18653, .zpaddd 3 3 7, 0x18659),
  (0x18659, .zpxord 13 13 0, 0x1865F),
  (0x1865F, .zpxord 14 14 1, 0x18665),
  (0x18665, .zpxord 15 15 2, 0x1866B),
  (0x1866B, .zpxord 24 24 3, 0x18671),
  (0x18671, .zprord 13 13 16, 0x18678),
  (0x18678, .zprord 14 14 16, 0x1867F),
  (0x1867F, .zprord 15 15 16, 0x18686),
  (0x18686, .zprord 24 24 16, 0x1868D),
  (0x1868D, .zpaddd 9 9 13, 0x18693),
  (0x18693, .zpaddd 10 10 14, 0x18699),
  (0x18699, .zpaddd 11 11 15, 0x1869F),
  (0x1869F, .zpaddd 12 12 24, 0x186A5),
  (0x186A5, .zpxord 4 4 9, 0x186AB),
  (0x186AB, .zpxord 5 5 10, 0x186B1),
  (0x186B1, .zpxord 6 6 11, 0x186B7),
  (0x186B7, .zpxord 7 7 12, 0x186BD),
  (0x186BD, .zprord 4 4 12, 0x186C4),
  (0x186C4, .zprord 5 5 12, 0x186CB),
  (0x186CB, .zprord 6 6 12, 0x186D2),
  (0x186D2, .zprord 7 7 12, 0x186D9),
  (0x186D9, .zpaddd 0 0 22, 0x186DF),
  (0x186DF, .zpaddd 1 1 18, 0x186E5),
  (0x186E5, .zpaddd 2 2 28, 0x186EB),
  (0x186EB, .zpaddd 3 3 8, 0x186F1),
  (0x186F1, .zpaddd 0 0 4, 0x186F7),
  (0x186F7, .zpaddd 1 1 5, 0x186FD),
  (0x186FD, .zpaddd 2 2 6, 0x18703),
  (0x18703, .zpaddd 3 3 7, 0x18709),
  (0x18709, .zpxord 13 13 0, 0x1870F),
  (0x1870F, .zpxord 14 14 1, 0x18715),
  (0x18715, .zpxord 15 15 2, 0x1871B),
  (0x1871B, .zpxord 24 24 3, 0x18721),
  (0x18721, .zprord 13 13 8, 0x18728),
  (0x18728, .zprord 14 14 8, 0x1872F),
  (0x1872F, .zprord 15 15 8, 0x18736),
  (0x18736, .zprord 24 24 8, 0x1873D),
  (0x1873D, .zpaddd 9 9 13, 0x18743),
  (0x18743, .zpaddd 10 10 14, 0x18749),
  (0x18749, .zpaddd 11 11 15, 0x1874F),
  (0x1874F, .zpaddd 12 12 24, 0x18755),
  (0x18755, .zpxord 4 4 9, 0x1875B),
  (0x1875B, .zpxord 5 5 10, 0x18761),
  (0x18761, .zpxord 6 6 11, 0x18767),
  (0x18767, .zpxord 7 7 12, 0x1876D),
  (0x1876D, .zprord 4 4 7, 0x18774),
  (0x18774, .zprord 5 5 7, 0x1877B),
  (0x1877B, .zprord 6 6 7, 0x18782),
  (0x18782, .zprord 7 7 7, 0x18789),
  (0x18789, .zpaddd 0 0 26, 0x1878F),
  (0x1878F, .zpaddd 1 1 31, 0x18795),
  (0x18795, .zpaddd 2 2 21, 0x1879B),
  (0x1879B, .zpaddd 3 3 16, 0x187A1),
  (0x187A1, .zpaddd 0 0 5, 0x187A7),
  (0x187A7, .zpaddd 1 1 6, 0x187AD),
  (0x187AD, .zpaddd 2 2 7, 0x187B3),
  (0x187B3, .zpaddd 3 3 4, 0x187B9),
  (0x187B9, .zpxord 24 24 0, 0x187BF),
  (0x187BF, .zpxord 13 13 1, 0x187C5),
  (0x187C5, .zpxord 14 14 2, 0x187CB),
  (0x187CB, .zpxord 15 15 3, 0x187D1),
  (0x187D1, .zprord 24 24 16, 0x187D8),
  (0x187D8, .zprord 13 13 16, 0x187DF),
  (0x187DF, .zprord 14 14 16, 0x187E6),
  (0x187E6, .zprord 15 15 16, 0x187ED),
  (0x187ED, .zpaddd 11 11 24, 0x187F3),
  (0x187F3, .zpaddd 12 12 13, 0x187F9),
  (0x187F9, .zpaddd 9 9 14, 0x187FF),
  (0x187FF, .zpaddd 10 10 15, 0x18805),
  (0x18805, .zpxord 5 5 11, 0x1880B),
  (0x1880B, .zpxord 6 6 12, 0x18811),
  (0x18811, .zpxord 7 7 9, 0x18817),
  (0x18817, .zpxord 4 4 10, 0x1881D),
  (0x1881D, .zprord 5 5 12, 0x18824),
  (0x18824, .zprord 6 6 12, 0x1882B),
  (0x1882B, .zprord 7 7 12, 0x18832),
  (0x18832, .zprord 4 4 12, 0x18839),
  (0x18839, .zpaddd 0 0 19, 0x1883F),
  (0x1883F, .zpaddd 1 1 25, 0x18845),
  (0x18845, .zpaddd 2 2 17, 0x1884B),
  (0x1884B, .zpaddd 3 3 30, 0x18851),
  (0x18851, .zpaddd 0 0 5, 0x18857),
  (0x18857, .zpaddd 1 1 6, 0x1885D),
  (0x1885D, .zpaddd 2 2 7, 0x18863),
  (0x18863, .zpaddd 3 3 4, 0x18869),
  (0x18869, .zpxord 24 24 0, 0x1886F),
  (0x1886F, .zpxord 13 13 1, 0x18875),
  (0x18875, .zpxord 14 14 2, 0x1887B),
  (0x1887B, .zpxord 15 15 3, 0x18881),
  (0x18881, .zprord 24 24 8, 0x18888),
  (0x18888, .zprord 13 13 8, 0x1888F),
  (0x1888F, .zprord 14 14 8, 0x18896),
  (0x18896, .zprord 15 15 8, 0x1889D),
  (0x1889D, .zpaddd 11 11 24, 0x188A3),
  (0x188A3, .zpaddd 12 12 13, 0x188A9),
  (0x188A9, .zpaddd 9 9 14, 0x188AF),
  (0x188AF, .zpaddd 10 10 15, 0x188B5),
  (0x188B5, .zpxord 5 5 11, 0x188BB),
  (0x188BB, .zpxord 6 6 12, 0x188C1),
  (0x188C1, .zpxord 7 7 9, 0x188C7),
  (0x188C7, .zpxord 4 4 10, 0x188CD),
  (0x188CD, .zprord 5 5 7, 0x188D4),
  (0x188D4, .zprord 6 6 7, 0x188DB),
  (0x188DB, .zprord 7 7 7, 0x188E2),
  (0x188E2, .zprord 4 4 7, 0x188E9),
  (0x188E9, .dec32 .r11, 0x188EC),
  (0x188EC, .zstore true .rsp 0x0 28, 0x188F3),
  (0x188F3, .zmov 28 29, 0x188F9),
  (0x188F9, .zmov 29 31, 0x188FF),
  (0x188FF, .zmov 31 19, 0x18905),
  (0x18905, .zload true 19 .rsp 0x0, 0x1890C),
  (0x1890C, .zstore true .rsp 0x40 26, 0x18914),
  (0x18914, .zmov 26 27, 0x1891A),
  (0x1891A, .zmov 27 8, 0x18920),
  (0x18920, .zmov 8 16, 0x18926),
  (0x18926, .zload true 16 .rsp 0x40, 0x1892E),
  (0x1892E, .zstore true .rsp 0x80 20, 0x18936),
  (0x18936, .zmov 20 18, 0x1893C),
  (0x1893C, .zmov 18 21, 0x18942),
  (0x18942, .zmov 21 25, 0x18948),
  (0x18948, .zload true 25 .rsp 0x80, 0x18950),
  (0x18950, .zstore true .rsp 0xC0 22, 0x18958),
  (0x18958, .zmov 22 23, 0x1895E),
  (0x1895E, .zmov 23 17, 0x18964),
  (0x18964, .zmov 17 30, 0x1896A),
  (0x1896A, .zload true 30 .rsp 0xC0, 0x18972),
  (0x18972, .jmp 0x18360, 0x18977),
  (0x18977, .zpxord 0 0 9, 0x1897D),
  (0x1897D, .zpxord 1 1 10, 0x18983),
  (0x18983, .zpxord 2 2 11, 0x18989),
  (0x18989, .zpxord 3 3 12, 0x1898F),
  (0x1898F, .zpxord 4 4 13, 0x18995),
  (0x18995, .zpxord 5 5 14, 0x1899B),
  (0x1899B, .zpxord 6 6 15, 0x189A1),
  (0x189A1, .zpxord 7 7 24, 0x189A7),
  (0x189A7, .mov 32 (.reg .r10) (.reg .r8), 0x189AA),
  (0x189AA, .add 64 (.reg .r14) (.imm 0x40), 0x189AE),
  (0x189AE, .dec64 .r13, 0x189B1),
  (0x189B1, .jne 0x18091, 0x189B7),
  (0x189B7, .zunpckldq 16 0 1, 0x189BD),
  (0x189BD, .zunpckhdq 0 0 1, 0x189C3),
  (0x189C3, .zunpckldq 1 2 3, 0x189C9),
  (0x189C9, .zunpckhdq 2 2 3, 0x189CF),
  (0x189CF, .zunpckldq 3 4 5, 0x189D5),
  (0x189D5, .zunpckhdq 4 4 5, 0x189DB),
  (0x189DB, .zunpckldq 5 6 7, 0x189E1),
  (0x189E1, .zunpckhdq 6 6 7, 0x189E7),
  (0x189E7, .zunpcklqdq 7 16 1, 0x189ED),
  (0x189ED, .zunpckhqdq 16 16 1, 0x189F3),
  (0x189F3, .zunpcklqdq 1 0 2, 0x189F9),
  (0x189F9, .zunpckhqdq 0 0 2, 0x189FF),
  (0x189FF, .zunpcklqdq 2 3 5, 0x18A05),
  (0x18A05, .zunpckhqdq 3 3 5, 0x18A0B),
  (0x18A0B, .zunpcklqdq 5 4 6, 0x18A11),
  (0x18A11, .zunpckhqdq 4 4 6, 0x18A17),
  (0x18A17, .zshufi32x4 6 7 2 136, 0x18A1E),
  (0x18A1E, .zshufi32x4 7 7 2 221, 0x18A25),
  (0x18A25, .zshufi32x4 2 1 5 136, 0x18A2C),
  (0x18A2C, .zshufi32x4 1 1 5 221, 0x18A33),
  (0x18A33, .zshufi32x4 5 16 3 136, 0x18A3A),
  (0x18A3A, .zshufi32x4 16 16 3 221, 0x18A41),
  (0x18A41, .zshufi32x4 3 0 4 136, 0x18A48),
  (0x18A48, .zshufi32x4 0 0 4 221, 0x18A4F),
  (0x18A4F, .zshufi32x4 4 6 5 136, 0x18A56),
  (0x18A56, .zstore false .r15 0x0 4, 0x18A5C),
  (0x18A5C, .zshufi32x4 4 2 3 136, 0x18A63),
  (0x18A63, .zstore false .r15 0x40 4, 0x18A6A),
  (0x18A6A, .zshufi32x4 4 7 16 136, 0x18A71),
  (0x18A71, .zstore false .r15 0x80 4, 0x18A78),
  (0x18A78, .zshufi32x4 4 1 0 136, 0x18A7F),
  (0x18A7F, .zstore false .r15 0xC0 4, 0x18A86),
  (0x18A86, .zshufi32x4 4 6 5 221, 0x18A8D),
  (0x18A8D, .zstore false .r15 0x100 4, 0x18A94),
  (0x18A94, .zshufi32x4 4 2 3 221, 0x18A9B),
  (0x18A9B, .zstore false .r15 0x140 4, 0x18AA2),
  (0x18AA2, .zshufi32x4 4 7 16 221, 0x18AA9),
  (0x18AA9, .zstore false .r15 0x180 4, 0x18AB0),
  (0x18AB0, .zshufi32x4 4 1 0 221, 0x18AB7),
  (0x18AB7, .zstore false .r15 0x1C0 4, 0x18ABE),
  (0x18ABE, .vzeroupper, 0x18AC1),
  (0x18AC1, .lea .rsp .rbp 0xFFFFFFFFFFFFFFD8, 0x18AC5),
  (0x18AC5, .pop .r15, 0x18AC7),
  (0x18AC7, .pop .r14, 0x18AC9),
  (0x18AC9, .pop .r13, 0x18ACB),
  (0x18ACB, .pop .r12, 0x18ACD),
  (0x18ACD, .pop .rbx, 0x18ACE),
  (0x18ACE, .pop .rbp, 0x18ACF),
  (0x18ACF, .ret, 0x18AD0)
]

/-- Every instruction of the program: this function's (it calls nothing). -/
def whole : List (Nat × Instr × Nat) := table

def prog (pc : Nat) : Option (Instr × Nat) := whole.lookup pc

/-- The addresses the program has an instruction at. -/
def keys : List Nat := whole.map (·.1)

theorem keys_of : ∀ pc x, prog pc = some x → pc ∈ keys := fun pc x h => lookup_mem_keys whole pc x h

@[ode_at] theorem at_18000 : prog 0x18000 = some (.nop, 0x18004) := rfl
@[ode_at] theorem at_18004 : prog 0x18004 = some (.push .rbp, 0x18005) := rfl
@[ode_at] theorem at_18005 : prog 0x18005 = some (.mov 64 (.reg .rbp) (.reg .rsp), 0x18008) := rfl
@[ode_at] theorem at_18008 : prog 0x18008 = some (.push .rbx, 0x18009) := rfl
@[ode_at] theorem at_18009 : prog 0x18009 = some (.push .r12, 0x1800B) := rfl
@[ode_at] theorem at_1800B : prog 0x1800B = some (.push .r13, 0x1800D) := rfl
@[ode_at] theorem at_1800D : prog 0x1800D = some (.push .r14, 0x1800F) := rfl
@[ode_at] theorem at_1800F : prog 0x1800F = some (.push .r15, 0x18011) := rfl
@[ode_at] theorem at_18011 : prog 0x18011 = some (.and 64 (.reg .rsp) (.imm 0xFFFFFFFFFFFFFFC0), 0x18015) := rfl
@[ode_at] theorem at_18015 : prog 0x18015 = some (.sub 64 (.reg .rsp) (.imm 0x100), 0x1801C) := rfl
@[ode_at] theorem at_1801C : prog 0x1801C = some (.mov 8 (.mem .rsp 0x0) (.imm 0x0), 0x18020) := rfl
@[ode_at] theorem at_18020 : prog 0x18020 = some (.mov 64 (.reg .r12) (.reg .rdi), 0x18023) := rfl
@[ode_at] theorem at_18023 : prog 0x18023 = some (.mov 64 (.reg .r13) (.reg .rsi), 0x18026) := rfl
@[ode_at] theorem at_18026 : prog 0x18026 = some (.mov 64 (.reg .r14) (.reg .rdx), 0x18029) := rfl
@[ode_at] theorem at_18029 : prog 0x18029 = some (.mov 64 (.reg .r15) (.reg .r9), 0x1802C) := rfl
@[ode_at] theorem at_1802C : prog 0x1802C = some (.mov 64 (.reg .rbx) (.reg .r8), 0x1802F) := rfl
@[ode_at] theorem at_1802F : prog 0x1802F = some (.mov 64 (.reg .r9) (.reg .rcx), 0x18032) := rfl
@[ode_at] theorem at_18032 : prog 0x18032 = some (.zbroadcast 0 (.mem .r14 0x0), 0x18038) := rfl
@[ode_at] theorem at_18038 : prog 0x18038 = some (.zbroadcast 1 (.mem .r14 0x4), 0x1803F) := rfl
@[ode_at] theorem at_1803F : prog 0x1803F = some (.zbroadcast 2 (.mem .r14 0x8), 0x18046) := rfl
@[ode_at] theorem at_18046 : prog 0x18046 = some (.zbroadcast 3 (.mem .r14 0xC), 0x1804D) := rfl
@[ode_at] theorem at_1804D : prog 0x1804D = some (.zbroadcast 4 (.mem .r14 0x10), 0x18054) := rfl
@[ode_at] theorem at_18054 : prog 0x18054 = some (.zbroadcast 5 (.mem .r14 0x14), 0x1805B) := rfl
@[ode_at] theorem at_1805B : prog 0x1805B = some (.zbroadcast 6 (.mem .r14 0x18), 0x18062) := rfl
@[ode_at] theorem at_18062 : prog 0x18062 = some (.zbroadcast 7 (.mem .r14 0x1C), 0x18069) := rfl
@[ode_at] theorem at_18069 : prog 0x18069 = some (.xor 32 (.reg .r14) (.reg .r14), 0x1806C) := rfl
@[ode_at] theorem at_1806C : prog 0x1806C = some (.movzx8 .r8 (.reg .rbx), 0x18070) := rfl
@[ode_at] theorem at_18070 : prog 0x18070 = some (.mov 32 (.reg .r10) (.reg .rbx), 0x18073) := rfl
@[ode_at] theorem at_18073 : prog 0x18073 = some (.shr32 .r10 8, 0x18077) := rfl
@[ode_at] theorem at_18077 : prog 0x18077 = some (.and 32 (.reg .r10) (.imm 0xFF), 0x1807E) := rfl
@[ode_at] theorem at_1807E : prog 0x1807E = some (.or 32 (.reg .r10) (.reg .r8), 0x18081) := rfl
@[ode_at] theorem at_18081 : prog 0x18081 = some (.mov 32 (.reg .rdi) (.reg .rbx), 0x18083) := rfl
@[ode_at] theorem at_18083 : prog 0x18083 = some (.shr32 .rdi 16, 0x18086) := rfl
@[ode_at] theorem at_18086 : prog 0x18086 = some (.and 32 (.reg .rdi) (.imm 0xFF), 0x1808C) := rfl
@[ode_at] theorem at_1808C : prog 0x1808C = some (.mov 32 (.reg .rsi) (.reg .rbx), 0x1808E) := rfl
@[ode_at] theorem at_1808E : prog 0x1808E = some (.shr32 .rsi 24, 0x18091) := rfl
@[ode_at] theorem at_18091 : prog 0x18091 = some (.mov 64 (.reg .rax) (.mem .r12 0x0), 0x18095) := rfl
@[ode_at] theorem at_18095 : prog 0x18095 = some (.zloadi 16 .rax .r14 0x0, 0x1809C) := rfl
@[ode_at] theorem at_1809C : prog 0x1809C = some (.mov 64 (.reg .rax) (.mem .r12 0x8), 0x180A1) := rfl
@[ode_at] theorem at_180A1 : prog 0x180A1 = some (.zloadi 17 .rax .r14 0x0, 0x180A8) := rfl
@[ode_at] theorem at_180A8 : prog 0x180A8 = some (.mov 64 (.reg .rax) (.mem .r12 0x10), 0x180AD) := rfl
@[ode_at] theorem at_180AD : prog 0x180AD = some (.zloadi 18 .rax .r14 0x0, 0x180B4) := rfl
@[ode_at] theorem at_180B4 : prog 0x180B4 = some (.mov 64 (.reg .rax) (.mem .r12 0x18), 0x180B9) := rfl
@[ode_at] theorem at_180B9 : prog 0x180B9 = some (.zloadi 19 .rax .r14 0x0, 0x180C0) := rfl
@[ode_at] theorem at_180C0 : prog 0x180C0 = some (.mov 64 (.reg .rax) (.mem .r12 0x20), 0x180C5) := rfl
@[ode_at] theorem at_180C5 : prog 0x180C5 = some (.zloadi 20 .rax .r14 0x0, 0x180CC) := rfl
@[ode_at] theorem at_180CC : prog 0x180CC = some (.mov 64 (.reg .rax) (.mem .r12 0x28), 0x180D1) := rfl
@[ode_at] theorem at_180D1 : prog 0x180D1 = some (.zloadi 21 .rax .r14 0x0, 0x180D8) := rfl
@[ode_at] theorem at_180D8 : prog 0x180D8 = some (.mov 64 (.reg .rax) (.mem .r12 0x30), 0x180DD) := rfl
@[ode_at] theorem at_180DD : prog 0x180DD = some (.zloadi 22 .rax .r14 0x0, 0x180E4) := rfl
@[ode_at] theorem at_180E4 : prog 0x180E4 = some (.mov 64 (.reg .rax) (.mem .r12 0x38), 0x180E9) := rfl
@[ode_at] theorem at_180E9 : prog 0x180E9 = some (.zloadi 23 .rax .r14 0x0, 0x180F0) := rfl
@[ode_at] theorem at_180F0 : prog 0x180F0 = some (.mov 64 (.reg .rax) (.mem .r12 0x40), 0x180F5) := rfl
@[ode_at] theorem at_180F5 : prog 0x180F5 = some (.zloadi 24 .rax .r14 0x0, 0x180FC) := rfl
@[ode_at] theorem at_180FC : prog 0x180FC = some (.mov 64 (.reg .rax) (.mem .r12 0x48), 0x18101) := rfl
@[ode_at] theorem at_18101 : prog 0x18101 = some (.zloadi 25 .rax .r14 0x0, 0x18108) := rfl
@[ode_at] theorem at_18108 : prog 0x18108 = some (.mov 64 (.reg .rax) (.mem .r12 0x50), 0x1810D) := rfl
@[ode_at] theorem at_1810D : prog 0x1810D = some (.zloadi 26 .rax .r14 0x0, 0x18114) := rfl
@[ode_at] theorem at_18114 : prog 0x18114 = some (.mov 64 (.reg .rax) (.mem .r12 0x58), 0x18119) := rfl
@[ode_at] theorem at_18119 : prog 0x18119 = some (.zloadi 27 .rax .r14 0x0, 0x18120) := rfl
@[ode_at] theorem at_18120 : prog 0x18120 = some (.mov 64 (.reg .rax) (.mem .r12 0x60), 0x18125) := rfl
@[ode_at] theorem at_18125 : prog 0x18125 = some (.zloadi 28 .rax .r14 0x0, 0x1812C) := rfl
@[ode_at] theorem at_1812C : prog 0x1812C = some (.mov 64 (.reg .rax) (.mem .r12 0x68), 0x18131) := rfl
@[ode_at] theorem at_18131 : prog 0x18131 = some (.zloadi 29 .rax .r14 0x0, 0x18138) := rfl
@[ode_at] theorem at_18138 : prog 0x18138 = some (.mov 64 (.reg .rax) (.mem .r12 0x70), 0x1813D) := rfl
@[ode_at] theorem at_1813D : prog 0x1813D = some (.zloadi 30 .rax .r14 0x0, 0x18144) := rfl
@[ode_at] theorem at_18144 : prog 0x18144 = some (.mov 64 (.reg .rax) (.mem .r12 0x78), 0x18149) := rfl
@[ode_at] theorem at_18149 : prog 0x18149 = some (.zloadi 31 .rax .r14 0x0, 0x18150) := rfl
@[ode_at] theorem at_18150 : prog 0x18150 = some (.zunpckldq 8 16 17, 0x18156) := rfl
@[ode_at] theorem at_18156 : prog 0x18156 = some (.zunpckhdq 16 16 17, 0x1815C) := rfl
@[ode_at] theorem at_1815C : prog 0x1815C = some (.zunpckldq 17 18 19, 0x18162) := rfl
@[ode_at] theorem at_18162 : prog 0x18162 = some (.zunpckhdq 18 18 19, 0x18168) := rfl
@[ode_at] theorem at_18168 : prog 0x18168 = some (.zunpckldq 19 20 21, 0x1816E) := rfl
@[ode_at] theorem at_1816E : prog 0x1816E = some (.zunpckhdq 20 20 21, 0x18174) := rfl
@[ode_at] theorem at_18174 : prog 0x18174 = some (.zunpckldq 21 22 23, 0x1817A) := rfl
@[ode_at] theorem at_1817A : prog 0x1817A = some (.zunpckhdq 22 22 23, 0x18180) := rfl
@[ode_at] theorem at_18180 : prog 0x18180 = some (.zunpckldq 23 24 25, 0x18186) := rfl
@[ode_at] theorem at_18186 : prog 0x18186 = some (.zunpckhdq 24 24 25, 0x1818C) := rfl
@[ode_at] theorem at_1818C : prog 0x1818C = some (.zunpckldq 25 26 27, 0x18192) := rfl
@[ode_at] theorem at_18192 : prog 0x18192 = some (.zunpckhdq 26 26 27, 0x18198) := rfl
@[ode_at] theorem at_18198 : prog 0x18198 = some (.zunpckldq 27 28 29, 0x1819E) := rfl
@[ode_at] theorem at_1819E : prog 0x1819E = some (.zunpckhdq 28 28 29, 0x181A4) := rfl
@[ode_at] theorem at_181A4 : prog 0x181A4 = some (.zunpckldq 29 30 31, 0x181AA) := rfl
@[ode_at] theorem at_181AA : prog 0x181AA = some (.zunpckhdq 30 30 31, 0x181B0) := rfl
@[ode_at] theorem at_181B0 : prog 0x181B0 = some (.zunpcklqdq 31 8 17, 0x181B6) := rfl
@[ode_at] theorem at_181B6 : prog 0x181B6 = some (.zunpckhqdq 8 8 17, 0x181BC) := rfl
@[ode_at] theorem at_181BC : prog 0x181BC = some (.zunpcklqdq 17 16 18, 0x181C2) := rfl
@[ode_at] theorem at_181C2 : prog 0x181C2 = some (.zunpckhqdq 16 16 18, 0x181C8) := rfl
@[ode_at] theorem at_181C8 : prog 0x181C8 = some (.zunpcklqdq 18 19 21, 0x181CE) := rfl
@[ode_at] theorem at_181CE : prog 0x181CE = some (.zunpckhqdq 19 19 21, 0x181D4) := rfl
@[ode_at] theorem at_181D4 : prog 0x181D4 = some (.zunpcklqdq 21 20 22, 0x181DA) := rfl
@[ode_at] theorem at_181DA : prog 0x181DA = some (.zunpckhqdq 20 20 22, 0x181E0) := rfl
@[ode_at] theorem at_181E0 : prog 0x181E0 = some (.zunpcklqdq 22 23 25, 0x181E6) := rfl
@[ode_at] theorem at_181E6 : prog 0x181E6 = some (.zunpckhqdq 23 23 25, 0x181EC) := rfl
@[ode_at] theorem at_181EC : prog 0x181EC = some (.zunpcklqdq 25 24 26, 0x181F2) := rfl
@[ode_at] theorem at_181F2 : prog 0x181F2 = some (.zunpckhqdq 24 24 26, 0x181F8) := rfl
@[ode_at] theorem at_181F8 : prog 0x181F8 = some (.zunpcklqdq 26 27 29, 0x181FE) := rfl
@[ode_at] theorem at_181FE : prog 0x181FE = some (.zunpckhqdq 27 27 29, 0x18204) := rfl
@[ode_at] theorem at_18204 : prog 0x18204 = some (.zunpcklqdq 29 28 30, 0x1820A) := rfl
@[ode_at] theorem at_1820A : prog 0x1820A = some (.zunpckhqdq 28 28 30, 0x18210) := rfl
@[ode_at] theorem at_18210 : prog 0x18210 = some (.zshufi32x4 30 31 18 136, 0x18217) := rfl
@[ode_at] theorem at_18217 : prog 0x18217 = some (.zshufi32x4 31 31 18 221, 0x1821E) := rfl
@[ode_at] theorem at_1821E : prog 0x1821E = some (.zshufi32x4 18 17 21 136, 0x18225) := rfl
@[ode_at] theorem at_18225 : prog 0x18225 = some (.zshufi32x4 17 17 21 221, 0x1822C) := rfl
@[ode_at] theorem at_1822C : prog 0x1822C = some (.zshufi32x4 21 8 19 136, 0x18233) := rfl
@[ode_at] theorem at_18233 : prog 0x18233 = some (.zshufi32x4 8 8 19 221, 0x1823A) := rfl
@[ode_at] theorem at_1823A : prog 0x1823A = some (.zshufi32x4 19 16 20 136, 0x18241) := rfl
@[ode_at] theorem at_18241 : prog 0x18241 = some (.zshufi32x4 16 16 20 221, 0x18248) := rfl
@[ode_at] theorem at_18248 : prog 0x18248 = some (.zshufi32x4 20 22 26 136, 0x1824F) := rfl
@[ode_at] theorem at_1824F : prog 0x1824F = some (.zshufi32x4 22 22 26 221, 0x18256) := rfl
@[ode_at] theorem at_18256 : prog 0x18256 = some (.zshufi32x4 26 25 29 136, 0x1825D) := rfl
@[ode_at] theorem at_1825D : prog 0x1825D = some (.zshufi32x4 25 25 29 221, 0x18264) := rfl
@[ode_at] theorem at_18264 : prog 0x18264 = some (.zshufi32x4 29 23 27 136, 0x1826B) := rfl
@[ode_at] theorem at_1826B : prog 0x1826B = some (.zshufi32x4 23 23 27 221, 0x18272) := rfl
@[ode_at] theorem at_18272 : prog 0x18272 = some (.zshufi32x4 27 24 28 136, 0x18279) := rfl
@[ode_at] theorem at_18279 : prog 0x18279 = some (.zshufi32x4 24 24 28 221, 0x18280) := rfl
@[ode_at] theorem at_18280 : prog 0x18280 = some (.zshufi32x4 28 30 20 136, 0x18287) := rfl
@[ode_at] theorem at_18287 : prog 0x18287 = some (.zshufi32x4 30 30 20 221, 0x1828E) := rfl
@[ode_at] theorem at_1828E : prog 0x1828E = some (.zshufi32x4 20 18 26 136, 0x18295) := rfl
@[ode_at] theorem at_18295 : prog 0x18295 = some (.zshufi32x4 18 18 26 221, 0x1829C) := rfl
@[ode_at] theorem at_1829C : prog 0x1829C = some (.zshufi32x4 26 21 29 136, 0x182A3) := rfl
@[ode_at] theorem at_182A3 : prog 0x182A3 = some (.zshufi32x4 21 21 29 221, 0x182AA) := rfl
@[ode_at] theorem at_182AA : prog 0x182AA = some (.zshufi32x4 29 19 27 136, 0x182B1) := rfl
@[ode_at] theorem at_182B1 : prog 0x182B1 = some (.zshufi32x4 19 19 27 221, 0x182B8) := rfl
@[ode_at] theorem at_182B8 : prog 0x182B8 = some (.zshufi32x4 27 31 22 136, 0x182BF) := rfl
@[ode_at] theorem at_182BF : prog 0x182BF = some (.zshufi32x4 31 31 22 221, 0x182C6) := rfl
@[ode_at] theorem at_182C6 : prog 0x182C6 = some (.zshufi32x4 22 17 25 136, 0x182CD) := rfl
@[ode_at] theorem at_182CD : prog 0x182CD = some (.zshufi32x4 17 17 25 221, 0x182D4) := rfl
@[ode_at] theorem at_182D4 : prog 0x182D4 = some (.zshufi32x4 25 8 23 136, 0x182DB) := rfl
@[ode_at] theorem at_182DB : prog 0x182DB = some (.zshufi32x4 8 8 23 221, 0x182E2) := rfl
@[ode_at] theorem at_182E2 : prog 0x182E2 = some (.zshufi32x4 23 16 24 136, 0x182E9) := rfl
@[ode_at] theorem at_182E9 : prog 0x182E9 = some (.zshufi32x4 16 16 24 221, 0x182F0) := rfl
@[ode_at] theorem at_182F0 : prog 0x182F0 = some (.mov 32 (.reg .rax) (.reg .r10), 0x182F3) := rfl
@[ode_at] theorem at_182F3 : prog 0x182F3 = some (.mov 32 (.reg .rdx) (.imm 0x40), 0x182F8) := rfl
@[ode_at] theorem at_182F8 : prog 0x182F8 = some (.cmp 64 (.reg .r13) (.imm 0x1), 0x182FC) := rfl
@[ode_at] theorem at_182FC : prog 0x182FC = some (.jne 0x18302, 0x182FE) := rfl
@[ode_at] theorem at_182FE : prog 0x182FE = some (.or 32 (.reg .rax) (.reg .rdi), 0x18300) := rfl
@[ode_at] theorem at_18300 : prog 0x18300 = some (.mov 32 (.reg .rdx) (.reg .rsi), 0x18302) := rfl
@[ode_at] theorem at_18302 : prog 0x18302 = some (.zbroadcast 9 (.imm 0x6A09E667), 0x1830C) := rfl
@[ode_at] theorem at_1830C : prog 0x1830C = some (.zbroadcast 10 (.imm 0xBB67AE85), 0x18316) := rfl
@[ode_at] theorem at_18316 : prog 0x18316 = some (.zbroadcast 11 (.imm 0x3C6EF372), 0x18320) := rfl
@[ode_at] theorem at_18320 : prog 0x18320 = some (.zbroadcast 12 (.imm 0xA54FF53A), 0x1832A) := rfl
@[ode_at] theorem at_1832A : prog 0x1832A = some (.zbroadcast 13 (.reg .r9), 0x18330) := rfl
@[ode_at] theorem at_18330 : prog 0x18330 = some (.mov 64 (.reg .rcx) (.reg .r9), 0x18333) := rfl
@[ode_at] theorem at_18333 : prog 0x18333 = some (.shr64 .rcx 32, 0x18337) := rfl
@[ode_at] theorem at_18337 : prog 0x18337 = some (.zbroadcast 14 (.reg .rcx), 0x1833D) := rfl
@[ode_at] theorem at_1833D : prog 0x1833D = some (.zbroadcast 15 (.reg .rdx), 0x18343) := rfl
@[ode_at] theorem at_18343 : prog 0x18343 = some (.zbroadcast 24 (.reg .rax), 0x18349) := rfl
@[ode_at] theorem at_18349 : prog 0x18349 = some (.mov 32 (.reg .r11) (.imm 0x7), 0x1834F) := rfl
@[ode_at] theorem at_1834F : prog 0x1834F = some (.nop, 0x18359) := rfl
@[ode_at] theorem at_18359 : prog 0x18359 = some (.nop, 0x18360) := rfl
@[ode_at] theorem at_18360 : prog 0x18360 = some (.zpaddd 0 0 28, 0x18366) := rfl
@[ode_at] theorem at_18366 : prog 0x18366 = some (.zpaddd 1 1 20, 0x1836C) := rfl
@[ode_at] theorem at_1836C : prog 0x1836C = some (.zpaddd 2 2 27, 0x18372) := rfl
@[ode_at] theorem at_18372 : prog 0x18372 = some (.zpaddd 3 3 22, 0x18378) := rfl
@[ode_at] theorem at_18378 : prog 0x18378 = some (.zpaddd 0 0 4, 0x1837E) := rfl
@[ode_at] theorem at_1837E : prog 0x1837E = some (.zpaddd 1 1 5, 0x18384) := rfl
@[ode_at] theorem at_18384 : prog 0x18384 = some (.zpaddd 2 2 6, 0x1838A) := rfl
@[ode_at] theorem at_1838A : prog 0x1838A = some (.zpaddd 3 3 7, 0x18390) := rfl
@[ode_at] theorem at_18390 : prog 0x18390 = some (.zpxord 13 13 0, 0x18396) := rfl
@[ode_at] theorem at_18396 : prog 0x18396 = some (.zpxord 14 14 1, 0x1839C) := rfl
@[ode_at] theorem at_1839C : prog 0x1839C = some (.zpxord 15 15 2, 0x183A2) := rfl
@[ode_at] theorem at_183A2 : prog 0x183A2 = some (.zpxord 24 24 3, 0x183A8) := rfl
@[ode_at] theorem at_183A8 : prog 0x183A8 = some (.zprord 13 13 16, 0x183AF) := rfl
@[ode_at] theorem at_183AF : prog 0x183AF = some (.zprord 14 14 16, 0x183B6) := rfl
@[ode_at] theorem at_183B6 : prog 0x183B6 = some (.zprord 15 15 16, 0x183BD) := rfl
@[ode_at] theorem at_183BD : prog 0x183BD = some (.zprord 24 24 16, 0x183C4) := rfl
@[ode_at] theorem at_183C4 : prog 0x183C4 = some (.zpaddd 9 9 13, 0x183CA) := rfl
@[ode_at] theorem at_183CA : prog 0x183CA = some (.zpaddd 10 10 14, 0x183D0) := rfl
@[ode_at] theorem at_183D0 : prog 0x183D0 = some (.zpaddd 11 11 15, 0x183D6) := rfl
@[ode_at] theorem at_183D6 : prog 0x183D6 = some (.zpaddd 12 12 24, 0x183DC) := rfl
@[ode_at] theorem at_183DC : prog 0x183DC = some (.zpxord 4 4 9, 0x183E2) := rfl
@[ode_at] theorem at_183E2 : prog 0x183E2 = some (.zpxord 5 5 10, 0x183E8) := rfl
@[ode_at] theorem at_183E8 : prog 0x183E8 = some (.zpxord 6 6 11, 0x183EE) := rfl
@[ode_at] theorem at_183EE : prog 0x183EE = some (.zpxord 7 7 12, 0x183F4) := rfl
@[ode_at] theorem at_183F4 : prog 0x183F4 = some (.zprord 4 4 12, 0x183FB) := rfl
@[ode_at] theorem at_183FB : prog 0x183FB = some (.zprord 5 5 12, 0x18402) := rfl
@[ode_at] theorem at_18402 : prog 0x18402 = some (.zprord 6 6 12, 0x18409) := rfl
@[ode_at] theorem at_18409 : prog 0x18409 = some (.zprord 7 7 12, 0x18410) := rfl
@[ode_at] theorem at_18410 : prog 0x18410 = some (.zpaddd 0 0 26, 0x18416) := rfl
@[ode_at] theorem at_18416 : prog 0x18416 = some (.zpaddd 1 1 29, 0x1841C) := rfl
@[ode_at] theorem at_1841C : prog 0x1841C = some (.zpaddd 2 2 25, 0x18422) := rfl
@[ode_at] theorem at_18422 : prog 0x18422 = some (.zpaddd 3 3 23, 0x18428) := rfl
@[ode_at] theorem at_18428 : prog 0x18428 = some (.zpaddd 0 0 4, 0x1842E) := rfl
@[ode_at] theorem at_1842E : prog 0x1842E = some (.zpaddd 1 1 5, 0x18434) := rfl
@[ode_at] theorem at_18434 : prog 0x18434 = some (.zpaddd 2 2 6, 0x1843A) := rfl
@[ode_at] theorem at_1843A : prog 0x1843A = some (.zpaddd 3 3 7, 0x18440) := rfl
@[ode_at] theorem at_18440 : prog 0x18440 = some (.zpxord 13 13 0, 0x18446) := rfl
@[ode_at] theorem at_18446 : prog 0x18446 = some (.zpxord 14 14 1, 0x1844C) := rfl
@[ode_at] theorem at_1844C : prog 0x1844C = some (.zpxord 15 15 2, 0x18452) := rfl
@[ode_at] theorem at_18452 : prog 0x18452 = some (.zpxord 24 24 3, 0x18458) := rfl
@[ode_at] theorem at_18458 : prog 0x18458 = some (.zprord 13 13 8, 0x1845F) := rfl
@[ode_at] theorem at_1845F : prog 0x1845F = some (.zprord 14 14 8, 0x18466) := rfl
@[ode_at] theorem at_18466 : prog 0x18466 = some (.zprord 15 15 8, 0x1846D) := rfl
@[ode_at] theorem at_1846D : prog 0x1846D = some (.zprord 24 24 8, 0x18474) := rfl
@[ode_at] theorem at_18474 : prog 0x18474 = some (.zpaddd 9 9 13, 0x1847A) := rfl
@[ode_at] theorem at_1847A : prog 0x1847A = some (.zpaddd 10 10 14, 0x18480) := rfl
@[ode_at] theorem at_18480 : prog 0x18480 = some (.zpaddd 11 11 15, 0x18486) := rfl
@[ode_at] theorem at_18486 : prog 0x18486 = some (.zpaddd 12 12 24, 0x1848C) := rfl
@[ode_at] theorem at_1848C : prog 0x1848C = some (.zpxord 4 4 9, 0x18492) := rfl
@[ode_at] theorem at_18492 : prog 0x18492 = some (.zpxord 5 5 10, 0x18498) := rfl
@[ode_at] theorem at_18498 : prog 0x18498 = some (.zpxord 6 6 11, 0x1849E) := rfl
@[ode_at] theorem at_1849E : prog 0x1849E = some (.zpxord 7 7 12, 0x184A4) := rfl
@[ode_at] theorem at_184A4 : prog 0x184A4 = some (.zprord 4 4 7, 0x184AB) := rfl
@[ode_at] theorem at_184AB : prog 0x184AB = some (.zprord 5 5 7, 0x184B2) := rfl
@[ode_at] theorem at_184B2 : prog 0x184B2 = some (.zprord 6 6 7, 0x184B9) := rfl
@[ode_at] theorem at_184B9 : prog 0x184B9 = some (.zprord 7 7 7, 0x184C0) := rfl
@[ode_at] theorem at_184C0 : prog 0x184C0 = some (.zpaddd 0 0 30, 0x184C6) := rfl
@[ode_at] theorem at_184C6 : prog 0x184C6 = some (.zpaddd 1 1 18, 0x184CC) := rfl
@[ode_at] theorem at_184CC : prog 0x184CC = some (.zpaddd 2 2 31, 0x184D2) := rfl
@[ode_at] theorem at_184D2 : prog 0x184D2 = some (.zpaddd 3 3 17, 0x184D8) := rfl
@[ode_at] theorem at_184D8 : prog 0x184D8 = some (.zpaddd 0 0 5, 0x184DE) := rfl
@[ode_at] theorem at_184DE : prog 0x184DE = some (.zpaddd 1 1 6, 0x184E4) := rfl
@[ode_at] theorem at_184E4 : prog 0x184E4 = some (.zpaddd 2 2 7, 0x184EA) := rfl
@[ode_at] theorem at_184EA : prog 0x184EA = some (.zpaddd 3 3 4, 0x184F0) := rfl
@[ode_at] theorem at_184F0 : prog 0x184F0 = some (.zpxord 24 24 0, 0x184F6) := rfl
@[ode_at] theorem at_184F6 : prog 0x184F6 = some (.zpxord 13 13 1, 0x184FC) := rfl
@[ode_at] theorem at_184FC : prog 0x184FC = some (.zpxord 14 14 2, 0x18502) := rfl
@[ode_at] theorem at_18502 : prog 0x18502 = some (.zpxord 15 15 3, 0x18508) := rfl
@[ode_at] theorem at_18508 : prog 0x18508 = some (.zprord 24 24 16, 0x1850F) := rfl
@[ode_at] theorem at_1850F : prog 0x1850F = some (.zprord 13 13 16, 0x18516) := rfl
@[ode_at] theorem at_18516 : prog 0x18516 = some (.zprord 14 14 16, 0x1851D) := rfl
@[ode_at] theorem at_1851D : prog 0x1851D = some (.zprord 15 15 16, 0x18524) := rfl
@[ode_at] theorem at_18524 : prog 0x18524 = some (.zpaddd 11 11 24, 0x1852A) := rfl
@[ode_at] theorem at_1852A : prog 0x1852A = some (.zpaddd 12 12 13, 0x18530) := rfl
@[ode_at] theorem at_18530 : prog 0x18530 = some (.zpaddd 9 9 14, 0x18536) := rfl
@[ode_at] theorem at_18536 : prog 0x18536 = some (.zpaddd 10 10 15, 0x1853C) := rfl
@[ode_at] theorem at_1853C : prog 0x1853C = some (.zpxord 5 5 11, 0x18542) := rfl
@[ode_at] theorem at_18542 : prog 0x18542 = some (.zpxord 6 6 12, 0x18548) := rfl
@[ode_at] theorem at_18548 : prog 0x18548 = some (.zpxord 7 7 9, 0x1854E) := rfl
@[ode_at] theorem at_1854E : prog 0x1854E = some (.zpxord 4 4 10, 0x18554) := rfl
@[ode_at] theorem at_18554 : prog 0x18554 = some (.zprord 5 5 12, 0x1855B) := rfl
@[ode_at] theorem at_1855B : prog 0x1855B = some (.zprord 6 6 12, 0x18562) := rfl
@[ode_at] theorem at_18562 : prog 0x18562 = some (.zprord 7 7 12, 0x18569) := rfl
@[ode_at] theorem at_18569 : prog 0x18569 = some (.zprord 4 4 12, 0x18570) := rfl
@[ode_at] theorem at_18570 : prog 0x18570 = some (.zpaddd 0 0 21, 0x18576) := rfl
@[ode_at] theorem at_18576 : prog 0x18576 = some (.zpaddd 1 1 19, 0x1857C) := rfl
@[ode_at] theorem at_1857C : prog 0x1857C = some (.zpaddd 2 2 8, 0x18582) := rfl
@[ode_at] theorem at_18582 : prog 0x18582 = some (.zpaddd 3 3 16, 0x18588) := rfl
@[ode_at] theorem at_18588 : prog 0x18588 = some (.zpaddd 0 0 5, 0x1858E) := rfl
@[ode_at] theorem at_1858E : prog 0x1858E = some (.zpaddd 1 1 6, 0x18594) := rfl
@[ode_at] theorem at_18594 : prog 0x18594 = some (.zpaddd 2 2 7, 0x1859A) := rfl
@[ode_at] theorem at_1859A : prog 0x1859A = some (.zpaddd 3 3 4, 0x185A0) := rfl
@[ode_at] theorem at_185A0 : prog 0x185A0 = some (.zpxord 24 24 0, 0x185A6) := rfl
@[ode_at] theorem at_185A6 : prog 0x185A6 = some (.zpxord 13 13 1, 0x185AC) := rfl
@[ode_at] theorem at_185AC : prog 0x185AC = some (.zpxord 14 14 2, 0x185B2) := rfl
@[ode_at] theorem at_185B2 : prog 0x185B2 = some (.zpxord 15 15 3, 0x185B8) := rfl
@[ode_at] theorem at_185B8 : prog 0x185B8 = some (.zprord 24 24 8, 0x185BF) := rfl
@[ode_at] theorem at_185BF : prog 0x185BF = some (.zprord 13 13 8, 0x185C6) := rfl
@[ode_at] theorem at_185C6 : prog 0x185C6 = some (.zprord 14 14 8, 0x185CD) := rfl
@[ode_at] theorem at_185CD : prog 0x185CD = some (.zprord 15 15 8, 0x185D4) := rfl
@[ode_at] theorem at_185D4 : prog 0x185D4 = some (.zpaddd 11 11 24, 0x185DA) := rfl
@[ode_at] theorem at_185DA : prog 0x185DA = some (.zpaddd 12 12 13, 0x185E0) := rfl
@[ode_at] theorem at_185E0 : prog 0x185E0 = some (.zpaddd 9 9 14, 0x185E6) := rfl
@[ode_at] theorem at_185E6 : prog 0x185E6 = some (.zpaddd 10 10 15, 0x185EC) := rfl
@[ode_at] theorem at_185EC : prog 0x185EC = some (.zpxord 5 5 11, 0x185F2) := rfl
@[ode_at] theorem at_185F2 : prog 0x185F2 = some (.zpxord 6 6 12, 0x185F8) := rfl
@[ode_at] theorem at_185F8 : prog 0x185F8 = some (.zpxord 7 7 9, 0x185FE) := rfl
@[ode_at] theorem at_185FE : prog 0x185FE = some (.zpxord 4 4 10, 0x18604) := rfl
@[ode_at] theorem at_18604 : prog 0x18604 = some (.zprord 5 5 7, 0x1860B) := rfl
@[ode_at] theorem at_1860B : prog 0x1860B = some (.zprord 6 6 7, 0x18612) := rfl
@[ode_at] theorem at_18612 : prog 0x18612 = some (.zprord 7 7 7, 0x18619) := rfl
@[ode_at] theorem at_18619 : prog 0x18619 = some (.zprord 4 4 7, 0x18620) := rfl
@[ode_at] theorem at_18620 : prog 0x18620 = some (.dec32 .r11, 0x18623) := rfl
@[ode_at] theorem at_18623 : prog 0x18623 = some (.je 0x18977, 0x18629) := rfl
@[ode_at] theorem at_18629 : prog 0x18629 = some (.zpaddd 0 0 20, 0x1862F) := rfl
@[ode_at] theorem at_1862F : prog 0x1862F = some (.zpaddd 1 1 29, 0x18635) := rfl
@[ode_at] theorem at_18635 : prog 0x18635 = some (.zpaddd 2 2 23, 0x1863B) := rfl
@[ode_at] theorem at_1863B : prog 0x1863B = some (.zpaddd 3 3 27, 0x18641) := rfl
@[ode_at] theorem at_18641 : prog 0x18641 = some (.zpaddd 0 0 4, 0x18647) := rfl
@[ode_at] theorem at_18647 : prog 0x18647 = some (.zpaddd 1 1 5, 0x1864D) := rfl
@[ode_at] theorem at_1864D : prog 0x1864D = some (.zpaddd 2 2 6, 0x18653) := rfl
@[ode_at] theorem at_18653 : prog 0x18653 = some (.zpaddd 3 3 7, 0x18659) := rfl
@[ode_at] theorem at_18659 : prog 0x18659 = some (.zpxord 13 13 0, 0x1865F) := rfl
@[ode_at] theorem at_1865F : prog 0x1865F = some (.zpxord 14 14 1, 0x18665) := rfl
@[ode_at] theorem at_18665 : prog 0x18665 = some (.zpxord 15 15 2, 0x1866B) := rfl
@[ode_at] theorem at_1866B : prog 0x1866B = some (.zpxord 24 24 3, 0x18671) := rfl
@[ode_at] theorem at_18671 : prog 0x18671 = some (.zprord 13 13 16, 0x18678) := rfl
@[ode_at] theorem at_18678 : prog 0x18678 = some (.zprord 14 14 16, 0x1867F) := rfl
@[ode_at] theorem at_1867F : prog 0x1867F = some (.zprord 15 15 16, 0x18686) := rfl
@[ode_at] theorem at_18686 : prog 0x18686 = some (.zprord 24 24 16, 0x1868D) := rfl
@[ode_at] theorem at_1868D : prog 0x1868D = some (.zpaddd 9 9 13, 0x18693) := rfl
@[ode_at] theorem at_18693 : prog 0x18693 = some (.zpaddd 10 10 14, 0x18699) := rfl
@[ode_at] theorem at_18699 : prog 0x18699 = some (.zpaddd 11 11 15, 0x1869F) := rfl
@[ode_at] theorem at_1869F : prog 0x1869F = some (.zpaddd 12 12 24, 0x186A5) := rfl
@[ode_at] theorem at_186A5 : prog 0x186A5 = some (.zpxord 4 4 9, 0x186AB) := rfl
@[ode_at] theorem at_186AB : prog 0x186AB = some (.zpxord 5 5 10, 0x186B1) := rfl
@[ode_at] theorem at_186B1 : prog 0x186B1 = some (.zpxord 6 6 11, 0x186B7) := rfl
@[ode_at] theorem at_186B7 : prog 0x186B7 = some (.zpxord 7 7 12, 0x186BD) := rfl
@[ode_at] theorem at_186BD : prog 0x186BD = some (.zprord 4 4 12, 0x186C4) := rfl
@[ode_at] theorem at_186C4 : prog 0x186C4 = some (.zprord 5 5 12, 0x186CB) := rfl
@[ode_at] theorem at_186CB : prog 0x186CB = some (.zprord 6 6 12, 0x186D2) := rfl
@[ode_at] theorem at_186D2 : prog 0x186D2 = some (.zprord 7 7 12, 0x186D9) := rfl
@[ode_at] theorem at_186D9 : prog 0x186D9 = some (.zpaddd 0 0 22, 0x186DF) := rfl
@[ode_at] theorem at_186DF : prog 0x186DF = some (.zpaddd 1 1 18, 0x186E5) := rfl
@[ode_at] theorem at_186E5 : prog 0x186E5 = some (.zpaddd 2 2 28, 0x186EB) := rfl
@[ode_at] theorem at_186EB : prog 0x186EB = some (.zpaddd 3 3 8, 0x186F1) := rfl
@[ode_at] theorem at_186F1 : prog 0x186F1 = some (.zpaddd 0 0 4, 0x186F7) := rfl
@[ode_at] theorem at_186F7 : prog 0x186F7 = some (.zpaddd 1 1 5, 0x186FD) := rfl
@[ode_at] theorem at_186FD : prog 0x186FD = some (.zpaddd 2 2 6, 0x18703) := rfl
@[ode_at] theorem at_18703 : prog 0x18703 = some (.zpaddd 3 3 7, 0x18709) := rfl
@[ode_at] theorem at_18709 : prog 0x18709 = some (.zpxord 13 13 0, 0x1870F) := rfl
@[ode_at] theorem at_1870F : prog 0x1870F = some (.zpxord 14 14 1, 0x18715) := rfl
@[ode_at] theorem at_18715 : prog 0x18715 = some (.zpxord 15 15 2, 0x1871B) := rfl
@[ode_at] theorem at_1871B : prog 0x1871B = some (.zpxord 24 24 3, 0x18721) := rfl
@[ode_at] theorem at_18721 : prog 0x18721 = some (.zprord 13 13 8, 0x18728) := rfl
@[ode_at] theorem at_18728 : prog 0x18728 = some (.zprord 14 14 8, 0x1872F) := rfl
@[ode_at] theorem at_1872F : prog 0x1872F = some (.zprord 15 15 8, 0x18736) := rfl
@[ode_at] theorem at_18736 : prog 0x18736 = some (.zprord 24 24 8, 0x1873D) := rfl
@[ode_at] theorem at_1873D : prog 0x1873D = some (.zpaddd 9 9 13, 0x18743) := rfl
@[ode_at] theorem at_18743 : prog 0x18743 = some (.zpaddd 10 10 14, 0x18749) := rfl
@[ode_at] theorem at_18749 : prog 0x18749 = some (.zpaddd 11 11 15, 0x1874F) := rfl
@[ode_at] theorem at_1874F : prog 0x1874F = some (.zpaddd 12 12 24, 0x18755) := rfl
@[ode_at] theorem at_18755 : prog 0x18755 = some (.zpxord 4 4 9, 0x1875B) := rfl
@[ode_at] theorem at_1875B : prog 0x1875B = some (.zpxord 5 5 10, 0x18761) := rfl
@[ode_at] theorem at_18761 : prog 0x18761 = some (.zpxord 6 6 11, 0x18767) := rfl
@[ode_at] theorem at_18767 : prog 0x18767 = some (.zpxord 7 7 12, 0x1876D) := rfl
@[ode_at] theorem at_1876D : prog 0x1876D = some (.zprord 4 4 7, 0x18774) := rfl
@[ode_at] theorem at_18774 : prog 0x18774 = some (.zprord 5 5 7, 0x1877B) := rfl
@[ode_at] theorem at_1877B : prog 0x1877B = some (.zprord 6 6 7, 0x18782) := rfl
@[ode_at] theorem at_18782 : prog 0x18782 = some (.zprord 7 7 7, 0x18789) := rfl
@[ode_at] theorem at_18789 : prog 0x18789 = some (.zpaddd 0 0 26, 0x1878F) := rfl
@[ode_at] theorem at_1878F : prog 0x1878F = some (.zpaddd 1 1 31, 0x18795) := rfl
@[ode_at] theorem at_18795 : prog 0x18795 = some (.zpaddd 2 2 21, 0x1879B) := rfl
@[ode_at] theorem at_1879B : prog 0x1879B = some (.zpaddd 3 3 16, 0x187A1) := rfl
@[ode_at] theorem at_187A1 : prog 0x187A1 = some (.zpaddd 0 0 5, 0x187A7) := rfl
@[ode_at] theorem at_187A7 : prog 0x187A7 = some (.zpaddd 1 1 6, 0x187AD) := rfl
@[ode_at] theorem at_187AD : prog 0x187AD = some (.zpaddd 2 2 7, 0x187B3) := rfl
@[ode_at] theorem at_187B3 : prog 0x187B3 = some (.zpaddd 3 3 4, 0x187B9) := rfl
@[ode_at] theorem at_187B9 : prog 0x187B9 = some (.zpxord 24 24 0, 0x187BF) := rfl
@[ode_at] theorem at_187BF : prog 0x187BF = some (.zpxord 13 13 1, 0x187C5) := rfl
@[ode_at] theorem at_187C5 : prog 0x187C5 = some (.zpxord 14 14 2, 0x187CB) := rfl
@[ode_at] theorem at_187CB : prog 0x187CB = some (.zpxord 15 15 3, 0x187D1) := rfl
@[ode_at] theorem at_187D1 : prog 0x187D1 = some (.zprord 24 24 16, 0x187D8) := rfl
@[ode_at] theorem at_187D8 : prog 0x187D8 = some (.zprord 13 13 16, 0x187DF) := rfl
@[ode_at] theorem at_187DF : prog 0x187DF = some (.zprord 14 14 16, 0x187E6) := rfl
@[ode_at] theorem at_187E6 : prog 0x187E6 = some (.zprord 15 15 16, 0x187ED) := rfl
@[ode_at] theorem at_187ED : prog 0x187ED = some (.zpaddd 11 11 24, 0x187F3) := rfl
@[ode_at] theorem at_187F3 : prog 0x187F3 = some (.zpaddd 12 12 13, 0x187F9) := rfl
@[ode_at] theorem at_187F9 : prog 0x187F9 = some (.zpaddd 9 9 14, 0x187FF) := rfl
@[ode_at] theorem at_187FF : prog 0x187FF = some (.zpaddd 10 10 15, 0x18805) := rfl
@[ode_at] theorem at_18805 : prog 0x18805 = some (.zpxord 5 5 11, 0x1880B) := rfl
@[ode_at] theorem at_1880B : prog 0x1880B = some (.zpxord 6 6 12, 0x18811) := rfl
@[ode_at] theorem at_18811 : prog 0x18811 = some (.zpxord 7 7 9, 0x18817) := rfl
@[ode_at] theorem at_18817 : prog 0x18817 = some (.zpxord 4 4 10, 0x1881D) := rfl
@[ode_at] theorem at_1881D : prog 0x1881D = some (.zprord 5 5 12, 0x18824) := rfl
@[ode_at] theorem at_18824 : prog 0x18824 = some (.zprord 6 6 12, 0x1882B) := rfl
@[ode_at] theorem at_1882B : prog 0x1882B = some (.zprord 7 7 12, 0x18832) := rfl
@[ode_at] theorem at_18832 : prog 0x18832 = some (.zprord 4 4 12, 0x18839) := rfl
@[ode_at] theorem at_18839 : prog 0x18839 = some (.zpaddd 0 0 19, 0x1883F) := rfl
@[ode_at] theorem at_1883F : prog 0x1883F = some (.zpaddd 1 1 25, 0x18845) := rfl
@[ode_at] theorem at_18845 : prog 0x18845 = some (.zpaddd 2 2 17, 0x1884B) := rfl
@[ode_at] theorem at_1884B : prog 0x1884B = some (.zpaddd 3 3 30, 0x18851) := rfl
@[ode_at] theorem at_18851 : prog 0x18851 = some (.zpaddd 0 0 5, 0x18857) := rfl
@[ode_at] theorem at_18857 : prog 0x18857 = some (.zpaddd 1 1 6, 0x1885D) := rfl
@[ode_at] theorem at_1885D : prog 0x1885D = some (.zpaddd 2 2 7, 0x18863) := rfl
@[ode_at] theorem at_18863 : prog 0x18863 = some (.zpaddd 3 3 4, 0x18869) := rfl
@[ode_at] theorem at_18869 : prog 0x18869 = some (.zpxord 24 24 0, 0x1886F) := rfl
@[ode_at] theorem at_1886F : prog 0x1886F = some (.zpxord 13 13 1, 0x18875) := rfl
@[ode_at] theorem at_18875 : prog 0x18875 = some (.zpxord 14 14 2, 0x1887B) := rfl
@[ode_at] theorem at_1887B : prog 0x1887B = some (.zpxord 15 15 3, 0x18881) := rfl
@[ode_at] theorem at_18881 : prog 0x18881 = some (.zprord 24 24 8, 0x18888) := rfl
@[ode_at] theorem at_18888 : prog 0x18888 = some (.zprord 13 13 8, 0x1888F) := rfl
@[ode_at] theorem at_1888F : prog 0x1888F = some (.zprord 14 14 8, 0x18896) := rfl
@[ode_at] theorem at_18896 : prog 0x18896 = some (.zprord 15 15 8, 0x1889D) := rfl
@[ode_at] theorem at_1889D : prog 0x1889D = some (.zpaddd 11 11 24, 0x188A3) := rfl
@[ode_at] theorem at_188A3 : prog 0x188A3 = some (.zpaddd 12 12 13, 0x188A9) := rfl
@[ode_at] theorem at_188A9 : prog 0x188A9 = some (.zpaddd 9 9 14, 0x188AF) := rfl
@[ode_at] theorem at_188AF : prog 0x188AF = some (.zpaddd 10 10 15, 0x188B5) := rfl
@[ode_at] theorem at_188B5 : prog 0x188B5 = some (.zpxord 5 5 11, 0x188BB) := rfl
@[ode_at] theorem at_188BB : prog 0x188BB = some (.zpxord 6 6 12, 0x188C1) := rfl
@[ode_at] theorem at_188C1 : prog 0x188C1 = some (.zpxord 7 7 9, 0x188C7) := rfl
@[ode_at] theorem at_188C7 : prog 0x188C7 = some (.zpxord 4 4 10, 0x188CD) := rfl
@[ode_at] theorem at_188CD : prog 0x188CD = some (.zprord 5 5 7, 0x188D4) := rfl
@[ode_at] theorem at_188D4 : prog 0x188D4 = some (.zprord 6 6 7, 0x188DB) := rfl
@[ode_at] theorem at_188DB : prog 0x188DB = some (.zprord 7 7 7, 0x188E2) := rfl
@[ode_at] theorem at_188E2 : prog 0x188E2 = some (.zprord 4 4 7, 0x188E9) := rfl
@[ode_at] theorem at_188E9 : prog 0x188E9 = some (.dec32 .r11, 0x188EC) := rfl
@[ode_at] theorem at_188EC : prog 0x188EC = some (.zstore true .rsp 0x0 28, 0x188F3) := rfl
@[ode_at] theorem at_188F3 : prog 0x188F3 = some (.zmov 28 29, 0x188F9) := rfl
@[ode_at] theorem at_188F9 : prog 0x188F9 = some (.zmov 29 31, 0x188FF) := rfl
@[ode_at] theorem at_188FF : prog 0x188FF = some (.zmov 31 19, 0x18905) := rfl
@[ode_at] theorem at_18905 : prog 0x18905 = some (.zload true 19 .rsp 0x0, 0x1890C) := rfl
@[ode_at] theorem at_1890C : prog 0x1890C = some (.zstore true .rsp 0x40 26, 0x18914) := rfl
@[ode_at] theorem at_18914 : prog 0x18914 = some (.zmov 26 27, 0x1891A) := rfl
@[ode_at] theorem at_1891A : prog 0x1891A = some (.zmov 27 8, 0x18920) := rfl
@[ode_at] theorem at_18920 : prog 0x18920 = some (.zmov 8 16, 0x18926) := rfl
@[ode_at] theorem at_18926 : prog 0x18926 = some (.zload true 16 .rsp 0x40, 0x1892E) := rfl
@[ode_at] theorem at_1892E : prog 0x1892E = some (.zstore true .rsp 0x80 20, 0x18936) := rfl
@[ode_at] theorem at_18936 : prog 0x18936 = some (.zmov 20 18, 0x1893C) := rfl
@[ode_at] theorem at_1893C : prog 0x1893C = some (.zmov 18 21, 0x18942) := rfl
@[ode_at] theorem at_18942 : prog 0x18942 = some (.zmov 21 25, 0x18948) := rfl
@[ode_at] theorem at_18948 : prog 0x18948 = some (.zload true 25 .rsp 0x80, 0x18950) := rfl
@[ode_at] theorem at_18950 : prog 0x18950 = some (.zstore true .rsp 0xC0 22, 0x18958) := rfl
@[ode_at] theorem at_18958 : prog 0x18958 = some (.zmov 22 23, 0x1895E) := rfl
@[ode_at] theorem at_1895E : prog 0x1895E = some (.zmov 23 17, 0x18964) := rfl
@[ode_at] theorem at_18964 : prog 0x18964 = some (.zmov 17 30, 0x1896A) := rfl
@[ode_at] theorem at_1896A : prog 0x1896A = some (.zload true 30 .rsp 0xC0, 0x18972) := rfl
@[ode_at] theorem at_18972 : prog 0x18972 = some (.jmp 0x18360, 0x18977) := rfl
@[ode_at] theorem at_18977 : prog 0x18977 = some (.zpxord 0 0 9, 0x1897D) := rfl
@[ode_at] theorem at_1897D : prog 0x1897D = some (.zpxord 1 1 10, 0x18983) := rfl
@[ode_at] theorem at_18983 : prog 0x18983 = some (.zpxord 2 2 11, 0x18989) := rfl
@[ode_at] theorem at_18989 : prog 0x18989 = some (.zpxord 3 3 12, 0x1898F) := rfl
@[ode_at] theorem at_1898F : prog 0x1898F = some (.zpxord 4 4 13, 0x18995) := rfl
@[ode_at] theorem at_18995 : prog 0x18995 = some (.zpxord 5 5 14, 0x1899B) := rfl
@[ode_at] theorem at_1899B : prog 0x1899B = some (.zpxord 6 6 15, 0x189A1) := rfl
@[ode_at] theorem at_189A1 : prog 0x189A1 = some (.zpxord 7 7 24, 0x189A7) := rfl
@[ode_at] theorem at_189A7 : prog 0x189A7 = some (.mov 32 (.reg .r10) (.reg .r8), 0x189AA) := rfl
@[ode_at] theorem at_189AA : prog 0x189AA = some (.add 64 (.reg .r14) (.imm 0x40), 0x189AE) := rfl
@[ode_at] theorem at_189AE : prog 0x189AE = some (.dec64 .r13, 0x189B1) := rfl
@[ode_at] theorem at_189B1 : prog 0x189B1 = some (.jne 0x18091, 0x189B7) := rfl
@[ode_at] theorem at_189B7 : prog 0x189B7 = some (.zunpckldq 16 0 1, 0x189BD) := rfl
@[ode_at] theorem at_189BD : prog 0x189BD = some (.zunpckhdq 0 0 1, 0x189C3) := rfl
@[ode_at] theorem at_189C3 : prog 0x189C3 = some (.zunpckldq 1 2 3, 0x189C9) := rfl
@[ode_at] theorem at_189C9 : prog 0x189C9 = some (.zunpckhdq 2 2 3, 0x189CF) := rfl
@[ode_at] theorem at_189CF : prog 0x189CF = some (.zunpckldq 3 4 5, 0x189D5) := rfl
@[ode_at] theorem at_189D5 : prog 0x189D5 = some (.zunpckhdq 4 4 5, 0x189DB) := rfl
@[ode_at] theorem at_189DB : prog 0x189DB = some (.zunpckldq 5 6 7, 0x189E1) := rfl
@[ode_at] theorem at_189E1 : prog 0x189E1 = some (.zunpckhdq 6 6 7, 0x189E7) := rfl
@[ode_at] theorem at_189E7 : prog 0x189E7 = some (.zunpcklqdq 7 16 1, 0x189ED) := rfl
@[ode_at] theorem at_189ED : prog 0x189ED = some (.zunpckhqdq 16 16 1, 0x189F3) := rfl
@[ode_at] theorem at_189F3 : prog 0x189F3 = some (.zunpcklqdq 1 0 2, 0x189F9) := rfl
@[ode_at] theorem at_189F9 : prog 0x189F9 = some (.zunpckhqdq 0 0 2, 0x189FF) := rfl
@[ode_at] theorem at_189FF : prog 0x189FF = some (.zunpcklqdq 2 3 5, 0x18A05) := rfl
@[ode_at] theorem at_18A05 : prog 0x18A05 = some (.zunpckhqdq 3 3 5, 0x18A0B) := rfl
@[ode_at] theorem at_18A0B : prog 0x18A0B = some (.zunpcklqdq 5 4 6, 0x18A11) := rfl
@[ode_at] theorem at_18A11 : prog 0x18A11 = some (.zunpckhqdq 4 4 6, 0x18A17) := rfl
@[ode_at] theorem at_18A17 : prog 0x18A17 = some (.zshufi32x4 6 7 2 136, 0x18A1E) := rfl
@[ode_at] theorem at_18A1E : prog 0x18A1E = some (.zshufi32x4 7 7 2 221, 0x18A25) := rfl
@[ode_at] theorem at_18A25 : prog 0x18A25 = some (.zshufi32x4 2 1 5 136, 0x18A2C) := rfl
@[ode_at] theorem at_18A2C : prog 0x18A2C = some (.zshufi32x4 1 1 5 221, 0x18A33) := rfl
@[ode_at] theorem at_18A33 : prog 0x18A33 = some (.zshufi32x4 5 16 3 136, 0x18A3A) := rfl
@[ode_at] theorem at_18A3A : prog 0x18A3A = some (.zshufi32x4 16 16 3 221, 0x18A41) := rfl
@[ode_at] theorem at_18A41 : prog 0x18A41 = some (.zshufi32x4 3 0 4 136, 0x18A48) := rfl
@[ode_at] theorem at_18A48 : prog 0x18A48 = some (.zshufi32x4 0 0 4 221, 0x18A4F) := rfl
@[ode_at] theorem at_18A4F : prog 0x18A4F = some (.zshufi32x4 4 6 5 136, 0x18A56) := rfl
@[ode_at] theorem at_18A56 : prog 0x18A56 = some (.zstore false .r15 0x0 4, 0x18A5C) := rfl
@[ode_at] theorem at_18A5C : prog 0x18A5C = some (.zshufi32x4 4 2 3 136, 0x18A63) := rfl
@[ode_at] theorem at_18A63 : prog 0x18A63 = some (.zstore false .r15 0x40 4, 0x18A6A) := rfl
@[ode_at] theorem at_18A6A : prog 0x18A6A = some (.zshufi32x4 4 7 16 136, 0x18A71) := rfl
@[ode_at] theorem at_18A71 : prog 0x18A71 = some (.zstore false .r15 0x80 4, 0x18A78) := rfl
@[ode_at] theorem at_18A78 : prog 0x18A78 = some (.zshufi32x4 4 1 0 136, 0x18A7F) := rfl
@[ode_at] theorem at_18A7F : prog 0x18A7F = some (.zstore false .r15 0xC0 4, 0x18A86) := rfl
@[ode_at] theorem at_18A86 : prog 0x18A86 = some (.zshufi32x4 4 6 5 221, 0x18A8D) := rfl
@[ode_at] theorem at_18A8D : prog 0x18A8D = some (.zstore false .r15 0x100 4, 0x18A94) := rfl
@[ode_at] theorem at_18A94 : prog 0x18A94 = some (.zshufi32x4 4 2 3 221, 0x18A9B) := rfl
@[ode_at] theorem at_18A9B : prog 0x18A9B = some (.zstore false .r15 0x140 4, 0x18AA2) := rfl
@[ode_at] theorem at_18AA2 : prog 0x18AA2 = some (.zshufi32x4 4 7 16 221, 0x18AA9) := rfl
@[ode_at] theorem at_18AA9 : prog 0x18AA9 = some (.zstore false .r15 0x180 4, 0x18AB0) := rfl
@[ode_at] theorem at_18AB0 : prog 0x18AB0 = some (.zshufi32x4 4 1 0 221, 0x18AB7) := rfl
@[ode_at] theorem at_18AB7 : prog 0x18AB7 = some (.zstore false .r15 0x1C0 4, 0x18ABE) := rfl
@[ode_at] theorem at_18ABE : prog 0x18ABE = some (.vzeroupper, 0x18AC1) := rfl
@[ode_at] theorem at_18AC1 : prog 0x18AC1 = some (.lea .rsp .rbp 0xFFFFFFFFFFFFFFD8, 0x18AC5) := rfl
@[ode_at] theorem at_18AC5 : prog 0x18AC5 = some (.pop .r15, 0x18AC7) := rfl
@[ode_at] theorem at_18AC7 : prog 0x18AC7 = some (.pop .r14, 0x18AC9) := rfl
@[ode_at] theorem at_18AC9 : prog 0x18AC9 = some (.pop .r13, 0x18ACB) := rfl
@[ode_at] theorem at_18ACB : prog 0x18ACB = some (.pop .r12, 0x18ACD) := rfl
@[ode_at] theorem at_18ACD : prog 0x18ACD = some (.pop .rbx, 0x18ACE) := rfl
@[ode_at] theorem at_18ACE : prog 0x18ACE = some (.pop .rbp, 0x18ACF) := rfl
@[ode_at] theorem at_18ACF : prog 0x18ACF = some (.ret, 0x18AD0) := rfl

end Code_p16
