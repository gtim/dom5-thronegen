npm run build \
&& rsync --archive --verbose --recursive build/ /srv/http/thronegen.illwiki.com/public_html \
&& rsync --archive --verbose --recursive ../ThroneGen /srv/http/thronegen.illwiki.com/public_html
