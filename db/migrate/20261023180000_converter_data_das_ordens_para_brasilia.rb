# The app now runs in Brasília's time zone (config.time_zone). An order's
# date and time were stored as their wall-clock value taken as UTC (8:00
# was 08:00 UTC); this turns them into the real instant (8:00 in Brasília,
# 11:00 UTC), so every order keeps showing the same date and time. The other
# datetime columns (created_at, conferido_em, ...) already hold real instants.
class ConverterDataDasOrdensParaBrasilia < ActiveRecord::Migration[7.2]
  def up
    execute "UPDATE sorders SET data = (data AT TIME ZONE 'America/Sao_Paulo') AT TIME ZONE 'UTC' WHERE data IS NOT NULL"
  end

  def down
    execute "UPDATE sorders SET data = (data AT TIME ZONE 'UTC') AT TIME ZONE 'America/Sao_Paulo' WHERE data IS NOT NULL"
  end
end
