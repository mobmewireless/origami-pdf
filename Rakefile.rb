# encoding: UTF-8

require 'rubygems'
require 'rdoc/task'
require 'rake/testtask'
require 'rubygems/package_task'

spec = Gem::Specification.new do |s|
  s.name       = "origami"
  s.version    = "1.2.5"
  s.author     = "Guillaume Delugre"
  s.email      = "guillaume at security-labs dot org"
  s.homepage   = "http://code.google.com/p/origami-pdf"
  s.platform   = Gem::Platform::RUBY
  
  s.summary    = "Origami aims at providing a scripting tool to generate and analyze malicious PDF files."
  s.description = <<DESC
Origami is a PDF-compliant parser. This is not a PDF rendering library, it aims at providing a scripting tool to generate and analyze malicious PDF files. 
As well, it can be used to create on-the-fly customized PDFs, or to inject (evil) code into already existing documents.
DESC

  s.files             = FileList[
    'README', 'COPYING.LESSER', "{lib,bin,tests,samples,templates}/**/*", "bin/shell/.irbrc"
  ].exclude(/\.pdf$/, /\.key$/, /\.crt$/, /\.conf$/).to_a

  s.require_path      = "lib"
  s.has_rdoc          = true
  s.test_file         = "test/ts_pdf.rb"
  s.requirements      = "ruby-gtk2 if you plan to run the PDF Walker interface"

  s.bindir            = "bin"
  s.executables       = [ "pdfdecompress", "pdfdecrypt", "pdfencrypt", "pdfmetadata", "pdf2graph", "pdf2ruby", "pdfextract", "pdfcop", "pdfcocoon", "pdfsh", "pdfwalker", "pdf2pdfa" ]
end

task :default => [:package]

Gem::PackageTask.new(spec) do |pkg|
  pkg.need_tar = true
end

desc "Generate rdoc documentation"
Rake::RDocTask.new("rdoc") do |rdoc|
  rdoc.rdoc_dir = "doc"
  rdoc.title = "Origami"
  rdoc.options << "-U" << "-N"
  rdoc.options << "-m" << "Origami::PDF"

  rdoc.rdoc_files.include("lib/origami/**/*.rb")
end

desc "Run the test suite"
Rake::TestTask.new do |t|
 t.verbose = true
 t.libs << "test" 
 t.test_files = FileList["test/ts_pdf.rb"]
end

task :clean do
  %x{rm -rf pkg doc}
end
