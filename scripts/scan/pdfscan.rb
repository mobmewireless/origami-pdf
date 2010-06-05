#!/usr/bin/env ruby 

# Understanding the output


# ====================================================================
# REScan
# ====================================================================
#
# Scan is made on a sanitized version of the PDF using regular
# expressions. Keep this in mind because it explains most of the
# surprising results you can get.
#
#
# Case 1: PDF describing PDF
# ==========================
#
# Some tests for this scanner has been made on articles/slides we
# wrote, including those for PacSec and SSTIC. As such, they contain
# some PDF keywords.
#
# Since this parsing is really simple, it cannot differenciate
# between real PDF instructions, and simple text.
#
#   >> ruby pdfscan.rb sstic09-origami.pdf 
#   ...
#     Catalog: 2
#     xref: 2
#     trailer: 2
#     startxref: 2
# 
# There is only one catalog, and since there is only one revision in
# the file, there can not be 2 xref, trailer and startxref. However,
# all these keywords are in the document...

#
# Case 2: encryption
# ==================
#
#   >> ruby pdfscan.rb ../crypto/encrypted_calc.pdf
#   ...
#   /Encrypt: 1
#   /Launch: 3

# If the file is encrypted, since all the RE matches are made on a
# decrypted version of the file, some matches can happen even when you
# dont expect them.
#
# Here, when you open the file encrypted_calc.pdf, you can find only 1
# /Launch:
#   >> grep -ci launch ../crypto/encrypted_calc.pdf
#   1
# However, when dispayed, the text contains 2 additionnal /Launch. 
# So, yes, the output is correct (but suprising).
#

begin
  require 'origami'
rescue LoadError
  ORIGAMIDIR = "#{File.dirname(__FILE__)}/../.."
  $: << ORIGAMIDIR
  require 'origami'
end
include Origami

require 'digest/md5'
require 'pp'

class SortedHash < Hash
	def []=(k, v)
		@keyseq ||= []
		@keyseq |= [k]
		super
	end
	def each
		@keyseq.each { |k| yield k, self[k] }
	end
end


#
# Functions
# 

# TERM output
def print_result(obj, n, lambda)
  if lambda != nil  and lambda.call(n)
    colorprint("  "+obj+": "+ n.to_s + "\n", Colors::RED)
  else
    puts "  "+obj+": "+ n.to_s
  end
end

def print_section(name, data)

  hash = data["#{name}"]
  if hash == nil
    puts "*** Error: cant display nil data for section \"#{name}\""
    return
  end

  colorprint("[#{name}]\n", Colors::CYAN)

  hash.each do |key, value|
    print_result(key, value["n"], value["lambda"])
  end
  
end

def print_analysis_term(data)

  print_section("File ID", data)
  print_section("Structure", data)
  print_section("Properties", data)
  print_section("Triggers", data)
  print_section("Actions", data)
  print_section("FormActions", data)

end

# HTML output
def print_result_html(obj, n, lambda)
  if lambda != nil  and lambda.call(n)
    puts "  <tr class=\"alert\"><td> "+obj+" </td><td>"+ n.to_s+" </td></tr>"
  else
    puts "  <tr><td width=30%> "+obj+"</td><td> "+ n.to_s+" </td></tr>"
  end
end

def print_section_html(name, data)

  hash = data["#{name}"]
  if hash == nil
    puts "*** Error: cant display nil data for section \"#{name}\""
    return
  end

  puts "  <tr><td colspan=2 align=center class=\"section\">[#{name}]</td></tr>\n"


  hash.each do |key, value|
    print_result_html(key, value["n"], value["lambda"])
  end



end


def print_analysis_html(data)

  hdr = %Q{
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-15">
<title>#{data['File ID']['File']}</title>
<link rel="stylesheet" href="pdfscan.css" type="text/css" media="all">

</head>

<body>

<div class="contents">

}

  puts hdr
  puts "<center>\n<table cellspacing=0 border=1>"
  print_section_html("File ID", data)
  print_section_html("Structure", data)
  print_section_html("Properties", data)
  print_section_html("Triggers", data)
  print_section_html("Actions", data)
  print_section_html("FormActions", data)
  puts "</table>\n</center>\n</div></body>\n</html>\n"

end

#
# lsscan
#
def lsstat(pdf, obj, expected)
  n = pdf.ls(obj).length
  print_result(obj, n, expected)
end

def lsscan(pdf, stats)

  #
  # Get all objects, even those in ObjectStream
  # UBER-SLOW !!
  #
  objects = pdf.objects(:include_keys => false, :include_objectstreams => true)
  indirects = pdf.indirect_objects.values

  # Structure
  #colorprint("[Structure]\n", Colors::CYAN)
  struct = SortedHash.new
  struct["Header"] = { "n" => pdf.header.to_s }
  struct["Revisions"] = { "n" => pdf.revisions.length.to_s }
  struct["Catalog"] = { "n" => objects.find_all{|obj| obj.is_a?(Catalog)}.size, "lambda" => lambda{|x| x!=1}}
  struct["object"] = { "n" => indirects.length, "lambda" => nil}
  struct["total objects"] = { "n" => objects.length, "lambda" => nil}
  struct["stream"] = { "n" => indirects.find_all{|obj| obj.is_a?(Stream)}.length }
  struct["/ObjStm"] = { "n" => indirects.find_all{|obj| obj.is_a?(ObjectStream)}.length }
  struct["Root (current)"] = { "n" => pdf.revisions.last.trailer[:Root] }
  struct["Size (current)"] = { "n" => pdf.revisions.last.trailer[:Size] }

  stats["Structure"] = struct

  # Properties
  properties = SortedHash.new
  properties["/Encrypt"] = { "n" => pdf.is_encrypted? ? 1 : 0, "lambda" => lambda{|x| x > 0}  }
  properties["EmbeddedFile"] = { 
    "n" => indirects.find_all{|obj| obj.is_a?(Dictionary) and obj.has_key? :EF}.length, 
    "lambda" => lambda{|x| x>0} 
  }
  
  stats["Properties"] = properties

  # Triggers
  triggers = SortedHash.new
  triggers["/OpenAction"] = { 
    "n" => indirects.find_all{|obj| obj.is_a?(Catalog) and obj.has_key? :OpenAction}.length, 
    "lambda" => lambda{|x| x>0} 
  }

  triggers["/AA"] = { 
    "n" => objects.find_all{|obj| obj.is_a?(Dictionary) and obj.has_key? :AA}.length, 
    "lambda" => lambda{|x| x>0} 
  }
  triggers["/Names"] = {
    "n" => indirects.find_all{|obj| obj.is_a?(Catalog) and obj.has_key? :Names}.length,
    "lambda" => lambda{|x| x>0}
  }

  stats["Triggers"] = triggers

  # Actions
  actions = SortedHash.new
  actions["/GoTo"] = { "n" => objects.find_all{|obj| obj.is_a?(Dictionary) and obj[:S] == :GoTo}.length, "lambda" => lambda{|x| x>0} }
  actions["/GoToR"] = { "n" => objects.find_all{|obj| obj.is_a?(Dictionary) and obj[:S] == :GoToR}.length, "lambda" => lambda{|x| x>0} }
  actions["/GoToE"] = { "n" => objects.find_all{|obj| obj.is_a?(Dictionary) and obj[:S] == :GoToE}.length, "lambda" => lambda{|x| x>0} }
  actions["/Launch"] = { "n" => objects.find_all{|obj| obj.is_a?(Dictionary) and obj[:S] == :Launch}.length, "lambda" => lambda{|x| x>0} }
  actions["/Thread"] = { "n" => objects.find_all{|obj| obj.is_a?(Dictionary) and obj[:S] == :Thread}.length }
  actions["/URI"] = { "n" => objects.find_all{|obj| obj.is_a?(Dictionary) and obj.has_key?(:URI)}.length, "lambda" => lambda{|x| x>0} }
  actions["/Sound"] = { "n" => objects.find_all{|obj| obj.is_a?(Dictionary) and obj[:S] == :Sound}.length }
  actions["/Movie"] = { "n" => objects.find_all{|obj| obj.is_a?(Dictionary) and obj[:S] == :Movie}.length }
  actions["/Hide"] = { "n" => objects.find_all{|obj| obj.is_a?(Dictionary) and obj[:S] == :Hide}.length }
  actions["/Named"] = { "n" => objects.find_all{|obj| obj.is_a?(Dictionary) and obj[:S] == :Named}.length, "lambda" => lambda{|x| x>0} }
  actions["/SetOCGState"] = { "n" => objects.find_all{|obj| obj.is_a?(Dictionary) and obj[:S] == :SetOCGState}.length }
  actions["/Rendition"] = { "n" => objects.find_all{|obj| obj.is_a?(Dictionary) and obj[:S] == :Rendition}.length }
  actions["/Transition"] = { "n" => objects.find_all{|obj| obj.is_a?(Dictionary) and obj[:S] == :Transition}.length }
  actions["/Go-To-3D"] = { "n" => objects.find_all{|obj| obj.is_a?(Dictionary) and obj[:S] == :"Go-To-3D"}.length }
  actions["/JavaScript"] = { "n" => objects.find_all{|obj| obj.is_a?(Dictionary) and obj[:S] == :JavaScript}.length, "lambda" => lambda{|x| x>0} }

  stats["Actions"] = actions

  # FormAction
  fa = SortedHash.new
  fa["/AcroForm"] = { "n" => objects.find_all{|obj| obj.is_a?(Dictionary) and obj[:S] == :AcroForm}.length, "lambda" => lambda{|x| x>0} } 
  fa["/SubmitForm"] = { "n" => objects.find_all{|obj| obj.is_a?(Dictionary) and obj[:S] == :SubmitForm}.length, "lambda" => lambda{|x| x>0} } 
  fa["/ResetForm"] = { "n" => objects.find_all{|obj| obj.is_a?(Dictionary) and obj[:S] == :ResetForm}.length, "lambda" => lambda{|x| x>0} } 
  fa["/ImportData"] = { "n" => objects.find_all{|obj| obj.is_a?(Dictionary) and obj[:S] == :ImportData}.length, "lambda" => lambda{|x| x>0} } 

  stats["FormActions"] = fa


  stats
end


#
# rescan
# 
def restat(pdf, regexp, obj, fct)

  pdf.pos = 0
  n = 0
  regexp.each do |re|
    n = n + 1 while pdf.skip_until(re)
  end

  return {
#    "Name" => obj,
    "n" => n,
    "lambda" => fct
  }
end

def rescan(pdf, stats)

  # rebuilding the pdf removes obfuscation
  # BUG: with /Linearized PDF, calling to_bin just consider the last
  # revision if several are present ... instead of summing all
  # elements of the multiple revisions xref
  # FIX (temporary): dont rebuild xref
  pdfbin = pdf.to_bin(:rebuildxrefs => false)
  raw = StringScanner.new pdfbin

  # Structure
  #colorprint("[Structure]\n", Colors::CYAN)
  struct = SortedHash.new
  struct["Header"] = { "n" => pdf.header.to_s, "lambda" => nil}
  nrev = pdf.revisions.length
  struct["Revisions"] = { "n" => nrev.to_s, "lambda" => nil}
  struct["Catalog"] = restat(raw, [ /\/Catalog[^\w]/ ], "Catalog", lambda{|x| x!=1})
  struct["object"] = restat(raw, [ /\d+\s+\d+\s+obj\s+/m ], "object", nil) 
  struct["endobj"] = restat(raw, [/\s+endobj\s+\d+\s+\d+/m, /\s+endobj\s+xref/ ], "endobj", nil)
  struct["object"]["lambda"] = lambda{ |x| x != struct["endobj"]["n"] }
  struct["endobj"]["lambda"] = lambda{ |x| x != struct["object"]["n"] }
  struct["stream"] = restat(raw, [ />>\s*stream\s+/ ], "stream", nil) 
  struct["endstream"] = restat(raw, [ /\s*endstream\s+endobj/m ], "endstream", nil) 
  struct["stream"]["lambda"] = lambda{ |x| x != struct["endstream"]["n"] }
  struct["endstream"]["lambda"] = lambda{ |x| x != struct["endstream"]["n"] }
  struct["/ObjStm"] = restat(raw, [ /\/ObjStm/ ], "/ObjStm", lambda{|x| x>0}) 
  struct["xref"] = restat(raw, [ /^xref\s*/ ], "xref", lambda{|x| x!=nrev}) 
  struct["trailer"] = restat(raw, [ /^trailer\s*/ ], "trailer", lambda{|x| x!=nrev}) 
  struct["startxref"] = restat(raw, [ /^startxref\s*/ ], "startxref", lambda{|x| x!=nrev}) 
  struct["Root (current)"] = {"n" => pdf.revisions.last.trailer[:Root].to_s, "lambda" => nil} 
  struct["Size (current)"] = {"n" => pdf.revisions.last.trailer[:Size], "lambda" => nil} 

  stats["Structure"] = struct

  # Properties
  properties = SortedHash.new  
  properties["/Encrypt"] = restat(raw, [ /\/Encrypt[^\w]/ ], "/Encrypt", lambda{|x| x>0}) 
  properties["EmbeddedFile"] = restat(raw, [ /\/EF[^\w]/ ], "/EF", lambda{|x| x>0}) 
  
  stats["Properties"] = properties


  # Triggers
  triggers = SortedHash.new
  triggers["/OpenAction"] = restat(raw, [ /\/OpenAction[^\w]/ ], "/OpenAction", lambda{|x| x>0})
  triggers["/AA"] = restat(raw, [ /\/AA[^\w]/ ], "/AA", lambda{|x| x>0})
  triggers["/Names"] = restat(raw, [ /\/Names[^\w]<</ ], "/AA", lambda{|x| x>0})

  stats["Triggers"] = triggers
  #"

  # Actions
  actions = SortedHash.new
  actions["/GoTo"] = restat(raw, [ /\/GoTo[^\w]/ ], "/GoTo", lambda{|x| x>0})
  actions["/GoToR"] = restat(raw, [ /\/GoToR[^\w]/ ], "/GoToR", lambda{|x| x>0})
  actions["/GoToE"] = restat(raw, [ /\/GoToE[^\w]/ ], "/GoToE", lambda{|x| x>0})
  actions["/Launch"] = restat(raw, [ /\/Launch[^\w]/ ], "/Launch", lambda{|x| x>0})
  actions["/Thread"] = restat(raw, [ /\/Thread[^\w]/ ], "/Thread", nil)
  actions["/URI"] = restat(raw, [ /\/URI[^\w]/ ], "/URI", lambda{|x| x>0})
  actions["/Sound"] = restat(raw, [ /\/Sound[^\w]/ ], "/Sound", nil)
  actions["/Movie"] = restat(raw, [ /\/Movie[^\w]/ ], "/Movie", nil)
  actions["/Hide"] = restat(raw, [ /\/Hide[^\w]/ ], "/Hide", nil)
  actions["/Named"] = restat(raw, [ /\/Named[^\w]/ ], "/Named", lambda{|x| x>0})
  actions["/SetOCGState"] = restat(raw, [ /\/SetOCGState[^\w]/ ], "/SetOCGState", nil)
  actions["/Rendition"] = restat(raw, [ /\/Rendition[^\w]/ ], "/Rendition", nil)
  actions["/Transition"] = restat(raw, [ /\/Transition[^\w]/ ], "/Transition", nil)
  actions["/Go-To-3D"] = restat(raw, [ /\/Go-To-3D[^\w]/ ], "/Go-To-3D", nil)
  actions["/JavaScript"] = restat(raw, [ /\/JavaScript[^\w]/ ], "/JavaScript", lambda{|x| x>0})

  stats["Actions"] = actions

  # FormAction
  fa = SortedHash.new
  fa["/AcroForm"] = restat(raw, [ /\/AcroForm[^\w]/ ], "/AcroForm", lambda{|x| x>0})
  fa["/SubmitForm"] = restat(raw, [ /\/SubmitForm[^\w]/ ], "/SubmitForm", lambda{|x| x>0})
  fa["/ResetForm"] = restat(raw, [ /\/ResetForm[^\w]/ ], "/ResetForm", lambda{|x| x>0})
  fa["/ImportData"] = restat(raw, [ /\/ImportData[^\w]/ ], "/ImportData", lambda{|x| x>0})

  stats["FormActions"] = fa

  return stats
end




#
# Main
#

require 'getopt.rb'
type = get_params(:type)

if ARGV.size != 1
  puts "error: must give a file to analyze"
  exit
end

STDERR << "Reading file...\n"
pdf = PDF.read(ARGV[0], :verbosity => Parser::VERBOSE_QUIET)
stats = {}

id = SortedHash.new
id["File"] = {"n" => ARGV[0], "lambda" => nil}
id["FileSize"] = {"n" => File.stat(ARGV[0]).size, "lambda" => nil}

stats["File ID"] = id

stats = 
case type
  when 'fast'
    STDERR << "Fast scanning...\n"
    rescan(pdf, stats)
  when 'deep'
    STDERR << "Deep scanning...\n"
    lsscan(pdf, stats)
end

#print_analysis_term(stats)
output = get_params(:output)
case output
  when 'txt'
    print_analysis_term(stats)
  when 'html'
    print_analysis_html(stats)
end
