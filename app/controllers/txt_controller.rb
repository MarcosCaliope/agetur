class TxtController < ApplicationController
    skip_before_action :verify_authenticity_token
    def index
        @customers= Customer.all
    end

    def importar
        errors = []
        file = params['txt'].tempfile.path
#        file = params['file']
        File.open(file).each do |line|
        begin
          line = line.split(",")
      
          next if line[0] == "nome"
      
          #buyer = line[0] rescue row[0]
          nome = line[0].strip rescue line[0]
          email = line[1].strip rescue line[1]
          phone = line[2].strip rescue line[2]
          document = line[3].strip rescue line[3]
          comments = line[4].strip rescue line[4]
          city = line[5].strip rescue line[5]
    
            Customer.create(nome: nome, email: email, phone: phone, document: document, 
            comments: comments, city: city)
          rescue Exception => err
          errors << err.message
        end
      end
      
      if errors.blank?
        flash[:success] = "Imported with successful"
      else
        flash[:error] = errors.join(", ")
      end        
      redirect_to "/txt"
    end

end
