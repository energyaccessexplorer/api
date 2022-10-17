CMD = ${DB_NAME}${PGREST_SUFFIX}-postgrest-start

PMATCH="postgrest ${ETC}/${PGREST_CONF_FILE}"
PKILL = 'pkill -xf ${PMATCH}'
PGREP = 'pgrep -xf ${PMATCH}'

.ifndef env
env = development
.endif

.ifndef API_HOST
.error "API_HOST is not defined. Hej då."
.endif

.ifndef SSH
.error "SSH command is not defined. Hej då."
.endif

PGREST_CONF_FILE = ${DB_NAME}-${env}.conf
START_SCRIPT = ${DB_NAME}-${env}-postgrest-start
CHECK_SCRIPT = ${DB_NAME}-${env}-postgrest-check

PGRESTCONF = 'db-uri = "${PG}"\ndb-schema = "public"\ndb-anon-role = "guest"\nserver-unix-socket = "${PGREST_SOCKET}"\nserver-unix-socket-mode = "777"\nserver-proxy-uri = "${PGREST_PROXY}"\njwt-secret = "${PGREST_SECRET}"\n'
STARTSH = '\#!/bin/sh\n\nwhile ! ping -c 1 -w 1 example.org >/dev/null 2>&1; do\n\techo "No network access yet..."\ndone\n\npostgrest ${ETC}/${PGREST_CONF_FILE} </dev/null >/dev/null &\n'
CHECK = '\#!/bin/sh\n\nfunction tb {\n        ${SNITCH} "PostgREST Check. Failed $1" >/dev/null\n        exit 1\n}\n\nif ! pgrep -xf "postgrest ${ETC}/${PGREST_CONF_FILE}" >/dev/null; then\n        ${CMD}\n        tb "PostgREST not running. Starting it..."\nfi\n\nif ! curl --silent --fail --unix-socket ${PGREST_SOCKET} http://localhost/ >/dev/null; then\n        pkill -SIGUSR1 postgrest\n        tb "curl ${PGREST_SOCKET}. Reloaded..."\nfi\n\nif ! curl --silent --fail ${PGREST_PROXY} >/dev/null; then\n        tb "curl ${PGREST_PROXY}"\nfi\n'

pgrest.conf:
	@printf ${PGRESTCONF} | envsubst >dist/${PGREST_CONF_FILE}

start.sh:
.export ETC
.export PGREST_CONF_FILE
	@printf ${STARTSH} | envsubst >dist/${START_SCRIPT}
	@chmod +x dist/${START_SCRIPT}

check.sh:
.export PG
.export DB_NAME
.export CMD
.export ETC
.export PGREST_CONF_FILE
.export PGREST_SOCKET
.export PGREST_PROXY
.export PGREST_SECRET
.export TIME
.export SNITCH
.export CURL
	@printf ${CHECK} | envsubst >dist/${CHECK_SCRIPT}
	@chmod +x dist/${CHECK_SCRIPT}

apiclean:
	rm -f dist/*

apibuild:
	@mkdir -p dist
	@bmake pgrest.conf start.sh check.sh

apisignin:
	psql ${PG} \
		--pset="pager=off" \
		--pset="tuples_only=on" \
		--command="select 'localStorage.setItem(\"token\", \"' || sign(row_to_json(r), '${PRIVATE_KEY}') || '\");' from (select '${ADMIN_ROLE}' as role, extract(epoch from now())::integer + 600*60 as exp) as r" | \
		xclip -selection clipboard

	@echo "Signed in as '${ADMIN_ROLE}'. Token copied to clipboard."

apisync:
	@scp dist/${PGREST_CONF_FILE} ${API_HOST}:${ETC}/
	@scp \
		dist/${START_SCRIPT} \
		dist/${CHECK_SCRIPT} \
		${API_HOST}:${BIN}/

apideploy: apisync apistop apistart apicheck

apistart:
.if ${env} == "development"
	./dist/${CMD}
.else
	${SSH} ${CMD} &
	@sleep 2
.endif

apistop:
.if ${env} == "development"
	-eval ${PKILL}
.else
	-${SSH} ${PKILL}
.endif

apicheck:
.if ${env} == "development"
	eval ${PGREP}
.else
	${SSH} ${PGREP}
.endif

apirestart: apistop apistart apicheck
