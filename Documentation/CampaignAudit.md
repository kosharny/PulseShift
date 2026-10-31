# Campaign revision 2 — deterministic audit

All 60 layouts pass the engine validator, including their explicit objectives and stored solution. Each is individually specified in `Scripts/generate_levels.py`; no random board generation, mirrored variants or row-chain template loops are used. Six board sizes are represented. Every level carries a design intent and revision number.

32 levels include at least one authored move that prepares a route without an exit. Level 60's final move creates a chain of 11, with three reactors and six dormant pulses. Par is the authored target, not a proof of the shortest possible solution. Difficulty and retention still need player testing; these metrics validate content structure and correctness.

Early instruction is short: Levels 1–8 take 1–4 moves. Each new mechanic gets a brief introduction followed by ordering puzzles and mixed application. Chapter endings and 56–60 emphasize preparation followed by a branching payoff. Partial movement costs a move; unchanged blocked taps remain free. Move limits appear selectively and permit undo/restart. New score records are revision-aware, while historical chapter access and earned currency are preserved.

| Level | Name | Board | Occupancy | Par | Setup moves | Peak chain | Verified solution |
|---|---|---|---|---|---|---|---|
| 1 | First Spark | 6×9 | 1% | 1 | 0 | 1 | a |
| 2 | Go Your Own Way | 6×9 | 3% | 2 | 0 | 1 | a → b |
| 3 | You First | 6×9 | 5% | 3 | 0 | 1 | c → b → a |
| 4 | Side Step | 5×8 | 12% | 3 | 0 | 1 | c → b → a |
| 5 | Tiny Traffic | 6×9 | 12% | 4 | 0 | 1 | d → c → b → a |
| 6 | Meet in the Middle | 6×8 | 8% | 4 | 0 | 1 | c → b → a → d |
| 7 | Around the Corner | 5×8 | 15% | 4 | 0 | 1 | d → c → b → a |
| 8 | Four Corners | 6×9 | 7% | 4 | 0 | 1 | c → b → a → d |
| 9 | Crossroads | 7×9 | 19% | 7 | 0 | 1 | d → c → b → a → f → g → h |
| 10 | Woven Signal | 7×10 | 18% | 9 | 0 | 1 | d → c → b → a → j → f → g → h → i |
| 11 | Bend the Light | 6×9 | 7% | 1 | 0 | 1 | a |
| 12 | Double Take | 6×9 | 11% | 2 | 0 | 1 | b → a |
| 13 | Crack the Code | 6×9 | 9% | 2 | 1 | 1 | a → a |
| 14 | Spin Cycle | 7×10 | 10% | 3 | 0 | 1 | c → b → a |
| 15 | Untie the Knot | 6×9 | 11% | 3 | 1 | 1 | a → b → a |
| 16 | Two-Sided Glass | 7×10 | 10% | 4 | 2 | 1 | a → b → a → b |
| 17 | Return Ticket | 7×10 | 12% | 4 | 0 | 1 | d → b → a → c |
| 18 | Diamond Cut | 7×10 | 17% | 7 | 3 | 1 | d → c → c → b → a → d → b |
| 19 | Long Way Home | 7×10 | 18% | 4 | 0 | 1 | d → c → b → a |
| 20 | Vector Vault | 7×10 | 22% | 9 | 2 | 1 | h → g → f → d → d → c → b → a → d |
| 21 | Open Sesame | 6×9 | 7% | 2 | 0 | 2 | a → b |
| 22 | Key Exchange | 7×10 | 12% | 4 | 0 | 2 | d → c → a → b |
| 23 | Heart Beat | 6×9 | 11% | 2 | 0 | 4 | a → b |
| 24 | Before the Boom | 7×10 | 15% | 5 | 0 | 2 | d → c → b → a → f |
| 25 | Glass Keys | 7×10 | 17% | 5 | 1 | 3 | d → a → b → b → c |
| 26 | The Wrong First Move | 7×10 | 17% | 4 | 0 | 3 | c → b → a → d |
| 27 | Keep It Open | 7×10 | 17% | 6 | 0 | 2 | g → f → a → d → b → c |
| 28 | Three Locks | 7×10 | 17% | 6 | 0 | 4 | c → b → a → d → f → g |
| 29 | Split Decision | 8×11 | 17% | 7 | 1 | 3 | g → g → f → d → c → b → a |
| 30 | Circuit Symphony | 8×11 | 22% | 9 | 2 | 3 | h → g → f → c → b → a → d → c → h |
| 31 | Shortcut | 6×9 | 9% | 1 | 0 | 1 | a |
| 32 | Exit Traffic | 7×10 | 12% | 4 | 0 | 1 | d → c → b → a |
| 33 | Wake Up | 6×9 | 7% | 2 | 0 | 3 | b → a |
| 34 | Long Distance Call | 7×10 | 15% | 4 | 0 | 3 | d → c → b → a |
| 35 | Wake in Order | 7×10 | 15% | 5 | 1 | 4 | d → d → c → b → a |
| 36 | Two Worlds | 8×11 | 14% | 6 | 2 | 1 | d → d → d → c → b → a |
| 37 | Sleeping Giant | 7×10 | 17% | 6 | 1 | 4 | f → c → b → d → c → a |
| 38 | Phase Carousel | 8×11 | 15% | 7 | 2 | 3 | d → c → c → b → d → f → a |
| 39 | Quiet Before | 8×11 | 17% | 5 | 0 | 4 | d → c → f → b → a |
| 40 | Across the Universe | 8×11 | 20% | 9 | 2 | 4 | d → d → d → c → b → h → g → f → a |
| 41 | A Little Pull | 6×9 | 7% | 2 | 1 | 1 | F → a |
| 42 | Push and Pull | 7×10 | 8% | 3 | 1 | 1 | F → a → b |
| 43 | Wait for Space | 7×10 | 12% | 5 | 1 | 1 | d → c → b → F → a |
| 44 | Vertical Thinking | 7×10 | 12% | 5 | 2 | 2 | c → b → b → F → a |
| 45 | Double Lock | 8×11 | 15% | 7 | 1 | 2 | d → c → g → f → b → F → a |
| 46 | Repulsion Route | 7×10 | 15% | 6 | 3 | 1 | c → c → c → b → F → a |
| 47 | Magnetic Key | 8×11 | 12% | 8 | 3 | 2 | d → d → d → c → F → a → b → f |
| 48 | Opposite Ends | 8×11 | 14% | 7 | 1 | 2 | d → c → g → f → F → a → b |
| 49 | Move the Shield | 8×11 | 15% | 8 | 3 | 3 | d → d → d → c → F → b → f → a |
| 50 | Field of Dreams | 8×11 | 20% | 9 | 3 | 3 | f → g → g → g → d → c → F → b → a |
| 51 | Ignition | 7×10 | 11% | 3 | 0 | 5 | c → b → a |
| 52 | Prepare the Party | 8×11 | 14% | 7 | 2 | 5 | f → f → f → d → c → b → a |
| 53 | A Remote Spark | 8×11 | 17% | 7 | 2 | 5 | d → c → c → b → d → f → a |
| 54 | Over and Under | 8×11 | 19% | 8 | 2 | 5 | g → g → f → d → c → F → b → a |
| 55 | Counter Current | 8×11 | 18% | 8 | 2 | 5 | g → g → g → f → c → b → a → d |
| 56 | Starlight Engine | 8×11 | 21% | 8 | 2 | 8 | g → f → d → d → c → b → d → a |
| 57 | Prism Express | 8×11 | 20% | 8 | 2 | 8 | g → f → d → d → d → c → b → a |
| 58 | Magnetic Orchestra | 8×11 | 25% | 10 | 3 | 8 | h → g → f → f → f → d → c → F → b → a |
| 59 | Supernova | 8×11 | 26% | 10 | 3 | 8 | h → g → f → f → f → F → d → c → b → a |
| 60 | Full Spectrum | 8×11 | 30% | 10 | 3 | 11 | h → g → f → f → f → d → c → F → b → a |
