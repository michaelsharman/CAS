# CAS 2.0 (Central Authentication Service) client integration

This is a ColdFusion component for integrating an application with a CAS server.

**Note: this class does not implement the Gateway feature of the CAS protocol**
 
 ## Usage:
```
// Setup a hashmap of parameters to pass to the constructor
var casOptions = {
    appBaseURI = "http://www.example.com/",
    casBaseURI = "https://cas.example.com/"
}
var CAS = new CAS(casOptions);

// Your application calls this to redirect a user to your CAS login page
CAS.authenticate();

// This should be called from the return URL you send to CAS. Used to validate the serviceTicket CAS provides
CAS.validate(ticket);

// This logs a user out of a remote CAS server (note: you should handle destroying your applications session separately)
CAS.logout();
```
