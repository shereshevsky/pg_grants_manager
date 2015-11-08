EXTENSION 	= grants_manager
DATA 		= grants_manager--0.0.1.sql
TESTS       = $(wildcard test/sql/*.sql)

all: grants_manager--0.0.1.sql

grants_manager--0.0.1.sql: complain.txt gm_array_sort.sql gm_translate.sql gm_get_status.sql gm_generate_current.sql gm_align_permissions.sql
		cat complain.txt gm_array_sort.sql gm_translate.sql gm_get_status.sql gm_generate_current.sql gm_align_permissions.sql > grants_manager--0.0.1.sql

REGRESS_OPTS  = --inputdir=test         \
                --load-extension=grants_manager \
                --load-language=plpgsql
REGRESS       = $(patsubst test/sql/%.sql,%,$(TESTS))

# postgres build stuff
PG_CONFIG = pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)