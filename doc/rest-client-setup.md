# Additional setup - REST client

You will find a full API description here: [api.md](api.md "api.md")

## Special requirements
* Apache with mod_cgi and mod_auth_basic

## Additional perl module
* CGI
* String::CRC32

## Step 1 - Setup basic authentication

Create a **.htusers** on your system in your prefered path.

```
htpasswd -c .htusers USERNAME
```
 
## Step 2 - Setup a virtual host in apache (as root)

Create a new virtual host in **/etc/apache2/sites-available**. You could use the [example_apache_virtual_host](../doc/example_apache_virtual_host "example_apache_virtual_host"). We renamed it to **rest** for example. Edit all paths to your needs.

Enable the new virtual host

```
a2ensite rest
```

Restart or reload  the apache server

```
service apache2 [restart/reload]
```

## Step 3 - Make database writeable

Ensure, that the directory with your database file is writeable from your webserver.
In debian systems with apache2 you have to:

* set the group attribute on database file to www-data
* set the parent directory to writeable 

Congratulation's, your own REST service should be available now.
