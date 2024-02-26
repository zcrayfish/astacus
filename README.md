# astacus
reference gopher server frontend for the hURL hack, and a suggestion on how to deal with type w (particularly with w3m).

**Prerequisites**:
* busybox ash (or other suitable shell)
* curl (or an inetd-style gopher server)
* inetd or similar super server daemon.
* python3 (for percent encoding URLs)

**Installing**:
* copy the astacus.sh and urlencode scripts to a directory of your choice (/usr/local/bin will be used in the rest of the documentation)
* change file permissions to allow execution: 
  * chmod a+x /usr/local/bin/astacus.sh
  * chmod a+x /usr/local/bin/urlencode
* edit variables in the configuration section at the top of the astacus.sh script:
* * _PATH_ The location the scripts are installed to
  * _fqdn_ The hostname of the gopher server that will is sending the actual content
  * _port_ The TCP port of the same server
  * _usecurl_ enter true or false here, if true curl will be used to connect to the gopher server, otherwise the server will be executed
  * _gopherd_ full path to an inetd-style gopher daemon. Used only when _usecurl_ is set to false.
  * _gopherd_options_ If command line options need to be passed to the gopher daemon, set them here. Used only when _usecurl_ is set to false.  
* add astacus.sh to your inetd
  * For busybox inetd you could try something like this:
    
/etc/inetd.conf
```
astacus       stream  tcp6    nowait  wwwrun  /usr/local/bin/astacus.sh       astacus.sh
```
/etc/services
```
astacus       72/tcp
```

Note: It's suggested that you run astacus on a secondary port, and your actual gopher server on port 70. The example above shows astacus running on port 72.

**Usage**:
When making a hURL or type w link to a website, point the server and port field to astacus.

Here's two real-life gophermap entries as deployed on my own gopher server with astacus handling the web links:
```
wExample website  http://www.example.org  gopher.zcrayfish.soy  72
hExample website  URL:http://www.example.org  gopher.zcrayfish.soy  72
```
