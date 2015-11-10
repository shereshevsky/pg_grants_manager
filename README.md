# pg_grants_manager
PostgreSQL automated grants managment


## Install
```sh
cd ~
git clone https://github.com/shereshevsky/pg_grants_manager.git
cd pg_grants_manager
make
sudo make install
make installcheck # (optional)
```

```sh
psql -Upostgres -d database_name -c "create extension grants_manager"
```

## Example

Create some tables and grant permissions to test user:

```sql
postgres=# create user test_user;
CREATE ROLE
postgres=#
postgres=# create table test_table_n (col1 int4);
CREATE TABLE
postgres=#
postgres=# create table test_table_r (col1 int4);
CREATE TABLE
postgres=#
postgres=# grant select on test_table_r to test_user;
GRANT
```

### Use Case 1: Generate current permissions map granted to users in the DB

Generate current permissions report. The function creates table with permissions
snapshot you can use for report or grants managment:


```sql
postgres=# select gm_generate_current();
 gm_generate_current
---------------------

(1 row)

postgres=# select object_name, test_user from public.grants_manager
postgres-# where
postgres-#   (schema_name, object_type) = ('public', 'TABLE')
postgres-#   and object_name in ('test_table_n', 'test_table_r')
postgres-# ;
 object_name  | test_user
--------------+-----------
 test_table_n | {}
 test_table_r | {r}
(2 rows)
```

### Use Case 2: provide simple grants manipulation declarative toolset

Modify user permissions by simple updates:
```sql
postgres=# update public.grants_manager set test_user = '{r, w, D}' where object_name = 'test_table_n';
UPDATE 1
postgres=# update public.grants_manager set test_user = '{}' where object_name = 'test_table_r';
UPDATE 1
postgres=#
postgres=# select object_name, postgres, test_user from public.grants_manager
postgres-# where
postgres-#   (schema_name, object_type) = ('public', 'TABLE')
postgres-#   and object_name in ('test_table_n', 'test_table_r')
postgres-# ;
 object_name  | test_user
--------------+-----------
 test_table_n | {r,w,D}
 test_table_r | {}
(2 rows)
```

### Use Case 3: Provide report for any permisions not matching the declaration

Check and report only unaligned table permissions (optrional):
```sql
postgres=# select gm_align_permissions(p_execute := false);
NOTICE:  test_table_n table permissions for user test_user not aligned. current - {}, should be - {r,w,D}
NOTICE:  test_table_r table permissions for user test_user not aligned. current - {r}, should be - {}
 gm_align_permissions
----------------------

(1 row)

```

### Use Case 4: Automatically align DB permissions

Automatically align table permissions to these declared in grants_manager table:
```sql
postgres=# select gm_align_permissions(p_execute := true);
 gm_align_permissions
----------------------

(1 row)
```

That's all, everything aligned.


## TBD 

* support group permissions for alignment
