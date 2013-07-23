# Additional setup - REST client

## Special requirements
* Apache with mod_cgi and mod_auth_basic

## Additional perl module
* CGI

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

Your REST service should be available now.
