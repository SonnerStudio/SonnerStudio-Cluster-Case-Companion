"""Warteschlange für Bildaufträge.

Für ein Bild muss das Sprachmodell entladen werden (~50 s). Damit Agenten nicht mitten
in einer Arbeitssitzung ausgebremst werden, wartet ein Bildauftrag, bis seit
`idle_s` Sekunden keine Chat-Anfrage mehr kam und keine läuft – höchstens aber
`max_wait_s` Sekunden. Mehrere wartende Bilder werden am Stück erzeugt, das
Sprachmodell wird erst danach wieder geladen.
"""

import asyncio
import time


class ImageScheduler:
    def __init__(self, idle_s: float = 30.0, max_wait_s: float = 300.0, clock=time.monotonic):
        self.idle_s = idle_s
        self.max_wait_s = max_wait_s
        self.clock = clock
        self.last_chat = 0.0
        self.active_chats = 0
        self.waiting = 0            # Bildaufträge in der Warteschlange
        self.running = 0            # gerade erzeugte Bilder

    # Chat-Verkehr melden
    def chat_started(self):
        self.active_chats += 1
        self.last_chat = self.clock()

    def chat_finished(self):
        self.active_chats = max(0, self.active_chats - 1)
        self.last_chat = self.clock()

    def idle_for(self) -> float:
        return self.clock() - self.last_chat

    def may_start(self, waited: float) -> bool:
        """Darf ein Bild jetzt beginnen?"""
        if waited >= self.max_wait_s:
            return True
        return self.active_chats == 0 and self.idle_for() >= self.idle_s

    async def wait_turn(self, poll: float = 1.0, urgent: bool = False):
        """Wartet, bis der Bildauftrag starten darf. Gibt die Wartezeit zurück."""
        self.waiting += 1
        start = self.clock()
        try:
            while not urgent and not self.may_start(self.clock() - start):
                await asyncio.sleep(poll)
        finally:
            self.waiting -= 1
        return self.clock() - start

    def snapshot(self) -> dict:
        return {"waiting": self.waiting, "running": self.running, "active_chats": self.active_chats,
                "idle_s": round(self.idle_for(), 1), "idle_needed_s": self.idle_s, "max_wait_s": self.max_wait_s}
