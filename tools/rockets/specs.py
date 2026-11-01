"""
specs.py — les 40 fusées, 4 mondes × 10, d'après l'image de référence.

Chaque spec :
  id, key (nom technique), name (nom affiché FR), world (1-4),
  finish : paint | metal | chrome | wood | crystal | matte
  body   : kind (cyl, taper, capsule, barrel, bullet, stage2, stage3, waist, crystal), h, r, r2
  nose   : kind (cone, ogive, dome, spike, blunt, crystal), h
  fins   : n, kind (tri, swept, delta, blade, wing, stub, crystal), size, z (0-1 sur le corps), tip_glow
  window : n, r, z, gap ; cockpit : z, r, len
  nozzles, nozzle_h, nozzle_r ; boosters : n, r, h, z, nose
  bands  : [ {z, h, color, glow} ] ; rings : [ {z, scale, thick, color, glow} ]
  halos  : [ {z, R, thick, color, tilt} ] ; panels : {z, len, w}
  antenna: {h} ; dish : {z, R, tilt} ; saucer : {z, R, thick, lights} ; dome : {z, r}
  legs   : {n, len} ; spikes : {n, z, len, r, up, glow}
  colors : body, accent, nose, fins, window, nozzle, glow, metal, panel, flame
  aura   : color (hex), strength (0.3 → 3.0)  -> intensité de l'aura (Neon/Highlight/Particules côté Roblox)
  stats  : multiplier (distance), cost (Wins) — valeurs d'équilibrage de départ
"""

W1_AURA = 0.45
W2_AURA = 0.9
W3_AURA = 1.5
W4_AURA = 2.4

SPECS = [
    # ===================================================================
    # MONDE 1 — DÉBUTANT : fusées simples, bricolées et légères
    # ===================================================================
    dict(id=1, key="WoodenDart", name="Dard de bois", world=1, finish="wood",
         body=dict(kind="taper", h=4.2, r=0.75, r2=0.55), nose=dict(kind="cone", h=2.6),
         fins=dict(n=3, kind="tri", size=0.8), nozzles=1, nozzle_h=0.5, nozzle_r=0.3,
         bands=[dict(z=0.35, h=0.25, color="accent"), dict(z=0.7, h=0.25, color="accent")],
         colors=dict(body="#6B4A2B", accent="#3D2A17", nose="#4A3220", fins="#5A3E26", nozzle="#2B2B2B", glow="#FFB04A", flame="#FF9A1F"),
         aura=dict(color="#FFB04A", strength=0.3), stats=dict(multiplier=1.0, cost=0)),

    dict(id=2, key="BrassBarrel", name="Tonneau de cuivre", world=1, finish="metal",
         body=dict(kind="barrel", h=4.0, r=1.15), nose=dict(kind="dome", h=1.1),
         fins=dict(n=3, kind="stub", size=0.8), window=dict(n=1, r=0.42, z=0.6), nozzles=1, nozzle_h=0.6, nozzle_r=0.4,
         rings=[dict(z=0.2, scale=1.03, thick=0.08, color="metal"), dict(z=0.8, scale=1.03, thick=0.08, color="metal")],
         colors=dict(body="#8C6D4A", accent="#5C4630", nose="#5C4630", fins="#5C4630", window="#8FE3FF", nozzle="#3A3A3A", metal="#4E4A44", glow="#FFC46B", flame="#FF9A1F"),
         aura=dict(color="#FFC46B", strength=0.35), stats=dict(multiplier=1.3, cost=150)),

    dict(id=3, key="OrangePod", name="Capsule orange", world=1, finish="paint",
         body=dict(kind="capsule", h=3.8, r=1.0), nose=dict(kind="dome", h=1.2),
         fins=dict(n=3, kind="stub", size=0.9), window=dict(n=1, r=0.45, z=0.62), nozzles=1, nozzle_h=0.6,
         colors=dict(body="#FF7A1A", accent="#2E2E2E", nose="#FF7A1A", fins="#2E2E2E", window="#9BE8FF", glow="#FFD27A", flame="#FFB300"),
         aura=dict(color="#FFD27A", strength=0.4), stats=dict(multiplier=1.7, cost=400)),

    dict(id=4, key="ClassicWhite", name="Classique blanche", world=1, finish="paint",
         body=dict(kind="cyl", h=4.6, r=0.9), nose=dict(kind="ogive", h=2.0),
         fins=dict(n=4, kind="tri", size=0.9), window=dict(n=1, r=0.38, z=0.65), nozzles=1, nozzle_h=0.7,
         bands=[dict(z=0.15, h=0.5, color="accent")],
         colors=dict(body="#F4F4F4", accent="#FF6A00", nose="#FF6A00", fins="#FF6A00", window="#7FFFB0", glow="#FFD27A", flame="#FFB300"),
         aura=dict(color="#FFD27A", strength=0.45), stats=dict(multiplier=2.2, cost=900)),

    dict(id=5, key="SkyBlue", name="Bleu ciel", world=1, finish="paint",
         body=dict(kind="cyl", h=4.8, r=0.9), nose=dict(kind="ogive", h=2.2),
         fins=dict(n=4, kind="swept", size=0.85), window=dict(n=2, r=0.32, z=0.7, gap=0.2), nozzles=1, nozzle_h=0.7,
         bands=[dict(z=0.1, h=0.6, color="accent")],
         colors=dict(body="#F4F4F4", accent="#2F7BFF", nose="#2F7BFF", fins="#2F7BFF", window="#9BE8FF", glow="#8FC8FF", flame="#FFB300"),
         aura=dict(color="#8FC8FF", strength=0.5), stats=dict(multiplier=2.8, cost=1800)),

    dict(id=6, key="TallNeedle", name="Aiguille blanche", world=1, finish="paint",
         body=dict(kind="cyl", h=5.6, r=0.75), nose=dict(kind="spike", h=2.6),
         fins=dict(n=3, kind="swept", size=0.8), window=dict(n=1, r=0.3, z=0.72), nozzles=1, nozzle_h=0.7, collar=True,
         colors=dict(body="#F6F6F6", accent="#2F7BFF", nose="#2F7BFF", fins="#D9D9D9", window="#9BE8FF", glow="#8FC8FF", flame="#FFB300"),
         aura=dict(color="#8FC8FF", strength=0.5), stats=dict(multiplier=3.5, cost=3500)),

    dict(id=7, key="TwinOrange", name="Double orange", world=1, finish="paint",
         body=dict(kind="cyl", h=4.4, r=0.85), nose=dict(kind="ogive", h=1.8),
         fins=dict(n=3, kind="tri", size=0.7), window=dict(n=1, r=0.32, z=0.68), nozzles=1, nozzle_h=0.7,
         boosters=dict(n=2, r=0.38, h=2.6, offset=0, color="body", nose_color="accent"),
         colors=dict(body="#F4F4F4", accent="#FF6A00", nose="#FF6A00", fins="#FF6A00", window="#9BE8FF", glow="#FFD27A", flame="#FFB300"),
         aura=dict(color="#FFD27A", strength=0.5), stats=dict(multiplier=4.3, cost=6500)),

    dict(id=8, key="NavySleek", name="Marine furtive", world=1, finish="metal",
         body=dict(kind="bullet", h=5.0, r=0.95), nose=dict(kind="ogive", h=2.0),
         fins=dict(n=4, kind="blade", size=0.8), window=dict(n=1, r=0.3, z=0.7), nozzles=1, nozzle_h=0.7,
         boosters=dict(n=2, r=0.32, h=2.4, offset=0, color="metal", nose_color="metal"),
         colors=dict(body="#1E2A5A", accent="#C9CED6", nose="#C9CED6", fins="#C9CED6", window="#9BE8FF", metal="#9AA0A8", glow="#8FC8FF", flame="#FFB300"),
         aura=dict(color="#8FC8FF", strength=0.55), stats=dict(multiplier=5.4, cost=12000)),

    dict(id=9, key="BigFin", name="Grands ailerons", world=1, finish="paint",
         body=dict(kind="cyl", h=5.0, r=0.9), nose=dict(kind="ogive", h=2.2),
         fins=dict(n=4, kind="delta", size=0.95), window=dict(n=1, r=0.34, z=0.7), nozzles=1, nozzle_h=0.75,
         bands=[dict(z=0.5, h=0.35, color="accent")],
         colors=dict(body="#F4F4F4", accent="#FF6A00", nose="#FF6A00", fins="#FF6A00", window="#9BE8FF", glow="#FFD27A", flame="#FFB300"),
         aura=dict(color="#FFD27A", strength=0.6), stats=dict(multiplier=6.8, cost=22000)),

    dict(id=10, key="SunsetSwept", name="Couchant", world=1, finish="paint",
         body=dict(kind="taper", h=5.2, r=0.95, r2=0.75), nose=dict(kind="ogive", h=2.0),
         fins=dict(n=3, kind="wing", size=0.8), window=dict(n=1, r=0.32, z=0.72), nozzles=1, nozzle_h=0.75,
         bands=[dict(z=0.25, h=0.4, color="body"), dict(z=0.85, h=0.3, color="body")],
         colors=dict(body="#FF7A1A", accent="#F4F4F4", nose="#F4F4F4", fins="#F4F4F4", window="#9BE8FF", glow="#FFD27A", flame="#FFB300"),
         aura=dict(color="#FFD27A", strength=0.65), stats=dict(multiplier=8.5, cost=40000)),

    # ===================================================================
    # MONDE 2 — TECHNOLOGIE : fusées améliorées, plus rapides et stables
    # ===================================================================
    dict(id=11, key="OrbiterDish", name="Orbiteur à parabole", world=2, finish="metal",
         body=dict(kind="waist", h=3.2, r=1.0, r2=0.9), nose=dict(kind="blunt", h=0.6),
         fins=dict(n=4, kind="stub", size=0.7), window=dict(n=2, r=0.25, z=0.55, gap=0.0, angle=-90), nozzles=1, nozzle_h=0.7,
         dish=dict(z=1.0, dz=0.6, R=1.3), legs=dict(n=3, len=1.6),
         colors=dict(body="#C9CED6", accent="#FF6A00", nose="#8A9099", fins="#8A9099", window="#5EC8FF", metal="#6F757D", glow="#5EC8FF", flame="#FF9A1F"),
         aura=dict(color="#5EC8FF", strength=0.8), stats=dict(multiplier=11, cost=75000)),

    dict(id=12, key="SolarSat", name="Satellite solaire", world=2, finish="metal",
         body=dict(kind="cyl", h=3.4, r=0.85), nose=dict(kind="dome", h=0.9),
         panels=dict(z=0.55, len=2.4, w=1.0), antenna=dict(h=1.1), nozzles=1, nozzle_h=0.7,
         window=dict(n=1, r=0.3, z=0.6), fins=dict(n=3, kind="stub", size=0.6),
         colors=dict(body="#D9DDE3", accent="#FF6A00", nose="#8A9099", fins="#8A9099", window="#5EC8FF", metal="#6F757D", panel="#1E3A8A", glow="#5EC8FF", flame="#FF9A1F"),
         aura=dict(color="#5EC8FF", strength=0.85), stats=dict(multiplier=14, cost=140000)),

    dict(id=13, key="SilverArrow", name="Flèche d'argent", world=2, finish="chrome",
         body=dict(kind="cyl", h=5.0, r=0.8), nose=dict(kind="spike", h=2.4),
         fins=dict(n=4, kind="swept", size=0.9, tip_glow=True), window=dict(n=1, r=0.3, z=0.7), nozzles=1, nozzle_h=0.7,
         bands=[dict(z=0.95, h=0.3, color="accent")],
         colors=dict(body="#C9CED6", accent="#FF6A00", nose="#FF6A00", fins="#C9CED6", window="#5EC8FF", glow="#FF9A1F", flame="#FF9A1F"),
         aura=dict(color="#FF9A1F", strength=0.9), stats=dict(multiplier=18, cost=260000)),

    dict(id=14, key="AzureJet", name="Jet azur", world=2, finish="paint",
         body=dict(kind="bullet", h=5.2, r=0.9), nose=dict(kind="ogive", h=2.4),
         fins=dict(n=3, kind="delta", size=0.85), window=dict(n=1, r=0.32, z=0.72), nozzles=1, nozzle_h=0.75,
         bands=[dict(z=0.3, h=0.3, color="accent", glow=True)],
         colors=dict(body="#F4F4F4", accent="#2F7BFF", nose="#2F7BFF", fins="#2F7BFF", window="#5EC8FF", glow="#5EC8FF", flame="#5EC8FF"),
         aura=dict(color="#5EC8FF", strength=0.9), stats=dict(multiplier=23, cost=480000)),

    dict(id=15, key="TwinStack", name="Double étage", world=2, finish="metal",
         body=dict(kind="stage2", h=5.4, r=1.0, r2=0.75), nose=dict(kind="blunt", h=1.4),
         fins=dict(n=4, kind="stub", size=0.9), window=dict(n=1, r=0.3, z=0.8), nozzles=3, nozzle_h=0.75,
         rings=[dict(z=0.55, scale=1.08, thick=0.1, color="accent")],
         colors=dict(body="#8A9099", accent="#FF6A00", nose="#F4F4F4", fins="#FF6A00", window="#5EC8FF", metal="#6F757D", glow="#FF9A1F", flame="#FF9A1F"),
         aura=dict(color="#FF9A1F", strength=0.95), stats=dict(multiplier=30, cost=900000)),

    dict(id=16, key="StratoWing", name="Aile strato", world=2, finish="paint",
         body=dict(kind="bullet", h=5.4, r=0.9), nose=dict(kind="ogive", h=2.2),
         fins=dict(n=2, kind="wing", size=1.0, offset=0), cockpit=dict(z=0.7, r=0.4, len=2.2), nozzles=1, nozzle_h=0.75,
         bands=[dict(z=0.4, h=0.3, color="accent")],
         colors=dict(body="#F4F4F4", accent="#2F7BFF", nose="#2F7BFF", fins="#2F7BFF", window="#5EC8FF", glow="#5EC8FF", flame="#5EC8FF"),
         aura=dict(color="#5EC8FF", strength=1.0), stats=dict(multiplier=38, cost=1.7e6)),

    dict(id=17, key="ClusterCore", name="Cœur en grappe", world=2, finish="metal",
         body=dict(kind="cyl", h=4.6, r=0.8), nose=dict(kind="ogive", h=1.6),
         fins=dict(n=4, kind="stub", size=0.7), window=dict(n=1, r=0.28, z=0.7), nozzles=1, nozzle_h=0.75,
         boosters=dict(n=4, r=0.36, h=3.0, offset=45, color="accent", nose_color="nose"),
         colors=dict(body="#8A9099", accent="#2F7BFF", nose="#F4F4F4", fins="#2F7BFF", window="#5EC8FF", metal="#6F757D", glow="#5EC8FF", flame="#5EC8FF"),
         aura=dict(color="#5EC8FF", strength=1.0), stats=dict(multiplier=48, cost=3.2e6)),

    dict(id=18, key="HaloProbe", name="Sonde à halo", world=2, finish="chrome",
         body=dict(kind="cyl", h=4.8, r=0.8), nose=dict(kind="spike", h=2.2),
         fins=dict(n=3, kind="blade", size=0.75), window=dict(n=1, r=0.3, z=0.7), nozzles=1, nozzle_h=0.75,
         halos=[dict(z=0.5, R=2.0, thick=0.12, color="glow")],
         colors=dict(body="#C9CED6", accent="#FF6A00", nose="#C9CED6", fins="#C9CED6", window="#5EC8FF", glow="#FF9A1F", flame="#FF9A1F"),
         aura=dict(color="#FF9A1F", strength=1.05), stats=dict(multiplier=60, cost=6e6)),

    dict(id=19, key="CobaltTower", name="Tour cobalt", world=2, finish="paint",
         body=dict(kind="stage3", h=6.2, r=0.95, r2=0.7), nose=dict(kind="ogive", h=2.0),
         fins=dict(n=4, kind="swept", size=0.8, tip_glow=True), window=dict(n=2, r=0.28, z=0.9, gap=0.18), nozzles=1, nozzle_h=0.8,
         colors=dict(body="#2F7BFF", accent="#F4F4F4", nose="#F4F4F4", fins="#F4F4F4", window="#5EC8FF", glow="#5EC8FF", flame="#5EC8FF"),
         aura=dict(color="#5EC8FF", strength=1.1), stats=dict(multiplier=75, cost=1.1e7)),

    dict(id=20, key="HeavyLifter", name="Lanceur lourd", world=2, finish="paint",
         body=dict(kind="cyl", h=5.6, r=1.0), nose=dict(kind="blunt", h=1.8),
         fins=dict(n=4, kind="stub", size=0.9), window=dict(n=1, r=0.3, z=0.75), nozzles=3, nozzle_h=0.8,
         boosters=dict(n=2, r=0.5, h=3.8, offset=0, color="body", nose_color="accent"),
         bands=[dict(z=0.15, h=0.6, color="accent")],
         colors=dict(body="#F4F4F4", accent="#FF6A00", nose="#FF6A00", fins="#FF6A00", window="#5EC8FF", glow="#FF9A1F", flame="#FF9A1F"),
         aura=dict(color="#FF9A1F", strength=1.15), stats=dict(multiplier=95, cost=2e7)),

    # ===================================================================
    # MONDE 3 — EXPÉRIMENTAL : fusées avancées, modules spéciaux, nouvelles énergies
    # ===================================================================
    dict(id=21, key="BronzeLander", name="Atterrisseur bronze", world=3, finish="metal",
         body=dict(kind="capsule", h=3.4, r=1.1), nose=dict(kind="dome", h=0.9),
         window=dict(n=1, r=0.4, z=0.6), legs=dict(n=4, len=2.0), nozzles=1, nozzle_h=0.7, antenna=dict(h=0.9),
         rings=[dict(z=0.25, scale=1.04, thick=0.08, color="metal")],
         colors=dict(body="#A3763E", accent="#5C4630", nose="#5C4630", window="#FFD27A", metal="#4E4A44", glow="#FFB04A", flame="#FFB04A"),
         aura=dict(color="#FFB04A", strength=1.3), stats=dict(multiplier=120, cost=4e7)),

    dict(id=22, key="CopperSolar", name="Cuivre solaire", world=3, finish="metal",
         body=dict(kind="cyl", h=3.8, r=0.9), nose=dict(kind="dome", h=1.0),
         panels=dict(z=0.6, len=2.4, w=1.1), window=dict(n=1, r=0.32, z=0.6), nozzles=1, nozzle_h=0.75, fins=dict(n=3, kind="stub", size=0.6),
         colors=dict(body="#B8742F", accent="#5C4630", nose="#5C4630", fins="#5C4630", window="#5EC8FF", metal="#4E4A44", panel="#1E3A8A", glow="#5EC8FF", flame="#FFB04A"),
         aura=dict(color="#5EC8FF", strength=1.3), stats=dict(multiplier=150, cost=7.5e7)),

    dict(id=23, key="TripodDish", name="Trépied radar", world=3, finish="metal",
         body=dict(kind="taper", h=4.6, r=0.6, r2=0.45), nose=dict(kind="spike", h=2.2),
         legs=dict(n=3, len=2.4), dish=dict(z=0.0, dz=0.5, R=1.9, tilt=0), nozzles=1, nozzle_h=0.6, nozzle_r=0.3,
         halos=[dict(z=0.65, R=1.0, thick=0.06, color="glow")],
         colors=dict(body="#8A9099", accent="#2E2E2E", nose="#C9CED6", metal="#4E4A44", glow="#5EC8FF", flame="#5EC8FF"),
         aura=dict(color="#5EC8FF", strength=1.35), stats=dict(multiplier=190, cost=1.4e8)),

    dict(id=24, key="FrostLance", name="Lance givrée", world=3, finish="chrome",
         body=dict(kind="bullet", h=5.4, r=0.85), nose=dict(kind="spike", h=2.6),
         fins=dict(n=4, kind="blade", size=0.85, tip_glow=True), window=dict(n=1, r=0.3, z=0.72), nozzles=1, nozzle_h=0.75,
         bands=[dict(z=0.35, h=0.25, color="glow", glow=True)],
         colors=dict(body="#E8ECF2", accent="#5EC8FF", nose="#C9CED6", fins="#C9CED6", window="#5EC8FF", glow="#5EC8FF", flame="#5EC8FF"),
         aura=dict(color="#5EC8FF", strength=1.4), stats=dict(multiplier=240, cost=2.6e8)),

    dict(id=25, key="VioletViper", name="Vipère violette", world=3, finish="paint",
         body=dict(kind="bullet", h=5.4, r=0.85), nose=dict(kind="ogive", h=2.4),
         fins=dict(n=3, kind="delta", size=0.9, tip_glow=True), cockpit=dict(z=0.7, r=0.38, len=2.0), nozzles=1, nozzle_h=0.75,
         bands=[dict(z=0.3, h=0.3, color="glow", glow=True)],
         colors=dict(body="#7A2BD6", accent="#C9CED6", nose="#C9CED6", fins="#5A1FA3", window="#FF6AD5", glow="#FF6AD5", flame="#FF6AD5"),
         aura=dict(color="#FF6AD5", strength=1.5), stats=dict(multiplier=300, cost=5e8)),

    dict(id=26, key="GoldSaucer", name="Soucoupe dorée", world=3, finish="chrome",
         body=dict(kind="waist", h=2.2, r=1.0, r2=0.8), nose=dict(kind="dome", h=0.5),
         saucer=dict(z=0.35, R=2.6, thick=0.4, lights=8), dome=dict(z=1.0, r=0.75), nozzles=3, nozzle_h=0.6, flame=True,
         colors=dict(body="#D9A520", accent="#F1C85A", nose="#D9A520", window="#9BE8FF", glow="#9BE8FF", flame="#9BE8FF", metal="#8A6A1A"),
         aura=dict(color="#9BE8FF", strength=1.6), stats=dict(multiplier=380, cost=9e8)),

    dict(id=27, key="CrimsonTrio", name="Trio cramoisi", world=3, finish="paint",
         body=dict(kind="cyl", h=4.8, r=0.8), nose=dict(kind="ogive", h=1.8),
         fins=dict(n=3, kind="stub", size=0.7), window=dict(n=1, r=0.3, z=0.72), nozzles=1, nozzle_h=0.75,
         boosters=dict(n=2, r=0.5, h=3.6, offset=0, color="body", nose_color="accent"),
         bands=[dict(z=0.2, h=0.5, color="accent")],
         colors=dict(body="#D62828", accent="#F1C85A", nose="#F1C85A", fins="#F1C85A", window="#FFD27A", glow="#FFB04A", flame="#FFB04A"),
         aura=dict(color="#FFB04A", strength=1.6), stats=dict(multiplier=470, cost=1.7e9)),

    dict(id=28, key="ScarletSpear", name="Épieu écarlate", world=3, finish="chrome",
         body=dict(kind="bullet", h=5.6, r=0.8), nose=dict(kind="spike", h=2.8),
         fins=dict(n=4, kind="swept", size=0.8, tip_glow=True), window=dict(n=1, r=0.28, z=0.72), nozzles=1, nozzle_h=0.75,
         bands=[dict(z=0.5, h=0.3, color="body"), dict(z=0.9, h=0.25, color="glow", glow=True)],
         colors=dict(body="#D62828", accent="#C9CED6", nose="#C9CED6", fins="#C9CED6", window="#FFD27A", glow="#FF4D4D", flame="#FF4D4D"),
         aura=dict(color="#FF4D4D", strength=1.7), stats=dict(multiplier=600, cost=3.2e9)),

    dict(id=29, key="GoldenHawk", name="Faucon doré", world=3, finish="paint",
         body=dict(kind="bullet", h=5.2, r=0.85), nose=dict(kind="ogive", h=2.4),
         fins=dict(n=2, kind="wing", size=1.0, offset=0, tip_glow=True), cockpit=dict(z=0.72, r=0.4, len=2.0), nozzles=1, nozzle_h=0.75,
         spikes=dict(n=2, z=0.15, len=1.2, r=0.15, offset=90, up=0.2, color="accent", glow=False),
         colors=dict(body="#D62828", accent="#F1C85A", nose="#F1C85A", fins="#F1C85A", window="#FFD27A", glow="#FFB04A", flame="#FFB04A"),
         aura=dict(color="#FFB04A", strength=1.8), stats=dict(multiplier=750, cost=6e9)),

    dict(id=30, key="AureateHalo", name="Halo auréolé", world=3, finish="chrome",
         body=dict(kind="cyl", h=5.0, r=0.8), nose=dict(kind="spike", h=2.4),
         fins=dict(n=3, kind="blade", size=0.8, tip_glow=True), window=dict(n=1, r=0.3, z=0.7), nozzles=1, nozzle_h=0.75,
         halos=[dict(z=0.35, R=2.0, thick=0.12, color="glow"), dict(z=0.7, R=1.6, thick=0.1, color="glow")],
         colors=dict(body="#F1C85A", accent="#D9A520", nose="#D9A520", fins="#D9A520", window="#FFD27A", glow="#FFD35A", flame="#FFD35A"),
         aura=dict(color="#FFD35A", strength=2.0), stats=dict(multiplier=950, cost=1.2e10)),

    # ===================================================================
    # MONDE 4 — LÉGENDAIRE : fusées d'élite, ultra-performantes, technologie ultime
    # ===================================================================
    dict(id=31, key="ShadowStriker", name="Frappeur d'ombre", world=4, finish="matte",
         body=dict(kind="bullet", h=5.4, r=0.85), nose=dict(kind="spike", h=2.6),
         fins=dict(n=4, kind="blade", size=0.95, tip_glow=True), window=dict(n=1, r=0.28, z=0.72), nozzles=1, nozzle_h=0.8,
         bands=[dict(z=0.3, h=0.25, color="glow", glow=True), dict(z=0.6, h=0.2, color="glow", glow=True)],
         colors=dict(body="#15161C", accent="#FF2FA8", nose="#2A2C36", fins="#2A2C36", window="#FF2FA8", glow="#FF2FA8", flame="#FF2FA8"),
         aura=dict(color="#FF2FA8", strength=2.1), stats=dict(multiplier=1300, cost=2.5e10)),

    dict(id=32, key="VoidSaucer", name="Soucoupe du vide", world=4, finish="matte",
         body=dict(kind="waist", h=2.2, r=1.0, r2=0.8), nose=dict(kind="dome", h=0.5),
         saucer=dict(z=0.35, R=2.7, thick=0.4, lights=10), dome=dict(z=1.0, r=0.75), nozzles=3, nozzle_h=0.6,
         colors=dict(body="#15161C", accent="#1F2230", nose="#15161C", window="#5EF2FF", glow="#5EF2FF", flame="#5EF2FF", metal="#2A2C36"),
         aura=dict(color="#5EF2FF", strength=2.2), stats=dict(multiplier=1700, cost=5e10)),

    dict(id=33, key="AmethystShard", name="Éclat d'améthyste", world=4, finish="crystal", segments=8,
         body=dict(kind="crystal", h=5.0, r=0.95, r2=0.55), nose=dict(kind="crystal", h=2.8),
         fins=dict(n=4, kind="crystal", size=0.9, tip_glow=True), nozzles=1, nozzle_h=0.8,
         spikes=dict(n=4, z=0.55, len=1.6, r=0.22, offset=45, up=0.8, glow=True),
         colors=dict(body="#A23BFF", accent="#FF6AD5", nose="#C77DFF", fins="#7A2BD6", window="#FF6AD5", glow="#FF6AD5", flame="#FF6AD5", nozzle="#2A2C36"),
         aura=dict(color="#FF6AD5", strength=2.3), stats=dict(multiplier=2200, cost=1e11)),

    dict(id=34, key="ObsidianFang", name="Croc d'obsidienne", world=4, finish="crystal", segments=6,
         body=dict(kind="crystal", h=5.2, r=0.95, r2=0.5), nose=dict(kind="crystal", h=3.0),
         fins=dict(n=3, kind="crystal", size=1.0, tip_glow=True), nozzles=1, nozzle_h=0.8,
         bands=[dict(z=0.45, h=0.25, color="glow", glow=True)],
         colors=dict(body="#1A1026", accent="#A23BFF", nose="#2A1840", fins="#2A1840", window="#A23BFF", glow="#A23BFF", flame="#A23BFF", nozzle="#2A2C36"),
         aura=dict(color="#A23BFF", strength=2.3), stats=dict(multiplier=2900, cost=2e11)),

    dict(id=35, key="CyanHalo", name="Halo cyan", world=4, finish="chrome",
         body=dict(kind="bullet", h=5.4, r=0.85), nose=dict(kind="spike", h=2.8),
         fins=dict(n=4, kind="swept", size=0.85, tip_glow=True), window=dict(n=1, r=0.3, z=0.72), nozzles=1, nozzle_h=0.8,
         halos=[dict(z=0.45, R=2.2, thick=0.12, color="glow", tilt=12)],
         colors=dict(body="#F4F4F4", accent="#5EF2FF", nose="#C9CED6", fins="#C9CED6", window="#5EF2FF", glow="#5EF2FF", flame="#5EF2FF"),
         aura=dict(color="#5EF2FF", strength=2.4), stats=dict(multiplier=3800, cost=4e11)),

    dict(id=36, key="InfernoFighter", name="Chasseur infernal", world=4, finish="paint",
         body=dict(kind="bullet", h=5.4, r=0.85), nose=dict(kind="spike", h=2.6),
         fins=dict(n=2, kind="wing", size=1.1, offset=0, tip_glow=True), cockpit=dict(z=0.72, r=0.4, len=2.2), nozzles=1, nozzle_h=0.8,
         spikes=dict(n=2, z=0.3, len=1.6, r=0.18, offset=90, up=0.3, color="accent", glow=True),
         bands=[dict(z=0.4, h=0.25, color="glow", glow=True)],
         colors=dict(body="#D62828", accent="#FF8A1F", nose="#FF8A1F", fins="#B51E1E", window="#FFD27A", glow="#FF8A1F", flame="#FF8A1F"),
         aura=dict(color="#FF8A1F", strength=2.5), stats=dict(multiplier=5000, cost=8e11)),

    dict(id=37, key="SolarCrown", name="Couronne solaire", world=4, finish="chrome",
         body=dict(kind="cyl", h=5.2, r=0.8), nose=dict(kind="spike", h=2.6),
         fins=dict(n=4, kind="blade", size=0.85, tip_glow=True), window=dict(n=1, r=0.3, z=0.72), nozzles=1, nozzle_h=0.8,
         halos=[dict(z=0.2, R=2.1, thick=0.12, color="glow"), dict(z=0.95, R=1.3, thick=0.08, color="glow")],
         colors=dict(body="#F1C85A", accent="#FFD35A", nose="#D9A520", fins="#D9A520", window="#FFD27A", glow="#FFD35A", flame="#FFD35A"),
         aura=dict(color="#FFD35A", strength=2.6), stats=dict(multiplier=6500, cost=1.6e12)),

    dict(id=38, key="GlacierCrystal", name="Cristal glacier", world=4, finish="crystal", segments=8,
         body=dict(kind="crystal", h=5.2, r=0.95, r2=0.55), nose=dict(kind="crystal", h=2.8),
         fins=dict(n=4, kind="crystal", size=0.95, tip_glow=True), nozzles=1, nozzle_h=0.8,
         spikes=dict(n=4, z=0.6, len=1.6, r=0.22, offset=45, up=0.8, glow=True),
         colors=dict(body="#2F7BFF", accent="#5EF2FF", nose="#8FE3FF", fins="#1E4FCC", window="#5EF2FF", glow="#5EF2FF", flame="#5EF2FF", nozzle="#2A2C36"),
         aura=dict(color="#5EF2FF", strength=2.7), stats=dict(multiplier=8500, cost=3.2e12)),

    dict(id=39, key="NebulaLance", name="Lance nébuleuse", world=4, finish="paint",
         body=dict(kind="bullet", h=5.6, r=0.85), nose=dict(kind="spike", h=3.0),
         fins=dict(n=4, kind="delta", size=0.95, tip_glow=True), window=dict(n=1, r=0.3, z=0.72), nozzles=1, nozzle_h=0.8,
         bands=[dict(z=0.3, h=0.3, color="glow", glow=True), dict(z=0.55, h=0.3, color="body")],
         halos=[dict(z=0.6, R=1.8, thick=0.1, color="glow")],
         colors=dict(body="#7A2BD6", accent="#F4F4F4", nose="#F4F4F4", fins="#F4F4F4", window="#FF6AD5", glow="#FF6AD5", flame="#FF6AD5"),
         aura=dict(color="#FF6AD5", strength=2.8), stats=dict(multiplier=11000, cost=6.5e12)),

    dict(id=40, key="UltimateLegend", name="Légende ultime", world=4, finish="chrome",
         body=dict(kind="bullet", h=5.8, r=0.9), nose=dict(kind="spike", h=3.0),
         fins=dict(n=2, kind="wing", size=1.2, offset=0, tip_glow=True), cockpit=dict(z=0.72, r=0.42, len=2.4), nozzles=3, nozzle_h=0.85,
         spikes=dict(n=2, z=0.3, len=1.8, r=0.18, offset=90, up=0.4, color="glow", glow=True),
         halos=[dict(z=0.25, R=2.6, thick=0.14, color="glow"), dict(z=0.6, R=2.0, thick=0.1, color="glow", tilt=15)],
         bands=[dict(z=0.5, h=0.3, color="glow", glow=True)],
         colors=dict(body="#F4F4F4", accent="#F1C85A", nose="#F1C85A", fins="#F1C85A", window="#FFD27A", glow="#FFD35A", flame="#FFD35A"),
         aura=dict(color="#FFD35A", strength=3.0), stats=dict(multiplier=15000, cost=1.5e13)),
]

assert len(SPECS) == 40
assert [s["id"] for s in SPECS] == list(range(1, 41))

WORLDS = {
    1: dict(name="Débutant", subtitle="Fusées simples, bricolées et légères", color="#38D430", bg="#4FB84A"),
    2: dict(name="Technologie", subtitle="Fusées améliorées, plus rapides et plus stables", color="#30C8FF", bg="#2A7FD4"),
    3: dict(name="Expérimental", subtitle="Fusées avancées, modules spéciaux et nouvelles énergies", color="#FFB13B", bg="#C8622A"),
    4: dict(name="Légendaire", subtitle="Fusées d'élite, ultra-performantes et à la technologie ultime", color="#D23BFF", bg="#3A1F6B"),
}
