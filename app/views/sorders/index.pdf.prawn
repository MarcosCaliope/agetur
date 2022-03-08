prawn_document do |pdf|
  pdf.text 'Listando Ordens:', :align => :center #, :size=> 18
   # descer 20 pixels 1 linha
  pdf.move_down 20  
   
  pdf.table @sorders.collect {|s| [s.id, s.data.strftime('%d/%m/%Y'), 
  s.sobservacoes, s.destination.description, s.tourguide.sname, s.driver.sname]}
  
end