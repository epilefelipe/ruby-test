# frozen_string_literal: true

class ItemSerializer < Blueprinter::Base
  identifier :slug, name: :id

  fields :name, :slug

  view :list do
    fields :description, :hint
  end

  view :detailed do
    fields :description, :hint
  end

  view :inventory do
    fields :name, :description, :slug
  end
end
