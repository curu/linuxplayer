var proxy = "192.168.1.254:3128";

//[network, netmask]
var networks = [
	['192.168.1.0', '255.255.255.0']
	];

var domains = [
        '.facebook.com',
        '.fbcdn.net',
        'twitter.com',
        '.twimg.com',
		'.mail-archive.com',
		'.blogspot.com',
		'.google.com',
		'.google.com.hk',
		'.googleusercontent.com',
		'.feedburner.com'
		];

function FindProxyForURL(url, host) {

// If URL has no dots in host name, send traffic direct.
	if (isPlainHostName(host))
		return "DIRECT";

// proxy by IP address
	var targetIP = dnsResolve(host);
	for(var i =0; i < networks.length; i++){
		if(isInNet(targetIP, networks[i][0], networks[i][1])){
            		return "PROXY " + proxy;
		}
	}
// proxy by domain name
	for (var i = 0; i < domains.length; i++){
		if(dnsDomainIs(host, domains[i])){
            		return "PROXY " + proxy;
		}
	}
        return "DIRECT";
	
}

