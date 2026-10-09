# Accent-insensitive search in the cadastro lists ("ceara" finds "CEARÁ").
class EnableUnaccent < ActiveRecord::Migration[7.2]
  def change
    enable_extension "unaccent"
  end
end
