-- 1) Find the artist who has contributed with the maximum no of albums. Display the artist name and the no of albums.

with cte as 
       (
		select ar.name as name, count(*) as no_of_albums, rank() over(order by count(*) desc) as rnk
		from artist ar
		join album al on ar.artistid = al.artistid
		group by ar.artistid, ar.name
	   )
select name, no_of_albums
from cte
where rnk = 1;


-- 2) Display the name, email id, country of all listeners who love Jazz, Rock and Pop music.

select concat(c.firstname, ' ' ,c.lastname) as name , c.email, c.country
from customer c
join invoice i on c.customerid = i.customerid 
join invoiceline il on i.invoiceid = il.invoiceid
join track t on il.trackid = t.trackid
join genre g on t.genreid = g.genreid
where g.name in ('Jazz','Rock','Pop');


-- 3) Find the employee who has supported the most no of customers. Display the employee name and designation.

with emp as 
        ( select concat(e.firstname, ' ', e.lastname) name , e.title, count(*) no_of_cust_support,
			     rank() over(order by count(*) desc) as rnk
		  from employee e
          join customer c on c.supportrepid = e.employeeid 
          group by e.employeeid
		)
select name, title as designation, no_of_cust_support
from emp
where rnk = 1;
         

-- 4) Which city corresponds to the best customers with respect to total purchase.

with city as 
		( select c.city, sum(i.total) total_purchase,
                 rank() over( order by sum(i.total) desc) as rnk
          from invoice i 
          join customer c on c.customerid = i.customerid
          group by c.city
		) 
select city, total_purchase
from city
where rnk = 1;


-- 5) The highest number of invoices belongs to which country.

select country, no_of_invoice
from ( select billingcountry as country, count(1) as no_of_invoice,
			  rank() over(order by count(1) desc) as rnk
       from Invoice
       group by billingcountry) sq
where sq.rnk=1;


-- 6) Name the best customer who has done the highest purchase.

select name 
from (
		select c.customerid, concat(c.firstname,' ', c.lastname) as name, sum(i.total) total,
			   rank() over(order by sum(i.total) desc) as rk
		from customer c
		join invoice i on c.customerid = i.customerid
		group by c.customerid
	 ) sq
where rk=1;


-- 7) Find out top 3 city best for hosting the rock concert based on the rock-music listeners in each city.

with city as
		( select i.billingcity as city, count(*) as no_of_listener, rank() over(order by count(*) desc) rk
	      from invoice i 
		  join invoiceline il on i.invoiceid = il.invoiceid
		  join track t on il.trackid = t.trackid
		  join genre g on g.genreid = t.genreid
		  where g.name = 'Rock'
		  group by i.billingcity
		)
select city, no_of_listener 
from city
where rk <=3 ;
        
        
-- 8) Identify all the albums who have less then 5 track under them. Display the album name, artist name and the no of tracks in the respective album.

-- method 1:
with cte as
        (
		  select al.title, al.artistid, count(*) no_of_tracks
		  from album al
		  join track t on al.albumid = t.albumid
		  group by al.title, al.artistid
		  having count(*)<5
		) 
select cte.title as album_name, ar.name as artist_name, cte.no_of_tracks 
from artist ar
join cte on ar.artistid = cte.artistid 
order by no_of_tracks;

-- method 2: 
select al.title as album_name ,ar.name as artist_name, count(t.trackid) no_of_tracks 
from album al
join track t on al.albumid = t.albumid
join artist ar on al.artistid = ar.artistid
group by al.title, ar.name
having  count(t.trackid) < 5 
order by no_of_tracks;


-- 9) Display the track, album, artist and the genre for all tracks which are not purchased.

-- method 1:
select t.name as track_name, al.title as album_name, ar.name as artist_name, g.name as genre_name 
from track t
left join invoiceline il on t.trackid = il.trackid 
join album al on t.albumid = al.albumid
join artist ar on al.artistid = ar.artistid
join genre g on t.genreid = g.genreid
where il.invoicelineid is null;

-- method 2:
select t.name as track_name, al.title as album_name, ar.name as artist_name, g.name as genre_name
from track t
join album al on al.albumid=t.albumid
join artist ar on ar.artistid = al.artistid
join genre g on g.genreid = t.genreid
where not exists (select 1
                 from InvoiceLine il
                 where il.trackid = t.trackid);


-- 10) Find artist who have performed in multiple genres. Diplay the aritst name and the genre.

with all_artist as 
       (select ar.name as artist_name, g.name as genre		   
		from artist ar
		join album al on ar.artistid = al.artistid 
		join track t on t.albumid = al.albumid
		join genre g on t.genreid = g.genreid
		group by ar.name, g.name),
	artist_multiple as 
       (select artist_name, count(*) 
		from all_artist 
		group by artist_name
		having count(*) >1)
select a.*
from all_artist a
join artist_multiple am on a.artist_name = am.artist_name
order by 1;


-- 11) Which is the most popular and least popular genre.

with genre as 
         (
			select g.name, count(*) as no_of_purchased,
                   rank() over(order by count(*) desc) as rnk
			from invoiceline il
			join track t on il.trackid = t.trackid
			join genre g on t.genreid = g.genreid 
			group by g.name
		 ),
     genre1 as
		 (
          select max(rnk) as max_rank from genre 
         )  
select g.name,
       case when g.rnk = 1 then 'Most Popular' else 'Least Popular' end as Category 
from genre g 
cross join genre1 g1
where g.rnk = 1 or g.rnk= g1.max_rank;


-- 12) Identify the 5 most popular artist for the most popular genre.

with most_popular as 
                (
					select *
                    from ( select g.name, count(*), rank() over(order by count(*) desc) rn
                           from invoiceline il 
                           join track t on il.trackid = t.trackid
                           join genre g on t.genreid = g.genreid
                           group by g.name
                         ) sq
					where rn = 1
				),
		  artist as 
               (    
					select ar.name as artist_name, count(t.name) as no_of_songs,
						   rank() over(order by count(t.name) desc) rnk
					from artist ar
					join album al on ar.artistid = al.artistid
					join track t on al.albumid = t.albumid
					join genre g on t.genreid = g.genreid
					where g.name = (select name from most_popular)
					group by ar.name, g.name
			   )
select artist_name, no_of_songs 
from artist 
where rnk <= 5;


-- 13) Find the artist who has contributed with the maximum no of songs/tracks. Display the artist name and the no of songs.

with art as 
        ( select ar.name as artist_name, count(t.name) as no_of_songs,
                 rank() over(order by count(t.name) desc) as rnk
		  from artist ar
          join album al on ar.artistid = al.artistid 
          join track t on al.albumid = t.albumid
          group by ar.name 
		)
select artist_name, no_of_songs
from art
where rnk = 1;