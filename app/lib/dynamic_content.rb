# frozen_string_literal: true

# Single Responsibility: Handle all dynamic content generation
# This eliminates code duplication across services and commands
class DynamicContent
  class << self
    def item_description(item, session)
      case item.slug
      when 'periodico'
        "Un periódico viejo. El titular dice: \"TRAGEDIA EN LA MANSIÓN VELASCO - " \
          "15 de Octubre de #{session.photo_year}\". Hay una foto de una niña llamada María."
      when 'cuadro_familia'
        "Una foto familiar. Padre, madre y una niña. Debajo dice: " \
          "\"Familia Velasco, #{session.photo_year}\". María lleva un collar con el número #{session.birth_year}."
      when 'foto_escritorio'
        "María soplando velas. El pastel dice \"Felices #{session.age_in_photo}\". " \
          "La fecha en el reverso: \"Octubre #{session.photo_year}\"."
      when 'nota_1'
        'Letra temblorosa: "María nunca olvidó el año en que todo comenzó. La clave está en su nacimiento."'
      when 'diario_maria'
        "Las páginas están amarillentas. La última entrada dice: \"15 de Octubre, #{session.photo_year} - " \
          'Escucho ruidos abajo. Papá me dijo que me escondiera. Si lees esto, SAL DE AQUÍ."'
      else
        item.description
      end
    end

    def clue_text(clue, session)
      case clue.slug
      when 'clue_year'
        "El año #{session.photo_year} parece importante. María Velasco tenía #{session.age_in_photo} años en la foto."
      when 'clue_birth'
        "Si María tenía #{session.age_in_photo} años en #{session.photo_year}... nació en #{session.birth_year}."
      when 'clue_collar'
        "El collar de María tiene grabado: #{session.birth_year}"
      when 'clue_birthday'
        "María cumplió #{session.age_in_photo} en #{session.photo_year}. Confirmado: nació en #{session.birth_year}."
      else
        clue.text
      end
    end
  end
end
