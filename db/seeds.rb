# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

# Brazilian states, needed by companies, vehicles and destinations.
# Idempotent: safe to run on a database that already has some of them.
{
  "AC" => "Acre", "AL" => "Alagoas", "AP" => "Amapá", "AM" => "Amazonas", "BA" => "Bahia",
  "CE" => "Ceará", "DF" => "Distrito Federal", "ES" => "Espírito Santo", "GO" => "Goiás",
  "MA" => "Maranhão", "MT" => "Mato Grosso", "MS" => "Mato Grosso do Sul", "MG" => "Minas Gerais",
  "PA" => "Pará", "PB" => "Paraíba", "PR" => "Paraná", "PE" => "Pernambuco", "PI" => "Piauí",
  "RJ" => "Rio de Janeiro", "RN" => "Rio Grande do Norte", "RS" => "Rio Grande do Sul",
  "RO" => "Rondônia", "RR" => "Roraima", "SC" => "Santa Catarina", "SP" => "São Paulo",
  "SE" => "Sergipe", "TO" => "Tocantins"
}.each do |uf, name|
  State.find_or_create_by!(uf: uf) { |state| state.name = name }
end
