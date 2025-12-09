# frozen_string_literal: true

puts 'Limpiando base de datos...'
Room.destroy_all
Item.destroy_all
Clue.destroy_all
GameSession.destroy_all

puts 'Creando pistas...'
clues_data = [
  {
    slug: 'clue_maria',
    text: 'María nunca olvidó el año en que todo comenzó.',
    source: 'nota_1',
    hint_level: 1
  },
  {
    slug: 'clue_year',
    text: 'El año 1987 parece importante. María Velasco tenía 7 años en la foto.',
    source: 'periodico',
    hint_level: 2
  },
  {
    slug: 'clue_birth',
    text: 'Si María tenía 7 años en 1987... nació en 1980.',
    source: 'nota_1',
    hint_level: 3
  },
  {
    slug: 'clue_collar',
    text: 'El collar de María tiene grabado: 1980',
    source: 'cuadro_familia',
    hint_level: 4
  },
  {
    slug: 'clue_birthday',
    text: 'María cumplió 7 en 1987. Confirmado: nació en 1980.',
    source: 'foto_escritorio',
    hint_level: 5
  },
  {
    slug: 'clue_escape',
    text: 'El diario dice: "La salida está al norte del pasillo. Papá siempre deja la llave maestra aquí."',
    source: 'diario_maria',
    hint_level: 6
  }
]

clues_data.each { |data| Clue.create!(data) }
puts "  #{Clue.count} pistas creadas"

puts 'Creando habitaciones...'

# Sótano
cellar = Room.create!(
  slug: 'cellar',
  name: 'Sótano Oscuro',
  description: 'Despiertas en un sótano húmedo. No recuerdas cómo llegaste aquí. La única luz proviene de una pequeña ventana en lo alto. Huele a encierro.',
  description_panic: 'El sótano tiembla. Polvo cae del techo. ¡Debes salir de aquí!',
  exits: [
    {
      direction: 'norte',
      target_room_slug: 'pasillo',
      door_id: 'puerta_sotano',
      locked: true,
      required_item: 'llave_sotano',
      hint: 'Necesitas una llave'
    }
  ]
)

# Pasillo
pasillo = Room.create!(
  slug: 'pasillo',
  name: 'Pasillo Tenebroso',
  description: 'Un pasillo largo y oscuro. Las paredes están llenas de cuadros de la familia Velasco. Al fondo ves una luz tenue.',
  description_panic: '¡El techo cruje! ¡Escombros caen a tu alrededor! ¡La salida está al NORTE!',
  exits: [
    {
      direction: 'sur',
      target_room_slug: 'cellar',
      door_id: 'puerta_sotano',
      locked: false
    },
    {
      direction: 'este',
      target_room_slug: 'estudio',
      door_id: 'puerta_estudio',
      locked: false
    },
    {
      direction: 'norte',
      target_room_slug: 'salida',
      door_id: 'puerta_principal',
      locked: true,
      required_item: 'llave_maestra',
      hint: 'Puerta principal. Necesitas la llave maestra.'
    }
  ]
)

# Estudio
estudio = Room.create!(
  slug: 'estudio',
  name: 'Estudio Polvoriento',
  description: 'El estudio del Dr. Velasco. Libros por todas partes. Un escritorio con una computadora antigua. Hay una caja fuerte en la pared.',
  description_panic: '¡Las paredes tiemblan! ¡Polvo cae del techo! ¡No hay tiempo!',
  exits: [
    {
      direction: 'oeste',
      target_room_slug: 'pasillo',
      door_id: 'puerta_estudio',
      locked: false
    }
  ]
)

# Salida
Room.create!(
  slug: 'salida',
  name: 'Exterior - Jardín',
  description: 'Sales al jardín abandonado de la mansión. El sol te ciega después de estar tanto tiempo en la oscuridad.',
  exits: []
)

puts "  #{Room.count} habitaciones creadas"

puts 'Creando items...'

# Items del Sótano
Item.create!(
  slug: 'caja_vieja',
  name: 'Caja vieja',
  description: 'Una caja de madera podrida. Adentro encuentras una llave oxidada y una nota arrugada.',
  hint: 'Parece que se puede abrir',
  room: cellar,
  examinable: true,
  contains_items: %w[llave_sotano nota_1],
  reveals_clue: 'clue_maria'
)

Item.create!(
  slug: 'periodico',
  name: 'Periódico amarillento',
  description: 'Un periódico viejo. El titular dice: "TRAGEDIA EN LA MANSIÓN VELASCO - 15 de Octubre de 1987". Hay una foto de una niña llamada María.',
  hint: 'La fecha es visible',
  room: cellar,
  examinable: true,
  reveals_clue: 'clue_year'
)

# Items que se obtienen de la caja
Item.create!(
  slug: 'llave_sotano',
  name: 'Llave oxidada',
  description: 'Una llave vieja y oxidada. Podría abrir algo.',
  pickable: true
)

Item.create!(
  slug: 'nota_1',
  name: 'Nota arrugada',
  description: 'Letra temblorosa: "María nunca olvidó el año en que todo comenzó. La clave está en su nacimiento."',
  pickable: true,
  reveals_clue: 'clue_birth'
)

# Items del Pasillo
Item.create!(
  slug: 'cuadro_familia',
  name: 'Cuadro de la familia Velasco',
  description: 'Una foto familiar. Padre, madre y una niña. Debajo dice: "Familia Velasco, 1987". María lleva un collar con el número 1980.',
  hint: 'La familia parece feliz',
  room: pasillo,
  examinable: true,
  reveals_clue: 'clue_collar'
)

Item.create!(
  slug: 'candelabro',
  name: 'Candelabro antiguo',
  description: 'Un candelabro de bronce. Puedes tomarlo.',
  hint: 'Podría servir como herramienta',
  room: pasillo,
  examinable: true,
  pickable: true
)

# Items del Estudio
Item.create!(
  slug: 'computadora',
  name: 'Computadora antigua',
  description: 'Una terminal de los 80s. La pantalla parpadea. Muestra: "SISTEMA VELASCO - INGRESE CONTRASEÑA". Parece requerir un código de 4 dígitos.',
  hint: 'Requiere contraseña',
  room: estudio,
  examinable: true,
  interaction_type: 'terminal'
)

Item.create!(
  slug: 'foto_escritorio',
  name: 'Foto en el escritorio',
  description: 'María soplando velas. El pastel dice "Felices 7". La fecha en el reverso: "Octubre 1987".',
  hint: 'Una foto de cumpleaños',
  room: estudio,
  examinable: true,
  reveals_clue: 'clue_birthday'
)

Item.create!(
  slug: 'caja_fuerte',
  name: 'Caja fuerte',
  description: 'Una caja fuerte empotrada en la pared. Tiene una cerradura electrónica moderna. Hay un lector de tarjetas.',
  hint: 'Necesita tarjeta de acceso',
  room: estudio,
  examinable: true,
  interaction_type: 'vault'
)

# Items que se obtienen de la caja fuerte
Item.create!(
  slug: 'llave_maestra',
  name: 'Llave Maestra',
  description: 'Una llave dorada con el emblema Velasco. Abre la puerta principal.',
  pickable: true
)

Item.create!(
  slug: 'diario_maria',
  name: 'Diario de María',
  description: 'Las páginas están amarillentas. La última entrada dice: "15 de Octubre, 1987 - Escucho ruidos abajo. Papá me dijo que me escondiera. Si lees esto, SAL DE AQUÍ."',
  pickable: true
)

puts "  #{Item.count} items creados"

puts '¡Seed completado!'
puts ''
puts 'Para jugar:'
puts '  1. docker-compose up'
puts '  2. POST http://localhost:3000/api/v1/game/start'
puts '  3. Usa el game_id en header X-Game-ID para las demás requests'
