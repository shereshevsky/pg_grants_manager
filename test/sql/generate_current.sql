begin;

create user test_user;

create table test_table_r (col1 int4);
create table test_table_w (col1 int4);
create table test_table_d (col1 int4);
create table test_table_a (col1 int4);
create table test_table_x (col1 int4);
create table test_table_t (col1 int4);
create table test_table_dd (col1 int4);
create sequence test_sequence_u;

grant select on test_table_r to test_user;
grant update on test_table_w to test_user;
grant delete on test_table_d to test_user;
grant insert on test_table_a to test_user;
grant references on test_table_x to test_user;
grant trigger on test_table_t to test_user;
grant truncate on test_table_dd to test_user;
grant usage on test_sequence_u to test_user;

select gm_generate_current();

select object_name, postgres, test_user from public.grants_manager
where (
  (schema_name, object_type) = ('public', 'TABLE')
  and object_name in ('test_table_r', 'test_table_w', 'test_table_d',
    'test_table_a', 'test_table_x', 'test_table_t', 'test_table_dd')
  ) or (
  (schema_name, object_type, object_name)
    = ('public', 'SEQUENCE', 'test_sequence_u')
  )
;

rollback;