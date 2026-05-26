create table if not exists tasks (
  id      integer generated always as identity primary key not null,
  title   text        not null,
  done_at timestamptz
);
