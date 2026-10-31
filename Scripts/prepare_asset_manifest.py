"""Document art slots and create unnamespaced catalog groups without missing-image warnings."""
import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
GROUPS={
'Branding': [('branding_logo','Original wordmark, white and gradient variants','1024×256'),('branding_symbol','Rounded pulse monogram, no text','512×512'),('branding_launch','Centered launch mark','512×512')],
'UI': [('ui_cta','Glossy aqua primary CTA, keep center clear for live text','720×160'),('ui_secondary','Blue raised secondary button','720×160'),('ui_action_pill','Dark and gold pill surfaces','400×144'),('ui_selected_tab','Filled cyan selected capsule','240×180')],
'Tabs': [(f'tab_{n}',f'{n.title()} icon: solid silhouette, active/inactive tintable','144×144') for n in ['home','levels','daily','collection']],
'Home': [('home_hero_board','Original playful diagonal board micro-illustration','800×800'),('home_daily','Daily event sun/pulse emblem','256×256'),('home_weekly','Seven-node circuit emblem','256×256'),('home_stats','Signal statistics emblem','256×256'),('home_collection','Collectible palette emblem','256×256'),('background_energy','Subtle midnight energy motifs; safe center and quiet text zones','1290×2796')]+[(f'chapter_{i:02}',n+' chapter emblem','256×256') for i,n in enumerate(['First Pulse','Vector','Circuit','Phase','Polarity','Overload'],1)],
'Gameplay': [('gameplay_board_frame','Transparent center; dimensional blue outer arena frame','960×1320'),('gameplay_cell','Quiet rounded cell inset, no semantic marks','192×192')],
'Pieces': [('piece_shard','Neutral glossy shard base, no arrow; transparent outer margin','192×192'),('piece_dormant','Dormant frosted shard base, no arrow','192×192'),('piece_arrow_up','White upright arrow; engine rotates this shared glyph','128×128')]+[(f'piece_arrow_{d}',f'{d.title()} arrow export for illustration use; gameplay rotates up','128×128') for d in ['right','down','left']],
'Mechanics': [(f'mechanic_{k}',desc,'192×192') for k,desc in [('wall','Solid wall with diagonal hatching'),('redirector','Corner body; turn direction remains live overlay'),('rotator','Circular rotator body; turn direction stays live'),('controlSwitch','Switch body with used/toggle overlays'),('gate','Gate frame; open/closed bars stay independently animated'),('portal','Portal rim; pair label remains live'),('crystal','Faceted crystal body; one/two-hit overlay'),('core','Four-way pulse core'),('reactor','Hex reactor; directional arms remain live'),('magnet','Magnet body; polarity sign remains live'),('polaritySwitch','Polarity toggle body; sign remains live')]]+[('mechanic_magnet_positive','Positive magnet reference/variant','192×192'),('mechanic_magnet_negative','Negative magnet reference/variant','192×192')],
'FX': [('fx_glow_ring','White soft ring, tinted at runtime','256×256'),('fx_pulse_burst','Radial energy burst','256×256'),('fx_trail','Soft white streak, stretched along movement','256×64'),('fx_crystal_shard','Small angular fragment','64×64'),('fx_spark','Small white spark, tinted at runtime','64×64'),('fx_combo','Quiet capsule behind live combo text','512×128'),('fx_completion','Large transparent celebratory radial burst','1024×1024')],
'Themes': [(f'theme_{id}_preview',f'{name}: {style}; same 3×4 preview-board composition','720×600') for id,name,style in [('dark','Dark Matter','cyan/sky/green on midnight'),('neon','Neon Void','violet and magenta on ink'),('prism','Prism Core','pink, aqua and refracted rainbow'),('solar','Solar Flare','gold and coral on warm graphite'),('frost','Frost Signal','icy aqua and pale sky on cold navy')]],
'Rewards': [('reward_energy','Glossy gold energy bolt','192×192'),('reward_star','Rounded dimensional gold star','256×256'),('reward_streak','Coral/magenta flame badge','192×192'),('reward_unlock','Gift/unlock emblem','256×256')],
'Completion': [('completion_crown','Milestone crown illustration','512×512'),('completion_retry','Friendly retry/return emblem','256×256'),('completion_celebration','Star celebration supporting art, no baked text','1024×800')],
'Settings': [('settings_gear','Rounded friendly gear','144×144')]
}
manifest=[]
for group,items in GROUPS.items():
 path=ROOT/'Pulse Shift/Assets.xcassets'/group
 path.mkdir(parents=True,exist_ok=True)
 (path/'Contents.json').write_text(json.dumps({'info':{'author':'xcode','version':1}},indent=2)+'\n')
 for name,purpose,size in items:manifest.append(dict(group=group,name=name,purpose=purpose,sourcePixels=size,status='art-slot'))
(ROOT/'Documentation/AssetManifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
intro='''# PULSE SHIFT — art production specification

The app ships with original code-rendered glossy surfaces, directional pieces and temporary SF Symbols. These are functional fallbacks. Final commissioned/generated artwork is a later production step; no external game's assets are included.

## Delivery contract

Use the exact global asset names below in the corresponding `Assets.xcassets` group. Groups do **not** provide namespaces. Create an imageset when its art arrives; empty groups intentionally create no missing-image warnings. Use sRGB transparent PNG for textures/illustrations, PDF with Preserve Vector Data for scalable line icons, 1×/2×/3× where appropriate. Source dimensions below are pixel targets, not point dimensions. Keep important silhouettes inside the center 84%; leave outer space for glow. Do not bake in copy, counters, arrows, portal IDs, lock states, or stars earned.

Bright-on-dark palette: #071122, #0C1730, #112040, #17284A; accents #35E6FF, #59F2FF, #49A5FF, #8A6BFF, #D95CFF, #5EFFA9, #FFD95A, #FF6A75. Use bold rounded geometry, restrained highlights and readable silhouettes. Text contrast and arrow readability take precedence over shine.

## Integration

`AssetIconPS` and `OptionalArtworkPS` are the SwiftUI substitution points. `SpriteArtPS` caches named textures and generates the fallback shard texture once per color. Existing live hooks include symbol, tabs, chapter/event emblems, reward star, theme previews, background energy, CTA surface, board frame/cells, shard/dormant bases, shared arrow, mechanic bodies and FX sprites. Other slots below are planned art roles: connect them at their named design-system component when final art is approved, with no engine or screen-layout changes.

The board frame has a transparent center, four equal corner margins, and tolerates 5:8 through 8:11 boards. If a bespoke frame cannot stretch cleanly, slice it into corner/edge textures within `GameScenePS`; never scale the logical grid to suit art. `piece_arrow_up` is the authoritative gameplay arrow. The three additional directions are illustration exports. `mechanic_magnet` is the runtime body; positive/negative variants are references for optional presentation expansion. Direction arrows, crystal durability, switch state, reactor arms and polarity signs stay separate and update from deterministic events.

Buttons use live SwiftUI text over an optional clear-center surface. Match corner radii and avoid baking shadows beyond the export padding. Use a nine-slice/cap-inset implementation for final button textures if their decorative edges cannot stretch. SF fallback icons should be replaced progressively, without removing their accessibility labels.

## Asset inventory

| Group | Asset name | Purpose | Source pixels |
|---|---|---|---|
'''
rows='\n'.join(f"| {x['group']} | `{x['name']}` | {x['purpose']} | {x['sourcePixels']} |" for x in manifest)
end='''

## Audio handoff

Bundle optional PCM WAV files named `tap`, `whoosh`, `blocked`, `spark`, `gate`, `portal`, `burst`, `crystalHit`, `crystalBreak`, `combo`, `reward`, `victory`, and `perfect`; use `ambient.m4a` for a seamless quiet music loop. Keep normal feedback short (40–350 ms), portal/reactor under 500 ms, victory under 1.5 s. Avoid clipping and align transients with the corresponding game event. `AudioCuePS` provides typed events; missing files safely produce silence. Sound and music settings remain independent.

## Haptics and performance

`HapticCuePS` defines 13 bounded patterns, including separate tap, blocked, crystal hit/break, gate, portal, reactor, chain, completion and perfect cues. The scene emits feedback at the presentation moment. Core Haptics retains the engine/players, restarts after reset, and falls back to system feedback when unsupported. Respect the Haptics toggle. A real iPhone is required to approve tactile intensity.

Target 60 FPS. Particle bursts are capped against 80 active FX nodes; textures are cached; celebration Canvas runs at 30 Hz only during its reveal. Reduced Effects / system Reduce Motion remove shakes, particle bursts, entrance bounce and large victory waves. Verify final art on the oldest supported iPhone and at small board sizes before replacing the fallbacks. No physics participates in puzzle resolution.
'''
(ROOT/'Documentation/AssetSpecification.md').write_text(intro+rows+end)
print(f'{len(manifest)} asset slots in {len(GROUPS)} catalog groups')
