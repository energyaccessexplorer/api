DB_NAME = eae_dev
PG = postgres://postgres@localhost/${DB_NAME}

ETC = /etc
API_HOST = api.example.org
API_URL = https://api.example.org

PGREST_PROXY = http://api.localhost
PGREST_SECRET = /path/to/public.jwk
PGREST_SOCKET = /var/www/tmp/postgrest.sock

PRIVATE_KEY = /path/to/private.pem

SSH = ssh ${API_HOST}

SNITCH = echo

.include <api.mk>
