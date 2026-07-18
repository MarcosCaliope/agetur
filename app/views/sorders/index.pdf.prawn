prawn_document do |pdf|
  pdf.text 'Current Ordens are:'
  pdf.move_down 20
  #pdf.table @sorders.collect{|s| [s.id,s.data]}
  pdf.table @sorders.collect {|s| [s.id, s.sobservacoes, s.destination.description, s.tourguide.sname]}
  #pdf.table @sorders.collect {|s| []}
end