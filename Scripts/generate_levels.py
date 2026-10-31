"""Compile individually authored puzzle layouts. No random layouts or mirrored clones."""
import json
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
LEVELS = []
DIRECTIONS = dict(U='up', R='right', D='down', L='left')

def s(id, row, column, direction, polarity=None, dormant=False):
    entity = dict(id=id, kind='dormant' if dormant else 'shard', position=dict(row=row, column=column), direction=DIRECTIONS[direction])
    if polarity: entity['polarity'] = 'positive' if polarity == '+' else 'negative'
    return entity

def e(id, kind, row, column, **configuration):
    return dict(id=id, kind=kind, position=dict(row=row, column=column), **configuration)

def walls(*positions):
    return [e(f'wall-{r}-{c}', 'wall', r, c) for r,c in positions]

def bend(id, row, column, turns=1, circular=False):
    return e(id, 'rotator' if circular else 'redirector', row, column, turns=turns)

def crystal(id, row, column, durability=1):
    return e(id, 'crystal', row, column, durability=durability)

def switch(id, row, column, *links, toggle=False):
    return e(id, 'controlSwitch', row, column, links=list(links), oneShot=not toggle)

def gate(id, row, column): return e(id, 'gate', row, column)
def core(id, row, column): return e(id, 'core', row, column)
def reactor(id, row, column, directions): return e(id, 'reactor', row, column, directions=[DIRECTIONS[d] for d in directions])
def portal(id, row, column, pair, turns=0): return e(id, 'portal', row, column, pair=pair, turns=turns)
def magnet(id, row, column, axis='horizontal', polarity='+', range=8): return e(id, 'magnet', row, column, axis=axis, polarity='positive' if polarity=='+' else 'negative', range=range)
def flip(id, row, column, *links, polarity='+'): return e(id, 'polaritySwitch', row, column, links=list(links), polarity='positive' if polarity=='+' else 'negative')

def level(id, name, size, pieces, solution, intent, tutorial=None, limit=None):
    columns, rows = size
    moves = solution.split()
    item = dict(id=id, chapter=(id-1)//10+1, name=name, columns=columns, rows=rows, parMoves=len(moves), objectives=['clearShards'], entities=pieces, solutionMoves=moves, contentRevision=2, designIntent=intent)
    if any(e['kind'] == 'crystal' for e in pieces): item['objectives'].append('destroyCrystals')
    if any(e['kind'] == 'reactor' for e in pieces): item['objectives'].append('activateReactors')
    if id in [31,32,34,36,38,39,40,46,50,53,57,59,60]: item['objectives'].append('usePortals')
    if tutorial: item['tutorialMessage'] = tutorial
    if limit: item['maxMoves'] = len(moves)+limit
    LEVELS.append(item)

level(1, 'First Spark', (6,9), [s('a',4,2,'U')], 'a', 'One inviting launch in the center.', 'Tap the glowing pulse. Let it fly!')
level(2, 'Go Your Own Way', (6,9), [s('a',3,1,'L'),s('b',6,4,'U')], 'a b', 'Two colors, two directions, no ordering pressure.', 'Every arrow shows its way out.')
level(3, 'You First', (6,9), [s('a',6,1,'U'),s('b',3,1,'R'),s('c',3,4,'U')], 'c b a', 'Three-piece elbow dependency, not a straight row.', 'Clear a path for the next pulse.')
level(4, 'Side Step', (5,8), [s('a',2,3,'D'),s('b',5,3,'L'),s('c',5,1,'U')]+walls((3,4),(4,4)), 'c b a', 'Read the same rule from the opposite edge.')
level(5, 'Tiny Traffic', (6,9), [s('a',6,1,'U'),s('b',3,1,'R'),s('c',3,4,'U'),s('d',1,4,'L')]+walls((4,2),(4,3),(5,2)), 'd c b a', 'Four-link zigzag, with a quiet central island.')
level(6, 'Meet in the Middle', (6,8), [s('a',4,1,'R'),s('b',4,4,'U'),s('c',1,4,'L'),s('d',6,2,'U')], 'c b a d', 'A crossing lane waits for the horizontal pair.')
level(7, 'Around the Corner', (5,8), [s('a',1,1,'D'),s('b',5,1,'R'),s('c',5,3,'U'),s('d',2,3,'R')]+walls((3,2),(4,2)), 'd c b a', 'Compact horseshoe with outward exits.')
level(8, 'Four Corners', (6,9), [s('a',2,1,'R'),s('b',2,4,'D'),s('c',6,4,'L'),s('d',7,1,'U')], 'c b a d', 'The apparent loop has one opening. End of basic onboarding.')
level(9, 'Crossroads', (7,9), [s('a',7,1,'U'),s('b',3,1,'R'),s('c',3,5,'U'),s('d',1,5,'L'),s('f',6,3,'U'),s('g',6,6,'L'),s('h',8,6,'U')]+walls((4,0),(4,4),(5,0),(5,4),(8,0)), 'd c b a f g h', 'Two dependent crossings and an edge follower create a real first-move read.')
level(10, 'Woven Signal', (7,10), [s('a',8,1,'U'),s('b',4,1,'R'),s('c',4,5,'U'),s('d',1,5,'L'),s('f',7,3,'U'),s('g',7,6,'L'),s('h',9,6,'U'),s('i',2,0,'R'),s('j',2,3,'R')]+walls((5,2),(5,4),(6,2),(6,4)), 'd c b a j f g h i', 'Nine pieces interweave around a central island; early partial moves cost stars.', limit=3)

level(11, 'Bend the Light', (6,9), [s('a',5,1,'R'),bend('turn',5,4,-1)]+walls((5,5),(6,5)), 'a', 'One clean redirect introduction.', 'Corner tiles bend your path.')
level(12, 'Double Take', (6,9), [s('a',7,1,'U'),bend('turn-a',4,1),s('b',4,4,'U'),bend('turn-b',1,4)]+walls((3,1),(0,4)), 'b a', 'The second elbow must clear before the first can flow.')
level(13, 'Crack the Code', (6,9), [s('a',5,1,'R'),crystal('crystal',5,3),bend('turn',5,4,-1)]+walls((5,5),(6,3)), 'a a', 'One hit breaks the crystal; the second launch claims the path.', 'Crack the crystal, then launch again.')
level(14, 'Spin Cycle', (7,10), [s('a',7,1,'R'),bend('spin',7,4,-1,True),s('b',4,4,'R'),s('c',4,6,'U')]+walls((7,5),(6,5),(5,5)), 'c b a', 'A rotator follows two crossing blockers.', 'Round tiles spin your direction.')
level(15, 'Untie the Knot', (6,9), [s('a',7,1,'U'),bend('upper',4,1),s('b',4,3,'D'),bend('lower',7,3)]+walls((3,1),(8,3)), 'a b a', 'A setup move vacates the exit of the other piece. Partial movement is the solution.')
level(16, 'Two-Sided Glass', (7,10), [s('a',8,2,'U'),bend('elbow',5,2),crystal('glass',5,5,2),s('b',2,5,'D'),bend('exit',5,6,-1)]+walls((4,2),(6,6)), 'a b a b', 'Two approaches share a reinforced crystal before their paths diverge.')
level(17, 'Return Ticket', (7,10), [s('a',5,1,'R'),s('b',5,3,'U'),bend('return',5,5,2,True),s('c',8,5,'U'),bend('side',2,3,-1),s('d',2,1,'U')]+walls((5,6),(6,6),(7,6)), 'd b a c', 'The turnaround travels twice through a lane; clear its crossing before launching.')
level(18, 'Diamond Cut', (7,10), [s('a',8,1,'U'),bend('a-turn',5,1),crystal('glass-a',5,3),s('b',1,3,'D'),bend('b-turn',7,3,-1),s('c',7,5,'U'),crystal('glass-b',3,5,2),s('d',3,2,'R'),bend('d-turn',3,6,-1)]+walls((4,1),(8,3),(8,6)), 'd c c b a d b', 'Cross-fire breaks two crystals before an inner and outer route can open.', limit=4)
level(19, 'Long Way Home', (7,10), [s('a',8,1,'U'),bend('r1',2,1),bend('r2',2,5),bend('r3',7,5),s('b',2,3,'D'),bend('b-turn',6,3,-1),s('c',6,6,'U'),s('d',1,6,'L')]+walls((0,1),(3,4),(8,5),(4,4),(5,4)), 'd c b a', 'A three-turn perimeter path crosses a shorter inner route.')
level(20, 'Vector Vault', (7,10), [s('a',8,1,'U'),bend('r1',3,1),s('b',3,4,'D'),bend('r2',7,4),s('c',7,2,'U'),bend('r3',5,2),crystal('glass',5,5,2),s('d',1,5,'D'),bend('r4',8,5,-1),s('f',8,6,'U'),s('g',2,6,'L'),s('h',2,3,'U')]+walls((1,1),(8,4),(4,2),(6,0)), 'h g f d d c b a d', 'Chapter test: open the outer exit before unthreading a bent inner circuit.', limit=4)

level(21, 'Open Sesame', (6,9), [s('a',6,0,'R'),switch('S',6,2,'G'),gate('G',2,4),s('b',7,4,'U')], 'a b', 'One switch opens another lane.', 'Cross the green switch to open its gate.')
level(22, 'Key Exchange', (7,10), [s('a',8,1,'U'),bend('r',5,1),switch('S',5,3,'G'),gate('G',2,5),s('b',7,5,'U'),s('c',1,5,'L'),s('d',1,2,'U')]+walls((4,1),(6,3)), 'd c a b', 'The opener itself depends on the exit traffic clearing.')
level(23, 'Heart Beat', (6,9), [s('a',5,0,'R'),core('X',5,2),switch('S',1,2,'G'),gate('G',5,4),crystal('glass',7,2),s('b',8,2,'U')], 'a b', 'The first core simultaneously opens a gate and breaks glass.', 'Cores send energy in four directions.')
level(24, 'Before the Boom', (7,10), [s('a',5,0,'R'),core('X',5,3),switch('S',1,3,'G'),gate('G',5,5),s('b',3,3,'R'),s('c',3,6,'U'),s('d',1,6,'L'),s('f',8,5,'U')]+walls((4,1),(6,1),(7,1)), 'd c b a f', 'Do not fire the core while a normal shard shields the switch.')
level(25, 'Glass Keys', (7,10), [s('a',7,1,'U'),bend('r',4,1),core('X',4,3),switch('S',1,3,'G','G2'),gate('G',4,5),gate('G2',7,5),crystal('glass',6,3,2),s('b',8,3,'U'),s('c',8,5,'U'),s('d',2,5,'L')]+walls((3,1),(5,0)), 'd a b b c', 'Core and shard share a reinforced crystal; the two gates split the payoff.')
level(26, 'The Wrong First Move', (7,10), [s('a',5,0,'R'),core('X',5,3),switch('S',1,3,'G'),gate('G',5,5),s('b',3,3,'R'),gate('G2',3,5),s('c',7,0,'R'),switch('S2',7,1,'G2'),s('d',8,5,'U')]+walls((4,1),(6,1),(8,1)), 'c b a d', 'A switch opens the core shield’s escape. Launching the core first strands it.', limit=3)
level(27, 'Keep It Open', (7,10), [s('a',5,1,'R'),switch('S',5,3,'G',toggle=True),gate('G',2,5),s('b',8,5,'U'),s('c',7,3,'U'),s('d',3,5,'U'),s('f',1,5,'L'),s('g',1,2,'U')]+walls((6,0),(6,1),(6,2),(4,0)), 'g f a d b c', 'Two pieces share a toggle. Clear the gate lane between the two crossings.', 'Striped switches toggle every time. Timing matters.', limit=3)
level(28, 'Three Locks', (7,10), [s('a',5,0,'R'),core('X',5,3),switch('S',1,3,'G','G2','G3'),gate('G',5,5),gate('G2',3,1),gate('G3',7,6),s('b',3,3,'R'),s('c',3,6,'U'),s('d',8,1,'U'),s('f',9,6,'U'),crystal('glass',7,3),s('g',8,3,'U')], 'c b a d f g', 'One carefully prepared core pays off in three separate escape lanes.')
level(29, 'Split Decision', (8,11), [s('a',6,0,'R'),core('X',6,3),switch('S',2,3,'G'),gate('G',6,6),s('b',4,3,'R'),gate('G2',4,6),s('c',9,2,'U'),bend('r',7,2),switch('S2',7,4,'G2'),s('d',7,7,'U'),s('f',1,6,'L'),crystal('glass',6,1),s('g',1,1,'D')]+walls((5,2),(8,0)), 'g g f d c b a', 'Two approach lanes, two locks and an initially obstructed launcher.', limit=4)
level(30, 'Circuit Symphony', (8,11), [s('a',6,0,'R'),core('X',6,3),switch('S',2,3,'G','G3'),gate('G',6,6),gate('G3',3,6),s('b',4,3,'R'),gate('G2',4,6),s('c',8,1,'R'),switch('S2',8,3,'G2'),s('d',8,6,'U'),s('f',1,6,'L'),s('g',1,2,'D'),bend('r1',3,2,1),crystal('glass',3,5),s('h',0,5,'D'),bend('r2',9,5,-1)]+walls((5,1),(5,2),(7,1),(7,2)), 'h g f c b a d c h', 'Multi-stage lock sequence around a central pulse highway.', limit=4)

level(31, 'Shortcut', (6,9), [s('a',6,0,'R'),portal('P',6,3,'pair',-1),portal('Q',3,4,'pair')]+walls((6,4),(5,4)), 'a', 'A single unmistakable portal trip.', 'Paired portals carry your pulse across the board.')
level(32, 'Exit Traffic', (7,10), [s('a',8,1,'U'),portal('P',5,1,'pair',1),portal('Q',3,3,'pair'),s('b',3,5,'D'),bend('r',7,5),s('c',7,2,'U'),s('d',1,2,'R')]+walls((4,1),(8,5)), 'd c b a', 'Read the exit of the portal before its entrance.')
level(33, 'Wake Up', (6,9), [s('a',5,0,'R'),core('X',5,3),s('sleep',2,3,'R',dormant=True),s('b',2,5,'U')], 'b a', 'Clear the sleepy pulse’s escape before waking it.', 'Energy wakes sleeping pulses and launches them.')
level(34, 'Long Distance Call', (7,10), [s('a',8,1,'U'),portal('P',5,1,'pair',1),portal('Q',4,3,'pair'),core('X',4,5),s('sleep',1,5,'L',dormant=True),s('b',1,2,'D'),bend('r',7,2,-1),s('c',7,6,'U'),s('d',2,6,'L')]+walls((3,1),(8,2)), 'd c b a', 'An exit-side core reaches a sleeper behind the original route.')
level(35, 'Wake in Order', (7,10), [s('a',5,0,'R'),core('X',5,3),s('top',2,3,'R',dormant=True),s('bottom',8,3,'L',dormant=True),s('b',2,5,'D'),gate('G',6,5),s('c',7,0,'R'),switch('S',7,2,'G'),s('d',8,1,'U'),crystal('glass',4,1)]+walls((6,0)), 'd d c b a', 'Unlock the upper sleeper’s path and clear the lower crossing before the payoff.', limit=3)
level(36, 'Two Worlds', (8,11), [s('a',9,1,'U'),portal('P',6,1,'pair',1),portal('Q',3,4,'pair'),s('b',3,6,'D'),portal('R',7,6,'pair2',1),portal('T',8,4,'pair2'),s('c',8,2,'U'),bend('r',2,2),s('d',2,5,'U'),crystal('glass',1,5,2)]+walls((5,1),(8,6),(1,2)), 'd d d c b a', 'Two portal pairs weave a return path through reinforced glass.', limit=3)
level(37, 'Sleeping Giant', (7,10), [s('a',5,0,'R'),core('X',5,3),s('sleep',1,3,'R',dormant=True),s('b',3,3,'R'),gate('G',3,5),s('c',8,1,'U'),bend('r',6,1),switch('S',6,3,'G'),s('d',6,5,'U'),s('f',1,5,'U'),crystal('glass',5,6)]+walls((4,1)), 'f c b d c a', 'The obvious core launch is premature: the sleeper is shielded by a locked piece.')
level(38, 'Phase Carousel', (8,11), [s('a',9,1,'U'),portal('P',6,1,'pair',1),portal('Q',4,3,'pair'),core('X',4,5),s('sleep',1,5,'L',dormant=True),s('b',1,2,'D'),bend('r',7,2,-1),s('c',7,6,'U'),crystal('glass',3,6,2),s('d',3,4,'R'),s('f',9,7,'U')]+walls((5,1),(8,2),(6,4)), 'd c c b d f a', 'A cross-fire crystal protects the remote sleeping route.', limit=4)
level(39, 'Quiet Before', (8,11), [s('a',6,0,'R'),core('X',6,3),s('top',2,3,'R',dormant=True),s('bottom',9,3,'L',dormant=True),s('b',4,3,'R'),gate('G',4,6),s('c',8,1,'U'),portal('P',5,1,'pair',1),portal('Q',7,4,'pair'),switch('S',7,5,'G'),s('d',2,6,'U'),bend('r',8,6),s('f',9,1,'U')]+walls((4,1),(10,0)), 'd c f b a', 'Portal key, shield removal, then a two-wing wake-up.', limit=4)
level(40, 'Across the Universe', (8,11), [s('a',6,0,'R'),core('X',6,3),s('north',2,3,'R',dormant=True),portal('P',2,5,'p',1),portal('Q',3,6,'p'),s('south',9,3,'L',dormant=True),s('b',4,3,'R'),gate('G',4,6),s('c',8,1,'U'),bend('r',5,1),switch('S',5,4,'G'),s('d',5,7,'U'),crystal('glass',1,7,2),s('f',9,1,'U'),s('g',7,7,'L'),s('h',7,5,'D')]+walls((4,1),(10,0)), 'd d d c b h g f a', 'A chapter finale with a portal sleeper, two shielded lanes and a prepared double clear.', limit=4)

level(41, 'A Little Pull', (6,9), [s('a',5,2,'U','+'),magnet('M',5,5),flip('F',7,4,'M')]+walls((4,2)), 'F a', 'One polarity flip pulls the pulse out from behind its wall.', 'Tap ± to flip the magnet. Opposites attract; matching signs repel.')
level(42, 'Push and Pull', (7,10), [s('a',6,2,'U','+'),s('b',6,5,'D','-'),magnet('M',6,6),flip('F',8,5,'M')]+walls((5,2),(7,5)), 'F a b', 'Opposite signs move in opposite directions together.')
level(43, 'Wait for Space', (7,10), [s('a',6,2,'U','+'),s('b',6,3,'U'),s('c',2,3,'R'),s('d',2,6,'U'),magnet('M',6,6),flip('F',8,5,'M')]+walls((5,2),(7,2),(8,2)), 'd c b F a', 'Make room for the magnetic destination before flipping. Occupied cells reject the shift.', limit=3)
level(44, 'Vertical Thinking', (7,10), [s('a',6,3,'R','+'),magnet('M',2,3,'vertical'),flip('F',9,6,'M'),s('b',5,5,'U'),gate('G',2,5),s('c',8,0,'R'),switch('S',8,2,'G'),crystal('glass',1,5)]+walls((6,4)), 'c b b F a', 'Vertical attraction lifts the pulse into a gate-controlled exit.')
level(45, 'Double Lock', (8,11), [s('a',7,2,'U','+'),s('b',7,3,'U'),s('c',3,3,'R'),gate('G',3,6),s('d',9,0,'R'),switch('S',9,4,'G'),magnet('M',7,6),flip('F',10,7,'M'),s('f',1,3,'D'),bend('r',5,3,-1),s('g',5,6,'U')]+walls((6,2),(8,2),(6,4)), 'd c g f b F a', 'A gate, crossing and destination blocker must clear before attraction is useful.', limit=4)
level(46, 'Repulsion Route', (7,10), [s('a',6,3,'U','-'),magnet('M',6,6),flip('F',8,5,'M'),portal('P',3,2,'p',1),portal('Q',2,4,'p'),s('b',2,5,'D'),bend('r',7,5),s('c',7,0,'U'),crystal('glass',4,0,2)]+walls((5,3),(8,4)), 'c c c b F a', 'Repel into a portal lane after unblocking its far end.', limit=3)
level(47, 'Magnetic Key', (8,11), [s('a',6,2,'U','+'),magnet('M',6,6),flip('F',9,6,'M'),switch('S',3,3,'G'),gate('G',7,5),s('b',9,5,'U'),s('c',4,5,'L'),s('d',4,1,'U'),crystal('glass',1,1,2),s('f',1,7,'L')]+walls((5,2)), 'd d d c F a b f', 'A shifted pulse becomes the key to a second, perpendicular route.')
level(48, 'Opposite Ends', (8,11), [s('a',7,2,'U','+'),s('b',3,5,'D','-'),magnet('M',7,7),magnet('N',3,1),flip('F',9,4,'M','N'),s('c',7,3,'U'),gate('G',4,3),s('d',1,0,'R'),switch('S',1,2,'G'),s('f',8,6,'L'),s('g',8,0,'U')]+walls((6,2),(4,5)), 'd c g f F a b', 'One flip controls two fields. Their landing spaces belong to different dependency chains.', limit=4)
level(49, 'Move the Shield', (8,11), [s('a',6,0,'R'),core('X',6,3),s('sleep',1,3,'R',dormant=True),s('b',3,3,'U','+'),magnet('M',3,7),flip('F',9,6,'M'),s('c',3,4,'D'),bend('r',8,4),s('d',8,1,'U'),crystal('glass',4,1,2),s('f',1,6,'D'),bend('r2',7,6)]+walls((0,3),(9,4)), 'd d d c F b f a', 'Shift a wall-bound shield off the core beam, then fire the sleeping payoff.', limit=4)
level(50, 'Field of Dreams', (8,11), [s('a',6,0,'R'),core('X',6,3),s('sleep',1,3,'R',dormant=True),s('b',3,3,'U','+'),magnet('M',3,7),flip('F',10,6,'M'),s('c',3,4,'D'),gate('G',7,4),s('d',9,1,'R'),switch('S',9,3,'G'),s('f',9,6,'U'),crystal('glass',5,6,2),s('g',1,6,'D'),portal('P',8,6,'p',1),portal('Q',8,2,'p')]+walls((0,3),(4,1),(5,1)), 'f g g g d c F b a', 'A portal exit, reinforced crystal, gate and magnetic shield form one connected puzzle.', limit=4)

level(51, 'Ignition', (7,10), [s('a',6,0,'R'),core('X',6,3),reactor('R',3,3,'LR'),s('left',3,1,'U',dormant=True),s('right',3,5,'U',dormant=True),s('b',1,5,'L'),s('c',1,1,'U'),bend('r',7,1,-1)], 'c b a', 'One directional reactor tutorial embedded in an ordering puzzle.', 'Reactors send energy along their marked arms.')
level(52, 'Prepare the Party', (8,11), [s('a',6,0,'R'),core('X',6,3),reactor('R',2,3,'LR'),s('left',2,1,'U',dormant=True),s('right',2,6,'U',dormant=True),s('b',4,3,'R'),gate('G',4,6),s('c',9,0,'R'),switch('S',9,2,'G'),s('d',7,6,'L'),s('f',7,1,'U'),crystal('glass',4,1,2),bend('exit',3,1,-1)], 'f f f d c b a', 'Clear two celebration routes, unlock the shield, then send a branching burst.', limit=4)
level(53, 'A Remote Spark', (8,11), [s('a',9,1,'U'),portal('P',6,1,'p',1),portal('Q',5,3,'p'),core('X',5,5),reactor('R',2,5,'LR'),s('left',2,2,'U',dormant=True),s('right',2,7,'U',dormant=True),s('b',7,2,'R'),s('c',7,7,'U'),crystal('glass',4,7,2),bend('exit',3,7),s('d',4,4,'R'),s('f',9,6,'U')]+walls((5,1),(8,2)), 'd c c b d f a', 'A remote reactor rewards clearing an intersecting reinforced route.', limit=4)
level(54, 'Over and Under', (8,11), [s('a',6,0,'R'),core('X',6,3),reactor('R',2,3,'LR'),s('left',2,1,'U',dormant=True),s('right',2,6,'U',dormant=True),s('b',4,3,'U','+'),magnet('M',4,7),flip('F',10,6,'M'),s('c',4,4,'D'),gate('G',8,4),s('d',9,0,'R'),switch('S',9,2,'G'),s('f',7,1,'R'),s('g',7,6,'U'),crystal('glass',5,6),bend('exit',3,6)]+walls((0,3)), 'g g f d c F b a', 'Move a magnetic shield after unlocking its landing space and both reactor exits.', limit=4)
level(55, 'Counter Current', (8,11), [s('a',6,0,'R'),core('X',6,3),reactor('R',2,3,'LR'),s('left',2,1,'U',dormant=True),s('right',2,6,'U',dormant=True),s('b',4,3,'R'),gate('G',4,6),s('c',9,0,'R'),switch('S',9,2,'G',toggle=True),s('d',10,2,'U'),s('f',7,6,'L'),s('g',7,1,'U'),crystal('glass',5,1,2),bend('exit',3,1,-1),portal('P',8,6,'p',1),portal('Q',8,3,'p')], 'g g g f c b a d', 'A toggle window and a return portal demand careful sequencing before the burst.', limit=4)
level(56, 'Starlight Engine', (8,11), [s('a',6,0,'R'),core('X',6,3),reactor('R',2,3,'LR'),reactor('T',9,3,'LR'),s('nw',2,1,'U',dormant=True),s('ne',2,6,'U',dormant=True),s('sw',9,1,'D',dormant=True),s('se',9,6,'D',dormant=True),s('b',4,3,'R'),gate('G',4,6),s('c',7,0,'R'),switch('S',7,2,'G'),s('d',7,6,'U'),crystal('glass',5,6,2),bend('exit',3,6),s('f',1,6,'L'),s('g',1,1,'U'),bend('r',5,1,-1)]+walls((10,0)), 'g f d d c b d a', 'Two reactors send four sleepers into a star-shaped finale after a glass-and-lock setup.', limit=4)
level(57, 'Prism Express', (8,11), [s('a',6,0,'R'),core('X',6,3),reactor('R',2,3,'LR'),reactor('T',9,3,'LR'),s('nw',2,1,'U',dormant=True),s('ne',2,6,'D',dormant=True),s('sw',9,1,'D',dormant=True),s('se',9,6,'U',dormant=True),portal('P',4,6,'p',1),portal('Q',7,5,'p'),s('b',4,3,'R'),gate('G',4,5),s('c',7,0,'R'),switch('S',7,2,'G'),s('d',7,4,'U'),crystal('glass',3,4,2),s('f',1,1,'R'),s('g',1,7,'D')], 'g f d d d c b a', 'Opposing sleeper trains use a portal crossing after the central station clears.', limit=4)
level(58, 'Magnetic Orchestra', (8,11), [s('a',6,0,'R'),core('X',6,3),reactor('R',2,3,'LR'),reactor('T',9,3,'LR'),s('nw',2,1,'U',dormant=True),s('ne',2,6,'U',dormant=True),s('sw',9,1,'D',dormant=True),s('se',9,6,'D',dormant=True),s('b',4,3,'U','+'),magnet('M',4,7),flip('F',10,7,'M'),s('c',4,4,'D'),gate('G',8,4),s('d',7,0,'R'),switch('S',7,2,'G'),s('f',7,6,'U'),crystal('glass',5,6,2),bend('exit',3,6),s('g',1,6,'L'),s('h',1,1,'U'),bend('r',5,1,-1)]+walls((0,3)), 'h g f f f d c F b a', 'A magnetic conductor releases the two-reactor orchestra only after its audience lanes clear.', limit=4)
level(59, 'Supernova', (8,11), [s('a',6,0,'R'),core('X',6,3),reactor('R',2,3,'LR'),reactor('T',9,3,'LR'),s('nw',2,1,'U',dormant=True),s('ne',2,6,'U',dormant=True),s('sw',9,1,'D',dormant=True),s('se',9,6,'D',dormant=True),s('b',4,3,'R'),gate('G',4,6),s('c',10,2,'U'),switch('S',7,2,'G'),s('d',7,6,'U','+'),magnet('M',7,1),flip('F',10,7,'M'),s('f',7,5,'U'),crystal('glass',6,5,2),s('g',1,6,'L'),s('h',1,1,'U'),bend('r',5,1,-1),portal('P',4,5,'p',-1),portal('Q',8,7,'p')]+walls((0,0)), 'h g f f f F d c b a', 'Shift the key lane sideways, route through a portal, then release the starburst.', limit=4)
level(60, 'Full Spectrum', (8,11), [s('a',6,0,'R'),core('X',6,3),reactor('R',2,3,'LR'),reactor('T',9,3,'LR'),reactor('E',6,6,'UD'),s('nw',2,1,'U',dormant=True),s('ne',2,5,'U',dormant=True),s('sw',9,1,'D',dormant=True),s('se',9,5,'D',dormant=True),s('east-up',3,6,'R',dormant=True),s('east-down',8,6,'R',dormant=True),s('b',4,3,'U','+'),magnet('M',4,7),flip('F',10,7,'M'),s('c',4,4,'D'),gate('G',8,4),s('d',7,0,'R'),switch('S',7,2,'G'),s('f',7,5,'U'),crystal('glass',5,5,2),bend('exit',3,5,-1),s('g',1,5,'L'),s('h',1,1,'U'),bend('r',5,1,-1),portal('P',3,7,'p'),portal('Q',8,7,'p')]+walls((0,3)), 'h g f f f d c F b a', 'Pack milestone: clear the conductor, align the field and ignite three reactors plus six sleepers in one final move.', limit=4)

if __name__ == '__main__':
    assert len(LEVELS) == 60
    for chapter in range(1,7):
        path = ROOT / 'Pulse Shift' / 'Data' / f'levels_chapter_{chapter:02}.json'
        path.write_text(json.dumps([x for x in LEVELS if x['chapter']==chapter], indent=2)+'\n')
    print('Wrote 60 authored levels.')
