/*
 * CAS 2.0 (Central Authentication Service) client integration
 * Michael Sharman (michael[at]chapter31.com)
 * http://learnosity.com/
 *
 * v0.1 - 26 September 2012
 *
 * Note: this class does not implement the Gateway feature of the CAS protocol
 *
 * Usage:
 *	// Setup a hashmap of parameters to pass to the constructor
 * 	var casOptions = {
 *		appBaseURI = "http://www.example.com/",
 *		casBaseURI = "https://cas.example.com/"
 *	}
 *	var CAS = new CAS(casOptions);
 *
 *	// Your application calls this to redirect a user to your CAS login page
 *	CAS.authenticate();
 *
 *	// This should be called from the return URL you send to CAS. Used to validate the serviceTicket CAS provides
 *	CAS.validate(ticket);
 *
 *	// This logs a user out of a remote CAS server (note: you should handle destroying your applications session separately)
 *	CAS.logout();
 */
component displayname="CAS" output="false"
{

	/**
	* @hint Contructor, pass in an optional hashmap of options to override any defaults
	**/
	public any function init(struct params)
	{
		// Set defaults here if you don't want to pass values in to the constructor every time
		variables.instance = {
			appBaseURI 			= "",					// URI (with trailing slash) of your application eg http://www.myapp.com/
			appValidatePath 		= "auth/validate",		// Path used (from your appBaseURI) for CAS to send a serviceTicket to validate
			casBaseURI 			= "",					// URI of the CAS service (with trailing slash)
			casLoginPath 			= "login?service=",		// Path used (from casBaseURI) for any login attempts
			casLogoutPath 			= "logout",				// Path used (from casBaseURI) to log a user out of the remote CAS server
			casValidatePath 		= "serviceValidate",		// Path used (from casBaseURI) when your app validates a service ticket
			logErrors				= true,					// Whether this class will log any errors (to a system log file)
			logFilename 			= application.applicationName,
			throwOnError 			= true 					// Whether to halt and show a message in the event of an exception, useful for development/debugging
		}
		// Override defaults with parameters passed in to the constructor
		if (structKeyExists(arguments, "params") && isStruct(arguments.params))
		{
			structAppend(variables.instance, arguments.params, true);
		}
		// If a log filename wasn't passed (or set as a default), try to use the application name
		if (!len(variables.instance.logFilename) && isDefined(application.applicationName))
		{
			variables.instance.logFilename = application.applicationName;
		}
		// Validate that we have everything we need before returning
		if (!len(variables.instance.casBaseURI) || !len(variables.instance.appBaseURI))
		{
			throw(type="error", message="Please check that you've passed in URIs for CAS and your app");
		}
		return this;
	}


	/**
	* @hint Redirect's a user to a nominated CAS server for authentication
	* */
	public void function authenticate()
	{
		try
		{
			var casURI = variables.instance.casBaseURI & variables.instance.casLoginPath;
			var returnURI = variables.instance.appBaseURI & variables.instance.appValidatePath;
			location(url=casURI & returnURI, addToken=false);
		}
		catch (any e)
		{
			writeToLog(msg="Error redirecting to CAS. #e.message#");
			if (variables.instance.throwOnError)
			{
				dump(var="#e#");abort;
			}
		}
	}


	/**
	* @hint Logs a user out of the remote CAS system
	* */
	public void function logout()
	{
		try
		{
			var logoutURI = variables.instance.casBaseURI & variables.instance.casLogoutPath;
			http
				url=logoutURI
				method="GET"
				redirect=false
				throwOnError=true
				timeout=10
				addtoken=false;
		}
		catch (any e)
		{
			writeToLog(msg="Error logging out of CAS. #e.message#");
			if (variables.instance.throwOnError)
			{
				dump(var="#e#");abort;
			}
		}
	}


	/**
	* @hint Runs an http check back against a CAS server to validate the `service ticket` (that was returned from a CAS server)
	* @return A string of XML from the CAS server
	**/
	public string function validate(required string ticket)
	{
		try
		{
			var validateURI = variables.instance.casBaseURI & variables.instance.casValidatePath & "?service=" & variables.instance.appBaseURI & variables.instance.appValidatePath & "&ticket=" & arguments.ticket;
			if (structKeyExists(arguments, "ticket") && len(arguments.ticket))
			{
				http
					url=validateURI
					method="GET"
					redirect=false
					throwOnError=true
					timeout=10
					addtoken=false;

				if (cfhttp.status_code == 200)
				{
					if (isXML(cfhttp.fileContent))
					{
						return cfhttp.fileContent;
					}
					else
					{
						throw(type="error", message="XML wasn't returned from the CAS validate, instead it returned #cfhttp.fileContent#");
					}
				}
				else
				{
					throw(type="error", message="auth.validate() Non-200 status returned | #cfhttp.fileContent#");
				}
			}
			else
			{
				throw(type="error", message="No service ticket passed");
			}
		}
		catch (any e)
		{
			writeToLog(msg="CAS.validate() #e.message#");
			if (variables.instance.throwOnError)
			{
				dump(var="#e#");abort;
			}
		}
	}


	/**
	* @hint Convenience function to write a message to a system log file. Whether to log or not can be controlled by an instance variable `logErrors`
	**/
	private void function writeToLog(required string msg, string type = "error")
	{
		if (variables.instance.logErrors)
		{
			writeLog(type=arguments.type, text=arguments.msg, file=variables.instance.logFilename);
		}
	}

}
