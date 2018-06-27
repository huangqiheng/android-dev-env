
var path = require('path'),  
config;

config = {  
	// ### Production
	// When running Ghost in the wild, use the production environment.
	// Configure your URL and mail settings here
	production: {
		url: 'http://www.denpe.com',
		mail: {},
		database: {
			client: 'sqlite3',
			connection: {
				filename: path.join(__dirname, '/content/data/ghost.db')
			},
			debug: false
		},
			// server: {
			//     host: '127.0.0.1',
			//      port: '2368'
			//  }

		server: {
			socket: {
				path: '/srv/www/denpe.com/socket.sock',
				permissions: '0666'
			}
		}
	},
};


chmod 777 /srv/www/denpe.com/socket.sock


upstream ghost_upstream {  
    server unix:/srv/www/denpe.com/socket.sock;
        keepalive 64;
}

proxy_cache_path /srv/www/cache levels=1:2 keys_zone=STATIC:100m inactive=24h max_size=512m;

server {  
	listen 80;
	server_name www.denpe.com;
	add_header X-Cache $upstream_cache_status;
	access_log /srv/www/logs/denpe.com.log;
	error_log  /srv/www/logs/error.log;

	location /content/images {
		alias /srv/www/denpe.com/content/images;
		access_log off;
		expires max;        
	}

	location /assets {
		alias /srv/www/denpe.com/content/themes/casper/assets;
		access_log off;
		expires max;         
	} 

	location /public {
		alias /srv/www/denpe.com/core/built/public;
		access_log off;
		expires max;        
	}

	location /ghost/scripts {
		alias /srv/www/denpe.com/core/built/scripts;
		access_log off;
		expires max;         
	}

	location ~ ^/(?:ghost|signout) {
		proxy_set_header Host      $http_host;
		proxy_set_header X-Real-IP $remote_addr;
		proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
		proxy_set_header X-Forwarded-Proto $scheme;
		proxy_pass http://ghost_upstream;
		add_header Cache-Control "no-cache, private, no-store, must-revalidate, max-stale=0, post-check=0, pre-check=0";
		proxy_redirect off;
	}

	location / {
		proxy_cache STATIC;
		proxy_cache_valid 200 60m;
		proxy_cache_valid 404 1m;
		proxy_ignore_headers X-Accel-Expires Expires Cache-Control;
		proxy_ignore_headers Set-Cookie;
		proxy_hide_header Set-Cookie;
		proxy_hide_header X-powered-by;    
		proxy_set_header X-Real-IP $remote_addr;
		proxy_set_header Host $http_host;
		proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
		proxy_pass http://ghost_upstream;
		expires 10m;
	}
}

server {  
	server_name denpe.com 107.167.184.244;
	return 301 http://www.denpe.com$request_uri;
}


rm -r /srv/www/cache/*  
find /home/nginx/ghostcache -type f -delete

Testing the cache
Now that the cache is setup and you've loaded your new config, you can try out the cache to to see how it performs. Just clicking around my site I can immediately tell that it's a lot faster. That's not very scientific though so let's create a test. I created two scripts.


cat with-cache.sh

for run in {1..10}
do
	curl https://scotthelme.co.uk > /dev/null
done

cat without-cache.sh

for run in {1..10}
do
	curl -H "Cache-Control: no-cache" https://scotthelme.co.uk > /dev/null
done

time ./with-cache.sh
real    0m13.066s

time ./without-cache.sh
real    0m14.346s
