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

    

    it "can prepare and save a PDF ready for sign" do

      mypdf = Origami::PDF.read file_to_be_signed
      
      hash_to_be_signed = mypdf.prepare_for_sign(   
      
            :location => "India", 
            :contact => "sajith@mobme.in", 
            :reason => "Proof of Concept Sajith Vishnu" 
            )

    
      mypdf.save( prepared_pdf );
      
      #mypdf.signature should not raise_error
      expect { mypdf.signature  }.to_not raise_error

      

    end



    it "can prepare and return a valid base64 encoded SHA1 hash signable data" do

      mypdf = Origami::PDF.read file_to_be_signed
      
      hash_to_be_signed = mypdf.prepare_for_sign(   
      
            :location => "India", 
            :contact => "sajith@mobme.in", 
            :reason => "Proof of Concept Sajith Vishnu" 
            )

    

      #hash_to_be_signed should be a base64 encoded hash with lenght = 20
      Base64.decode64(hash_to_be_signed).size.should eql 20 


    end


    it "can attach a sign inside a prepared PDF document" do 

      mypdf = Origami::PDF.read prepared_and_waiting_pdf

      signature_base64 = File.read(base64encoded_signature_pkcs7)

      mypdf.insert_sign( signature_base64)

      mypdf.is_signed?.should eql true

      mypdf.verify.should eql true

      


    end


    it "can verify a wrong signature attachment" do 

      mypdf = Origami::PDF.read prepared_and_waiting_pdf

      signature_base64 = File.read(wrong_signature_pkcs7)

      mypdf.insert_sign( signature_base64)

      mypdf.is_signed?.should eql true

      mypdf.verify.should eql false


    end


    it "can detect a change in signed PDF" do

      mypdf = Origami::PDF.read prepared_and_waiting_pdf

      signature_base64 = File.read(base64encoded_signature_pkcs7)

      mypdf.insert_sign( signature_base64)

      mypdf.is_signed?.should eql true

      mypdf.verify.should eql true

      mypdf.save(signed_pdf_path)

      #adding a new page
      page = Origami::Page.new
      mypdf.append_page(page)

      mypdf.save(signed_pdf_path)

      #mypdf.verify.should eql false

      true


    end 




end