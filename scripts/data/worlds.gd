class_name WorldDefs
extends RefCounted
## Mundos: 20 estágios cada. Chefão (elite) a cada 5 estágios; o 20º é o chefão do mundo.
## Depois do 5º mundo o ciclo recomeça ("Pesadelo") com a mesma curva de dificuldade subindo.

const STAGES_PER_WORLD := 20

const DATA: Array[Dictionary] = [
	{"id": "cozinha", "regular": ["barata", "formiga", "rato", "mosca"], "boss": "baratona"},
	{"id": "quintal", "regular": ["pombo", "gato", "cachorro", "caracol"], "boss": "gatao"},
	{"id": "rua", "regular": ["cone", "moto", "buraco", "camelo"], "boss": "engarrafamento"},
	{"id": "escritorio", "regular": ["boleto", "planilha", "reuniao", "notificacao"], "boss": "segunda"},
	{"id": "banco", "regular": ["fila", "juros", "carimbo", "senha"], "boss": "leao"},
]


static func index_of(stage: int) -> int:
	return floori((stage - 1) / float(STAGES_PER_WORLD)) % DATA.size()


static func stage_in_world(stage: int) -> int:
	return (stage - 1) % STAGES_PER_WORLD + 1


## 0 = primeira volta; 1 = Pesadelo I; ...
static func cycle_of(stage: int) -> int:
	return floori((stage - 1) / float(STAGES_PER_WORLD * DATA.size()))


static func is_boss_stage(stage: int) -> bool:
	return stage % 5 == 0


static func is_world_boss(stage: int) -> bool:
	return stage % STAGES_PER_WORLD == 0
