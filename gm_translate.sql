create or replace function gm_translate(text)
returns text as
$$
select case
    when $1 = 'SELECT' then 'r'
    when $1 = 'UPDATE' then 'w'
    when $1 = 'USAGE' then 'U'
    when $1 = 'DELETE' then 'd'
    when $1 = 'INSERT' then 'a'
    when $1 = 'REFERENCES' then 'x'
    when $1 = 'TRIGGER' then 't'
    when $1 = 'TRUNCATE' then 'D'
    when $1 = 'r' then 'SELECT'
    when $1 = 'w' then 'UPDATE'
    when $1 = 'U' then 'USAGE'
    when $1 = 'd' then 'DELETE'
    when $1 = 'a' then 'INSERT'
    when $1 = 'x' then 'REFERENCES'
    when $1 = 't' then 'TRIGGER'
    when $1 = 'D' then 'TRUNCATE'
end;
$$ language sql immutable;


-- select gm_translate('SELECT');