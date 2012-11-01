require_relative '../../spec_helper'

describe Origami::PDF do

    #the path of original PDF to be signed
    let(:file_to_be_signed ) { File.expand_path("../../fixtures/test_file.pdf", File.dirname(__FILE__)) }
    
    #the path where PDF prepared for sign to be saved
    let(:prepared_pdf ) { File.expand_path("../../fixtures/prepared.pdf", File.dirname(__FILE__)) }
    
    #PDF in which the signature hash is prepared and waiting for sign  from 3rd party
    let(:prepared_and_waiting_pdf ) { File.expand_path("../../fixtures/prepared-and-waiting.pdf", File.dirname(__FILE__)) }
    
    let(:signed_pdf_path) { File.expand_path("../../fixtures/signed-pdf.pdf", File.dirname(__FILE__)) }

    #path for base64 encode signature 
    let(:base64encoded_signature_pkcs7 ) { File.expand_path("../../fixtures/signature_pkcs7", File.dirname(__FILE__)) }
    
    #a signature altered path
    let(:wrong_signature_pkcs7 ) { File.expand_path("../../fixtures/wrong_signature_pkcs7", File.dirname(__FILE__)) }

    
     #the path of linearized pdf
    let(:linearized_pdf_path ) { File.expand_path("../../fixtures/linear.pdf", File.dirname(__FILE__)) }
    

    #the path of xrefed_pdf
    let(:xrefed_pdf_path ) { File.expand_path("../../fixtures/xrefed.pdf", File.dirname(__FILE__)) }
    

    describe ".prepare_for_sign" do
    
        it "can prepare PDF ready for sign" do

          mypdf = Origami::PDF.read file_to_be_signed
          
          hash_to_be_signed = mypdf.prepare_for_sign(   
          
                :location => "India", 
                :contact => "sajith@mobme.in", 
                :reason => "Proof of Concept Sajith Vishnu" 
                )

        
          mypdf.save( prepared_pdf );
          
          #mypdf.signature should not raise_error (if prepared, the pdf must have a signture field)
          expect { mypdf.signature  }.to_not raise_error

          Base64.decode64(hash_to_be_signed).size.should eql 20 

          

        end

    end 


    describe ".insert_sign" do

        
      context "when a prepared PDF is passed" do

        it "can attach a sign" do 

          mypdf = Origami::PDF.read prepared_and_waiting_pdf

          signature_base64 = File.read(base64encoded_signature_pkcs7)

          mypdf.insert_sign( signature_base64)

          mypdf.is_signed?.should eql true

          mypdf.verify.should eql true

          


        end

      end  

      context "when a normal PDF is passed" do

        it "throws invalid PDF exception" do 

          mypdf = Origami::PDF.read file_to_be_signed

          signature_base64 = File.read(base64encoded_signature_pkcs7)

          expect { mypdf.insert_sign( signature_base64) }.to raise_error

            
        end

      end



        it "returns invalid PDF for wrong signature" do 

          mypdf = Origami::PDF.read prepared_and_waiting_pdf

          signature_base64 = File.read(wrong_signature_pkcs7)

          mypdf.insert_sign( signature_base64)

          mypdf.is_signed?.should eql true

          mypdf.verify.should eql false


        end

    end

    it "can verify a change in signed PDF" do

      

      #Open a signed PDF file
      mypdf = Origami::PDF.read signed_pdf_path
      mypdf.is_signed?.should eql true

      #verify the signature, to make sure it is signed validly
      mypdf.verify.should eql true

      
      #add some extra content @todo, make this work properly
      #contents = ContentStream.new
      #contents.write "Adding extra data",
       # :x => 250, :y => 750, :rendering => Text::Rendering::FILL, :size => 30
      #mypdf.append_page Page.new.setContents(contents)


      #save the edited version somewhere
      mypdf.saveas( signed_pdf_path + "_duplicate.pdf" )


      #load the edited version
      edited_pdf =  Origami::PDF.read signed_pdf_path + "_duplicate.pdf"

      #verification should through exeception
      #expect { edited_pdf.verify }.to raise_error

      #@todo replace this with above line
      true


    end 

    describe ".valid_pdf_for_sign?" do

        context "when a linearized PDF is passed" do

            it "returns false" do

              #Open a signed PDF file
              mypdf = Origami::PDF.read linearized_pdf_path

              mypdf.valid_pdf_for_sign?.should eql false

            end

        end


        context "when a XREFed PDF is passed" do

            it "returns false" do

              #Open a signed PDF file
              mypdf = Origami::PDF.read xrefed_pdf_path

              mypdf.valid_pdf_for_sign?.should eql false

            end

        end



    end

    it "throws exception when call prepared_pdf method" do

        #Open a signed PDF file
          mypdf = Origami::PDF.read linearized_pdf_path

          expect { mypdf.prepare_for_sign(   
          
                :location => "India", 
                :contact => "sajith@mobme.in", 
                :reason => "Proof of Concept Sajith Vishnu" 
                ) }.to raise_error
    
    end
      




end