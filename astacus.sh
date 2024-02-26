#! /bin/ash
#####Configuration section#####
#readonly PATH=
#The fqdn variable defines the hostname of the gopher server you'll be proxying to gemini.
readonly fqdn=gopher.zcrayfish.soy
#The port variable defines the TCP port of the gopher server you'll be proxying to gemini.
readonly port=70
#Use curl, or use the gopher daemon directly
usecurl=true
#full path to gopher daemon
readonly gopherd=/usr/sbin/gophernicus
#command options to pass to the gopher daemon
readonly gopherd_options="-h $fqdn -nv -nf -np -f /srv/gopher/filters -o utf-8 -l /var/log/gopher.access.log -T 300"
####End of configuration section, use caution if editing below this line####

#pull in the entire request and toss it into the gopherrequest variable
IFS= read -t 30 -r gopherrequest

#function to handle clients that don't support gophertype w
typew () {
  printf '\xEF\xBB\xBF'
  printf '%s\15\12' "Your gopher client does not support gophertype w." \
    "the URL that your gopher client should have sent you to is:" \
    "$1"
}

#function to handle clients that don't support the hURL hack.
hURL () {
  printf '\xEF\xBB\xBF'
  printf '%s\15\12' '<?xml version="1.0" encoding="UTF-8"?>' \
    '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"' \
    '    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">' \
    '<html xmlns="http://www.w3.org/1999/xhtml">' \
    '<head>' \
    '  <meta http-equiv="Content-Type" content="application/xhtml+xml; charset=utf-8" />' \
    "  <meta http-equiv=\"refresh\" content=\"1;URL=$1\" />" \
    "  <meta http-equiv=\"location\" content=\"$1\" />" \
    "  <title>Redirect to: $1</title>" \
    '</head>' \
    '<body>' \
    '<p>You are following a link from gopher to another URL or protocol.' \
    'You should be automatically taken to the site shortly.' \
    "If you don't get sent there, please use the URL below to get there:</p>" \
    "<p><a href=\"$1\">$1</a></p>" \
    '</body></html>'
}

#This is where the magic happens, see if the request matches a client that doesn't know what to do with type w
#or with hURL.
case "$gopherrequest" in
  http://*|https://*|ftp://*|irc://*|ircs://*|mailto:*)
        #w3m converts the query string initiator into tab...
	typew "$gopherrequest" | sed -e 's/	/?/g'
  ;;
  whttp://*|whttps://*|wftp://*|wirc://*|wircs://*|wmailto:*)
	#the cuts here are because some clients prepend the gophertype to the request.
	#Fun fact: some older servers expected this behavior!
	typew "$(echo "$gopherrequest" | cut -b 2- | sed -e 's/	/?/g')"
  ;;
  w/http://*|w/https://*|w/ftp://*|w/irc://*|w/ircs://*|w/mailto:*)
	typew "$(echo "$gopherrequest" | cut -b 3- | sed -e 's/	/?/g')"
  ;;
  URL:http://*|URL:https://*|URL:ftp://*|URL:irc://*|URL:ircs://*|URL:mailto:*)
        #for hURLs, don't encode : and completely drop CR and LF.
        #dropping CRLF in one go breaks w3m.
	hURL "$(echo "$gopherrequest" | cut -b 5- | urlencode | sed -e 's/%3A/:/g' -e 's/%0D//g' -e 's/%0A//g')"
  ;;
  /URL:http://*|/URL:https://*|/URL:ftp://*|/URL:irc://*|/URL:ircs://*|/URL:mailto:*)
	hURL "$(echo "$gopherrequest" | cut -b 6- | urlencode | sed -e 's/%3A/:/g' -e 's/%0D//g' -e 's/%0A//g')"
  ;;
  h/URL:http://*|h/URL:https://*|h/URL:ftp://*|h/URL:irc://*|h/URL:ircs://*|h/URL:mailto:*)
	hURL "$(echo "$gopherrequest" | cut -b 7- | urlencode | sed -e 's/%3A/:/g' -e 's/%0D//g' -e 's/%0A//g')"
  ;;
  *)
	export REMOTE_HOST
	export REMOTE_PORT
	export REMOTE_ADDR="$REMOTE_HOST"
        if [ "$usecurl" = "true" ] ; then
	  #We use /0 in the URL to make it valid for curl; ditto for the tab removal and the carriage return removal.
	  #Many versions of curl fail with ZERO output if the URL contains a carriage return.
          gopherrequestsanitized="$(echo "$gopherrequest" | sed -e 's/	/?/g' -e 's/\r$//g')"
	  gopherurl="gopher://$fqdn:$port/0$gopherrequestsanitized"
          curl -q --disable -s --output - "$gopherurl"
	else
	  echo "$gopherrequest" | ${gopherd} ${gopherd_options}
	fi
  ;;
esac
exit
