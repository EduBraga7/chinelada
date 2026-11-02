class_name EnemyDefs
extends RefCounted
## Inimigos ("perrengues"). Todos os valores são multiplicadores sobre a curva do estágio (Econ).
## traits: stun (chance de atordoar herói), dot (queima herói), shield (escudo inicial),
## grow (ataque cresce com o tempo), snipe (mira o herói mais frágil).
## summon/summon_every: invoca outro inimigo de tempos em tempos (chefões).
## swarm: quantas unidades nascem por "vaga" da onda.

const DATA := {
	# --- Mundo 1: Cozinha Infestada ---
	"barata": {"hp": 1.0, "atk": 1.0, "aspd": 0.9, "speed": 150.0, "gold": 1.0, "scale": 1.0},
	"formiga": {"hp": 0.40, "atk": 0.45, "aspd": 1.3, "speed": 210.0, "gold": 0.45, "scale": 0.7, "swarm": 3},
	"rato": {"hp": 1.9, "atk": 1.25, "aspd": 0.7, "speed": 125.0, "gold": 1.6, "scale": 1.15},
	"mosca": {"hp": 0.7, "atk": 0.9, "aspd": 1.1, "speed": 190.0, "gold": 1.1, "scale": 0.8, "ranged": true},
	"baratona": {"hp": 1.0, "atk": 1.5, "aspd": 0.7, "speed": 90.0, "gold": 1.0, "scale": 2.0, "summon": "barata", "summon_every": 7.0},
	# --- Mundo 2: Quintal da Vizinhança ---
	"pombo": {"hp": 0.8, "atk": 1.3, "aspd": 1.0, "speed": 170.0, "gold": 1.1, "scale": 0.95, "ranged": true, "traits": ["snipe"]},
	"gato": {"hp": 1.0, "atk": 1.4, "aspd": 1.4, "speed": 230.0, "gold": 1.2, "scale": 1.0},
	"cachorro": {"hp": 2.2, "atk": 1.5, "aspd": 0.8, "speed": 140.0, "gold": 1.8, "scale": 1.3, "traits": ["stun"]},
	"caracol": {"hp": 2.8, "atk": 0.8, "aspd": 0.6, "speed": 60.0, "gold": 2.0, "scale": 0.9, "traits": ["shield"]},
	"gatao": {"hp": 1.0, "atk": 1.8, "aspd": 1.0, "speed": 100.0, "gold": 1.0, "scale": 2.1, "traits": ["stun"], "summon": "gato", "summon_every": 8.0},
	# --- Mundo 3: Rua e Trânsito ---
	"cone": {"hp": 2.4, "atk": 0.8, "aspd": 0.7, "speed": 110.0, "gold": 1.7, "scale": 1.0},
	"moto": {"hp": 0.9, "atk": 1.6, "aspd": 1.2, "speed": 260.0, "gold": 1.3, "scale": 1.15, "ranged": true},
	"buraco": {"hp": 1.7, "atk": 1.1, "aspd": 0.9, "speed": 100.0, "gold": 1.5, "scale": 1.1, "traits": ["dot"]},
	"camelo": {"hp": 1.1, "atk": 0.9, "aspd": 1.0, "speed": 160.0, "gold": 3.2, "scale": 1.0},
	"engarrafamento": {"hp": 1.0, "atk": 1.7, "aspd": 0.8, "speed": 80.0, "gold": 1.0, "scale": 2.3, "summon": "moto", "summon_every": 6.0},
	# --- Mundo 4: Escritório ---
	"boleto": {"hp": 1.0, "atk": 1.0, "aspd": 1.0, "speed": 150.0, "gold": 1.3, "scale": 1.0, "traits": ["dot"]},
	"planilha": {"hp": 1.5, "atk": 1.2, "aspd": 0.9, "speed": 130.0, "gold": 1.6, "scale": 1.1, "traits": ["shield"]},
	"reuniao": {"hp": 3.0, "atk": 0.7, "aspd": 0.6, "speed": 90.0, "gold": 2.2, "scale": 1.25, "traits": ["stun"]},
	"notificacao": {"hp": 0.6, "atk": 1.0, "aspd": 1.8, "speed": 200.0, "gold": 1.2, "scale": 0.8, "ranged": true},
	"segunda": {"hp": 1.0, "atk": 1.6, "aspd": 0.8, "speed": 90.0, "gold": 1.0, "scale": 2.2, "traits": ["grow"], "summon": "notificacao", "summon_every": 7.0},
	# --- Mundo 5: Banco e Repartição ---
	"fila": {"hp": 0.38, "atk": 0.5, "aspd": 1.2, "speed": 150.0, "gold": 0.5, "scale": 0.75, "swarm": 4},
	"juros": {"hp": 1.3, "atk": 1.0, "aspd": 0.9, "speed": 120.0, "gold": 1.8, "scale": 1.0, "traits": ["grow"]},
	"carimbo": {"hp": 1.6, "atk": 1.3, "aspd": 0.8, "speed": 135.0, "gold": 1.9, "scale": 1.05, "traits": ["stun"]},
	"senha": {"hp": 1.2, "atk": 0.9, "aspd": 1.0, "speed": 140.0, "gold": 1.7, "scale": 1.0, "summon": "fila", "summon_every": 9.0},
	"leao": {"hp": 1.0, "atk": 2.0, "aspd": 0.9, "speed": 85.0, "gold": 1.0, "scale": 2.4, "traits": ["dot", "stun"], "summon": "carimbo", "summon_every": 8.0},
}
