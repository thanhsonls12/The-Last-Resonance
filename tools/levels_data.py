# LEGACY DESIGN SNAPSHOT — not used by runtime or the current validator.
# The current runtime source of truth is resources/levels/*.tres, parsed by
# tools/tres_levels.py. This file preserves an older five-level prototype only.
# Maps use game_logic.gd symbols:
#   # wall  . pedestal  p plate  D door  a/b portal  e elevator  r bridge
#   $ core  * core-on-slot  @ player  + player-on-slot
# Multi-floor levels use "maps": [layer0_rows, layer1_rows, ...] (y = floor).
# Bridge/energy come from "entities" (mirrors the .gd entity schema).

LEVELS = [
    # ================= CHAPTER I - FORGOTTEN ARCHIVE =================
    {
        "name": "Khoi dong", "chapter": 1, "difficulty": 1,
        "memory": "KY UC 01 [TRAM BAO TRI AST-327]: Kiro-K7 kich hoat sau 327 nam. Asteria mat dien toan phan. Nhiem vu: ket noi lai cac Lumina Core.",
        "map": [
            "###########",
            "#         #",
            "# ##   ## #",
            "#         #",
            "#  @ $  . #",
            "#         #",
            "# ##   ## #",
            "#         #",
            "###########",
        ],
    },
    {
        "name": "Goc luu tru", "chapter": 1, "difficulty": 1,
        "memory": "KY UC 02 [KS. MARA]: Dao dong song trong Lumina Core ngay cang bat thuong. EVA tran an rang moi thu trong tam kiem soat. Toi khong tin co ta nua.",
        "map": [
            "###########",
            "#       . #",
            "#  ####   #",
            "#         #",
            "#  @ $    #",
            "#         #",
            "#  ##  ## #",
            "#         #",
            "###########",
        ],
    },
    {
        "name": "Hai loi", "chapter": 1, "difficulty": 2,
        "memory": "KY UC 03 [KS. MARA]: 'Cac Core dao dong ngay cang manh. EVA noi moi thu trong tam kiem soat. Toi khong tin ba ta.'",
        "map": [
            "#########",
            "#       #",
            "# $   $ #",
            "# .   . #",
            "#   @   #",
            "#########",
        ],
    },
    {
        "name": "Duong vong", "chapter": 1, "difficulty": 2,
        "memory": "KY UC 04 [ARCHIVE]: Lumina khong chi la nang luong. No luu giu dau vet ky uc con nguoi.",
        "map": [
            "#######",
            "#   . #",
            "# ##  #",
            "# $   #",
            "# @   #",
            "#######",
        ],
    },
    {
        "name": "Kho hep", "chapter": 1, "difficulty": 3,
        "memory": "KY UC 05 [DR. ELIAS VALE]: 'Neu ai do doc duoc dieu nay: he thong dang tro nen nguy hiem. Lumina ghi lai chung ta.'",
        "map": [
            "#########",
            "#  . .  #",
            "# $   $ #",
            "#   @   #",
            "#       #",
            "#########",
        ],
    },
    # PLACEHOLDER_CH2
]
