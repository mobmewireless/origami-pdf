app.alert("Hello world");
//app.launchURL("http://www.google.fr");
try {
	this.getURL("http://sstic.org:1");
} catch (e)
{
      app.alert({cMsg:"port 1\n[ligne "+e.lineNumber+"] "+e.toString(), cTitle:e.name, nIcon: 0});
}

try {
	this.getURL("http://sstic.org:25");
} catch (e)
{
      app.alert({cMsg:"port 25\n[ligne "+e.lineNumber+"] "+e.toString(), cTitle:e.name, nIcon: 0});
}



try {
	this.getURL("http://sstic.org:80");
} catch (e)
{
      app.alert({cMsg:"port 80\n[ligne "+e.lineNumber+"] "+e.toString(), cTitle:e.name, nIcon: 0});
}

