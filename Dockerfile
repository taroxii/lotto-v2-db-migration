# lotto-v2-db-migration — migrate runner image
# Bundles the golang-migrate binary + migration SQL. Intended to run as a
# k8s initContainer before backend / reward_batch pods start:
#   command: ["migrate","-path","/migrations","-database","$(DB_URL)","up"]
#
# For baselining an existing data-bearing DB, override the command:
#   command: ["migrate","-path","/migrations","-database","$(DB_URL)","force","5"]

FROM migrate/migrate:v4.17.1

COPY migrations/ /migrations/

# default: apply all. DB_URL supplied via env at runtime.
ENTRYPOINT ["migrate", "-path", "/migrations"]
CMD ["-database", "${DB_URL}", "up"]
