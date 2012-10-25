					README
			
			crclient 1.1 for Unix/Linux

Contents
	* Introduction
	* Make 
	* Options
	* Example of Configuration File


Introduction 
	
	Cyberoam Client is a part of the Cyberoam product which is a complete solution to
	Employee Internet Management. This tool provides an interface for the client to 
	communicate with the Cyberoam server. There are various options provided which help the
	client to effectively communicate with the server.

Make
	crclient supports two modes at the time of compilation. 
	1) Single Login
	2) Multiple Login
		In case of single login only one user is allowed to login at a time. For 
	enabling single mode the macro CFLAGS in the Makefile has to be disabled.
		#CFLAGS=-D__MULTILOGIN__

		In case of multiple login option the more then one user can login at a given 
	time. The macro CFLAGS has to be enabled before making the files.
		CFLAGS=-D__MULTILOGIN__

	Other make options include the clean option. Before making the file after the macro is
	enabled/disabled the clean option should be used.
		Ex.
			$make clean.	
	
Options
	
	-u :	The option is responsible for sending a login request to the server. It requires 
		username as a parameter.

	-s :	The option is for setting preferences for the client. Preferences such as AskonExit,
		AutoLogin, ShowNotification and Server Address can be set using this option. The 
		preference values are then reflected in the Configuration file.
	
	-l:	This option is used to send a logout request to the server. In case of Multiple 
		Login mode this option requires argument i.e Username. 

	-h:	 provides help for the client.

	-d:	Specify the location for log file.

	-v:	Sets the verbose mode on. This option is for debugging purpose. 

	-V:	Provides Current Version information.

	-f: 	Specify the location for the configuration file.

Example of Configuration File

	AskonExit       0
	AutoLogin       0
	FirstTime       1
	Password
	Port    6060
	SavePassword    0
	Server  192.9.203.203
	User    ankit
	ShowNotification        1
	LiveRequestTime 180
	AlreadyLoggedIn 0
	VersionId       1
	Version crclient1.1
	
	The configuration file includes the above showm parameters. First Configuration file is searched
	at /etc, if not found  it is searched in the user's home directory. If the configuration file is 
	not found at both the places a file is created in the user's home directory by accepting the 
	essential parameters from the User.
 
NOTE : 

i)	User has to manually disable the SavePassword option in the configuration file by setting the 
	value of SavePassword field to zero , once the option is enabled.

ii)	Also, if the savepassword option is enabled and Password field is found to be null in the
	configuration file the user have to disable the savepassword option i.e by setting the
	SavePassword field to 0, inoder to login.

iii) If -f option is specified the full path along with the filename should be specified.
	 Ex. /home/ankit/CyberClient.conf.

iv) In case of Sun Solaris the multiple process issue is vulnerable.No gaurantee is taken to 
	control multiple client process invocation.

v)  In case of '-d' option if log file cannot be opened at the specified location client exits.
	In absence of '-d' option preference for log location is
	1) '/var/log'
	2) Users home directory
	3) '/tmp'
	If all the three preferences fail logging will be done on standard output.

