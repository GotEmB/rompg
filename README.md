rompg
=====

Regional Ocean Modeling and Prediction Group at UCLA JIFRESSE

tl; dr instructions for Forever
-------------------------------

* Start script using `forever start -c coffee web.coffee`.
* Stop script using `forever stop <uid>`.
* Get `uid` by running `forever list`.

west.rssoffice.com
------------------
* `forever`, `coffee`, `grunt`, `bower` installed in '/home/gotemb/node_modules/.bin' (west.rssoffice.com).
* Using forever (https://github.com/nodejitsu/forever) to run NodeJS process.
* Currently NodeJS service does not start automtically when system reboots. Will have to manually start using `forever`.
* Main Website @ http://west.rssoffice.com:9080
* Blog @ http://west.rssoffice.com:9081