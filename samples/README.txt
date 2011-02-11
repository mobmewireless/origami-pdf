:: SUBDIRECTORIES
=================

``crypto/``
* PDF encryption (supports RC4 40-128 bits, and AES128).
  - crypto.rb : Create a simple encrypted document.
  - encrypt.rb : Encrypt an existing document.

``digsig/``
* PDF digital signatures. Create a new document and signs it with test.key.

``flash/``
* PDF with Flash object. Create a document with an embedded SWF file.

``launch/``
* Launch action. Create a document launching the calculator on Windows, Unix and MacOS.

``loop/``
* Create a looping document using GoTo and Named actions (see also moebius in the scripts directory). 

``Named/``
* Named action. Create a document prompting for printing.

``triggerevents/``
* Create a document launching JS scripts on various mouse events.

``webbug``
* Create a document connecting to a remote server.
  - webbug-browser.rb : Connection using a URI action.
  - webbug-reader.rb : Connection using a SubmitForm action.
  - webbug-js.rb : Connection using JS script.

``open``
* Various methods to trigger an action at the document opening.

