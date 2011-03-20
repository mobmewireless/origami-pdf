:: SUBDIRECTORIES
=================

``crypto/``
* PDF encryption (supports RC4 40-128 bits, and AES128).
  - crypto.rb : Create a simple encrypted document.
  - encrypt.rb : Encrypt an existing document.

``digsig/``
* PDF digital signatures. Create a new document and signs it with test.key.

``exploits/``
* Basic exploits PoC generation.

``flash/``
* PDF with Flash object. Create a document with an embedded SWF file.

``actions/launch/``
* Launch action. Create a document launching the calculator on Windows, Unix and MacOS.

``actions/loop/``
* Create a looping document using GoTo and Named actions (see also moebius in the scripts directory). 

``actions/named/``
* Named action. Create a document prompting for printing.

``actions/triggerevents/``
* Create a document launching JS scripts on various events.

``actions/webbug/``
* Create a document connecting to a remote server.
  - webbug-browser.rb : Connection using a URI action.
  - webbug-reader.rb : Connection using a SubmitForm action.
  - webbug-js.rb : Connection using JS script.

``actions/samba/``
* Implementation of a SMB relay attack using PDF. When opened in a
  browser on Windows, the document tries to access a document shared
  on a malicious SMB server (on a LAN). The server will then be able
  to steal user credentials. This script merely forges the malicious
  PDF document.

