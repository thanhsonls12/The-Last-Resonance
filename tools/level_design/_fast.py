"""Scratch: fast push-only solver for the search loop.

validate_levels.solve stays the authority for par_moves because it mirrors every
game rule. This one drops doors, portals, elevators, bridges and energy nodes so
the hill-climb can evaluate thousands of plain maps instead of dozens: flat int
indices, dead-square pruning and a frozen-2x2 deadlock test.
"""
import heapq
from itertools import count

DIR_LETTERS = "RLDU"


class Board:
    def __init__(self, rows):
        self.h = len(rows)
        self.w = max(len(r) for r in rows)
        self.open = [False] * (self.w * self.h)
        self.goal = [False] * (self.w * self.h)
        self.boxes = []
        self.player = 0
        for z, row in enumerate(rows):
            for x, glyph in enumerate(row):
                i = z * self.w + x
                if glyph == "#":
                    continue
                self.open[i] = True
                if glyph in ".*+":
                    self.goal[i] = True
                if glyph in "$*":
                    self.boxes.append(i)
                if glyph in "@+":
                    self.player = i
        self.step = [1, -1, self.w, -self.w]
        self.edge = [self._edges(d) for d in range(4)]
        self.goals = [i for i in range(self.w * self.h) if self.goal[i]]
        self.push_cost = self._push_cost()
        self.dead = {i for i in range(self.w * self.h)
                     if self.open[i] and self.push_cost[i] < 0}

    def _edges(self, d):
        """Destination index per cell for direction d, or -1 off the board."""
        out = [-1] * (self.w * self.h)
        for i in range(self.w * self.h):
            if not self.open[i]:
                continue
            x = i % self.w
            if d == 0 and x + 1 >= self.w:
                continue
            if d == 1 and x == 0:
                continue
            j = i + self.step[d]
            if 0 <= j < self.w * self.h and self.open[j]:
                out[i] = j
        return out

    def _push_cost(self):
        """Pushes needed to walk a lone Core to its nearest goal, -1 when never.

        Reverse BFS from the goals over pull moves, ignoring other Cores. A real
        route can only ever need more pushes, so summing this over the Cores is a
        lower bound on remaining pushes and therefore on remaining moves.
        """
        cost = [-1] * (self.w * self.h)
        frontier = []
        for g in self.goals:
            cost[g] = 0
            frontier.append(g)
        while frontier:
            nxt = []
            for cell in frontier:
                for d in range(4):
                    pull = self.edge[d][cell]
                    if pull < 0 or cost[pull] >= 0:
                        continue
                    if self.edge[d][pull] < 0:
                        continue
                    cost[pull] = cost[cell] + 1
                    nxt.append(pull)
            frontier = nxt
        return cost

    def frozen(self, box, boxes):
        """True when box sits in a 2x2 of walls/boxes holding an off-goal box."""
        def solid(i):
            return i < 0 or not self.open[i] or i in boxes

        x, z = box % self.w, box // self.w
        for dx in (-1, 0):
            for dz in (-1, 0):
                cells = []
                for ox in (0, 1):
                    for oz in (0, 1):
                        cx, cz = x + dx + ox, z + dz + oz
                        inside = 0 <= cx < self.w and 0 <= cz < self.h
                        cells.append(cz * self.w + cx if inside else -1)
                if all(solid(c) for c in cells):
                    if any(c in boxes and not self.goal[c] for c in cells):
                        return True
        return False

    def heuristic(self, boxes):
        cost = self.push_cost
        return sum(cost[b] for b in boxes)


def solve_fast(rows, max_states=400_000):
    """(solved, moves, route) for a plain push map, route in RLDU letters."""
    board = Board(rows)
    if len(board.boxes) != len(board.goals):
        return (False, 0, "")
    if any(b in board.dead for b in board.boxes):
        return (False, 0, "")
    start = (board.player, frozenset(board.boxes))
    if all(board.goal[b] for b in start[1]):
        return (True, 0, "")
    best = {start: 0}
    came = {start: None}
    tie = count()
    queue = [(board.heuristic(start[1]), next(tie), start)]
    while queue:
        _f, _t, state = heapq.heappop(queue)
        player, boxes = state
        g = best[state]
        for d in range(4):
            target = board.edge[d][player]
            if target < 0:
                continue
            if target in boxes:
                beyond = board.edge[d][target]
                if beyond < 0 or beyond in boxes or beyond in board.dead:
                    continue
                moved = frozenset(boxes - {target} | {beyond})
                if board.frozen(beyond, moved):
                    continue
                nxt = (target, moved)
            else:
                nxt = (target, boxes)
            if best.get(nxt, 1 << 30) <= g + 1:
                continue
            best[nxt] = g + 1
            came[nxt] = (state, d)
            if all(board.goal[b] for b in nxt[1]):
                return (True, g + 1, _route(came, nxt))
            heapq.heappush(queue, (g + 1 + board.heuristic(nxt[1]), next(tie), nxt))
        if len(best) > max_states:
            return (False, 0, "")
    return (False, 0, "")


def _route(came, state):
    steps = []
    while came[state] is not None:
        state, d = came[state]
        steps.append(DIR_LETTERS[d])
    steps.reverse()
    return "".join(steps)
