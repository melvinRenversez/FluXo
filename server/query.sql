use fluxo;

drop table if exists links;
create table links(
	id int auto_increment primary key,
	url varchar(255) not null unique,
	title varchar(255) not null,
	duration float not null,
	status_id int not null default 1,

	startDownload_at timestamp,
	endDownload_at timestamp,

	created_at timestamp default current_timestamp,

	foreign key (status_id) references status(id)
);

alter table links add column startDownload_at timestamp;
alter table links add column endDownload_at timestamp;


delete from links where id between 0 and 10000;

update links set status_id = 1, startDownload_at = null, endDownload_at = null where id between 0 and  100000;

select l.id, url, title, duration, libelle
from links l
join status s on l.status_id = s.id;


insert into links(url, title, duration) values('https://www.youtube.com/watch?v=dQw4w9WgXcQ', 'Rick Astley - Never Gonna Give You Up (Video)', 212.0);


drop table if exists status;
create table status(
	id int auto_increment primary key,
	libelle varchar(255) not null unique
);
select * from status;

insert into status(libelle) values('Pending'), ('Progress'), ('Completed'), ('Failed');


select * from links;


select id, title, url from links where status_id = 1 or status_id = 2;



drop table if exists search;
create table search(
	id int auto_increment primary key,
	title varchar(255) not null,
	image varchar(255) not null,
	type varchar(255) not null,
	video varchar(255) not null,
	date integer not null,
	description longtext not null,
	page integer not null,
	idx integer not null,
    
	created_at timestamp default current_timestamp
);

select * from search order by title;
select * from search where title like "%perf%";