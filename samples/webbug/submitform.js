try
{

  app.alert("First, I try to launch your browser :)");
  app.launchURL("http://localhost/webbug-browser.html");
  
}
catch(e)
{
}

try
{
  app.alert("Now I try to connect to the website, through your Reader");

  this.submitForm( 
  { 
    cURL: "http://localhost/webbug-reader.php",
    bAnnotations: true,
    bGet: true,
    cSubmitAs: "XML"
  });
}
catch(e)
{
}
