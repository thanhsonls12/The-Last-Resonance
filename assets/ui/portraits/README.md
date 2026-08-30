# Dialogue portraits

## Dialogue avatars

Square avatar assets for the dialogue box shown in the Android landscape UI:

- `kiro_avatar_dialogue.png` — Kiro-K7, exact box-shaped robot design from the supplied model reference, upper-body close-up.
- `eva_avatar_dialogue.png` — EVA, faceted holographic AI woman with cyan eyes and chest core, upper-body close-up facing toward the right-side dialogue text.
- `elias_avatar_dialogue.png` — Dr. Elias Vale, exact visor/suit/tablet design, upper-body close-up facing toward the right-side dialogue text.
- `system_avatar_dialogue.png` — abstract SYSTEM emergency power-core emblem; no character face or baked-in text.

Each avatar is 1:1 (`1254x1254`). The images contain no speaker name or dialogue text; those should be rendered by the Dialogue UI. The avatar box can crop or scale these assets without distorting the character/emblem.

## Landscape dialogue cards

These are full landscape presentation cards for Android:

- `kiro_dialogue_card_v3.png` — Kiro-K7, compact box-shaped maintenance robot, upper-body crop.
- `kiro_dialogue_card_left_v1.png` — Kiro-K7, upper-body crop positioned on the left for dialogue text on the right.
- `eva_dialogue_card_v3.png` — EVA, floating maintenance robot/central AI, upper-body crop.
- `dr_elias_dialogue_card_v3.png` — Dr. Elias Vale, stylized scientist with visor and tablet, upper-body crop.

Each final card is 16:9 (`1672x941`). The standard cards place the character on the right with a darker left side reserved for dialogue text; `kiro_dialogue_card_left_v1.png` is the reversed layout with Kiro on the left. Use the `*_dialogue_card_v3.png` files and the left-layout Kiro card as needed. The older `*_dialogue.png`, `*_dialogue_card.png`, and `*_dialogue_card_v2.png` files are earlier portrait experiments and are not the final dialogue assets.
