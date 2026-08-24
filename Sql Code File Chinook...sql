use chinook;

-- Does any table have missing values or duplicates? If yes, how would you handle it?

-- Verifying the employee table for the presence of NULL values.
select * from employee
where employee_id is NULL 
or last_name is NULL
or first_name is NULL
or title is NULL
or reports_to is NULL
or birthdate is NULL
or hire_date is NULL
or address is NULL
or city is NULL
or state is NULL
or country is NULL
or postal_code is NULL
or phone is NULL
or fax is NULL
or email is NULL

-- Managing NULL values
select 
employee_id,
    last_name,
    first_name,
    title,
    coalesce(reports_to,'NA') as reports_to,
    birthdate,
    hire_date,
    address,
    city,
    state,
    country,
    postal_code,
    phone,fax,
    email
from employee;

-- checking track etables containing NULL values 
select * 
from track 
where name is null or 
album_id is null or 
media_type_id is null or 
genre_id is null or 
composer is null or 
milliseconds is null or 
bytes is null or 
unit_price is null;

-- Managing NULL values
select 
    track_id, 
    name, 
    album_id, 
    media_type_id, 
    genre_id, 
    coalesce(composer, 'NA') as composer, 
    milliseconds, 
    bytes, 
    unit_price 
from track;

-- Inspecting the customer table
select * from customer
where customer_id is NULL 
or first_name is NULL
or last_name is NULL
or company is NULL
or address is NULL
or city is NULL
or state is NULL
or country is NULL
or postal_code is NULL
or phone is NULL
or fax is NULL
or email is NULL 
or support_rep_id is NULL

-- Managing NULL values
select
    customer_id,
    first_name,
    last_name,
    coalesce (company, 'NA') AS company,
    address,
    city,
    coalesce(state, 'NA') AS state,
    country,
    coalesce(postal_code, 'NA') as postal_code,
    coalesce (phone, 'NA') as phone,
    coalesce (fax, 'NA') AS fax,
    email,
    support_rep_id
from customer;

-- Find the top-selling tracks and top artist in the USA and identify their most famous genres.

-- The highest-selling track in the USA
select 
    t.track_id,
    t.name as track_name, 
    sum(il.quantity) as Top_Selling_quantity
    from track as t 
join invoice_line as il on t.track_id= il.track_id 
join invoice i on il.invoice_id= i.invoice_id 
join customer c on i.customer_id = c.customer_id 
where c.country = 'USA' 
group by t.name,t.track_id 
order by Top_Selling_quantity desc 
limit 10;

-- Top artist in USA
select 
ar.artist_id, 
ar.name as artist_name,
sum(il.quantity) as total_quantity_sold 
from track as t 
join album al on t.album_id = al.album_id 
join artist ar on al.artist_id = ar.artist_id
join invoice_line il on t.track_id = il.track_id
join invoice i on il.invoice_id = i.invoice_id
join customer c on i.customer_id = c.customer_id
where c.country = 'USA' 
group by ar.artist_id,artist_name 
order by total_quantity_sold desc 
limit 1; 

-- Famous genre of top artist
with top_artist as (
    select ar.artist_id
    from track t
    join album al on t.album_id = al.album_id
    join artist ar on al.artist_id = ar.artist_id
    join invoice_line il on t.track_id = il.track_id
    join invoice i on il.invoice_id = i.invoice_id
    join customer c on i.customer_id = c.customer_id
    where c.country = 'USA'
    group by ar.artist_id
    order by sum(il.quantity) desc
    limit 1
),

genre_sales as (
    select 
        g.genre_id,
        g.name as genre,
        sum(il.quantity) as total_quantity_sold
    from track t
    join genre g on t.genre_id = g.genre_id
    join invoice_line il on t.track_id = il.track_id
    join invoice i on il.invoice_id = i.invoice_id
    join customer c on i.customer_id = c.customer_id
    join album al on t.album_id = al.album_id
    join artist ar on al.artist_id = ar.artist_id
    where c.country = 'USA'
      and ar.artist_id = (select artist_id from top_artist)
    group by g.genre_id, g.name
)

select * 
from genre_sales 
order by total_quantity_sold desc 
limit 10;

-- What is the customer demographic breakdown (age, gender, location) of Chinook's customer base?
select 
	country, coalesce(state,'NA') as state, city, count(customer_id) as customer_count
    from customer 
group by country, state, city
order by country, state, city;

-- Calculate the total revenue and number of invoices for each country, state, and city?
select
	c.country,
    coalesce(c.state,'NA') as state,
    c.city,
    sum(i.total) as total_revenue,
    count(i.invoice_id) as number_of_invoice
from customer as c
join invoice i on c.customer_id = i.customer_id
group by c.country,state,c.city
order by total_revenue desc;

-- Find the top 5 customers by total revenue in each country
with customer_revenue_by_country as (
	select
		c.customer_id,
        concat(c.first_name, ' ', c.last_name) as customer_name,
		c.country,
        sum(i.total) as total_revenue
	from customer as c
	join invoice as i on c.customer_id = i.customer_id
	group by c.country, c.customer_id, customer_name
),
top_5_customers_per_country as (
	select 
		customer_id,
		customer_name,
		country,
		total_revenue,
		rank() over(partition by country order by total_revenue desc) as ranking
	from customer_revenue_by_country
)
select 
	customer_id,
	customer_name,
	country,
	total_revenue
from top_5_customers_per_country
where ranking <= 5
order by country, ranking;

-- Identify the top-selling track for each customer
with customer_total_tracks as (
	select 
		c.customer_id,
		concat(c.first_name, ' ', c.last_name) as customer_name,
		sum(il.quantity) as total_quantity
	from customer as c 
	join invoice i on c.customer_id = i.customer_id
	join invoice_line il on i.invoice_id = il.invoice_id
	group by c.customer_id, customer_name
),
customer_top_track as (
	select 
		ctt.customer_id,
		ctt.customer_name,
		ctt.total_quantity,
		row_number() over(partition by ctt.customer_id order by ctt.total_quantity desc) as top_rank,
		t.track_id,
		t.name as track_name
	from customer_total_tracks ctt
	join invoice i on ctt.customer_id = i.customer_id
	join invoice_line il on i.invoice_id = il.invoice_id
	join track t on il.track_id = t.track_id
)
select
	customer_id,
	customer_name,
	track_name,
	total_quantity
from customer_top_track
where top_rank = 1
order by customer_id;

-- Are there any patterns or trends in customer purchasing behavior (e.g., frequency of purchases, preferred payment methods, average order value)?
select 
	c.customer_id,
    concat(c.first_name,' ',c.last_name) as customer_name,
    year(i.invoice_date) as year,
    count(i.invoice_id) as purchase_count
from customer c 
join invoice i on c.customer_id = i.customer_id
group by c.customer_id,customer_name,year
order by c.customer_id,year desc;

-- Average order value of each customer 
select
	c.customer_id,
    concat(c.first_name,' ',c.last_name) as customer_name,
    round(avg(i.total),2) average_order_value
from customer c 
join invoice i on c.customer_id = i.customer_id
group by c.customer_id
order by average_order_value desc;

-- The total revenue produced by each customer
select 
	c.customer_id,
    concat(c.first_name,' ',c.last_name) as customer_name,
    sum(i.total) as total_revenue
from customer c
join invoice i on c.customer_id = i.customer_id
group by c.customer_id,customer_name
order by total_revenue desc; 

-- What is the customer churn rate?
WITH yc AS (
    SELECT DISTINCT
        customer_id,
        YEAR(invoice_date) AS yr
    FROM invoice
)

SELECT
    a.yr + 1 AS churn_year,
    ROUND(
        100 * (COUNT(a.customer_id) - COUNT(b.customer_id))
        / COUNT(a.customer_id),
        2
    ) AS churn_rate
FROM yc a
LEFT JOIN yc b
    ON a.customer_id = b.customer_id
    AND b.yr = a.yr + 1
GROUP BY a.yr
ORDER BY churn_year;
    
-- Calculate the percentage of total sales contributed by each genre in the USA and identify the best-selling genres and artists.
with genre_sales_by_country as (
	select
		sum(il.quantity*t.unit_price) as sales,
        g.name as genre_name
	from invoice_line as il
    join track as t on il.track_id = t.track_id
    join genre as g on t.genre_id = g.genre_id
    join invoice as i on il.invoice_id = i.invoice_id
    join customer as c on i.customer_id = c.customer_id
    where c.country = 'USA'
    group by genre_name
    order by sales desc
    ),
total_sales_by_genre as (
	select 
		sum(sales) as total_sales
	from genre_sales_by_country
    )
select 
	genre_name,
    sales,
    round(sales/(select * from total_sales_by_genre)*100,2) as genre_percentage
from genre_sales_by_country ;

-- The top-selling genres and artists in the market
with genre_artist_sales as (
	select
		sum(il.quantity*t.unit_price) as sales,
        g.name as genre_name,
        a.name as artist_name
	from invoice_line as il
    join track as t on il.track_id = t.track_id
    join genre as g on t.genre_id = g.genre_id
    join invoice as i on il.invoice_id = i.invoice_id
    join customer as c on i.customer_id = c.customer_id
    join album as al on t.album_id = al.album_id
    join artist as a on al.artist_id = a.artist_id
    where c.country = 'USA'
    group by genre_name,artist_name
    order by sales desc
)
    
select 
    genre_name,
    artist_name,
    sales,
    dense_rank() over(partition by genre_name order by sales desc) as artist_rank
from genre_artist_sales;

-- Find customers who have purchased tracks from at least 3 different genres
select c.customer_id, first_name, last_name,count(distinct t.genre_id) as genre_count
from customer as c
join invoice i on c.customer_id = i.customer_id
join invoice_line il on i.invoice_id = il.invoice_id
join track as t on il.track_id = t.track_id
group by c.customer_id,first_name, last_name
having count(distinct t.genre_id) >=3
order by genre_count desc;

-- Rank genres based on their sales performance in the USA
select
    g.name as genre,
    sum(il.unit_price * il.quantity) as total_sales,
    dense_rank() over (order by sum(il.unit_price * il.quantity) desc) as sales_rank
from invoice i
join invoice_line il on i.invoice_id = il.invoice_id
join track t on il.track_id = t.track_id
join genre g on t.genre_id = g.genre_id
where i.billing_country = 'USA'
group by g.name;

-- Identify customers who have not completed a purchase in the past three months.
select distinct(c.customer_id), first_name, last_name from customer c
join invoice i on i.customer_id = c.customer_id 
where i.invoice_date <= curdate() - interval 3 month
order by c.customer_id ;

-- Recommend the three albums from the new record label that should be prioritised for advertising and promotion in the USA based on genre sales analysis.
select
	g.name as genre_name,
	al.title as album_title,
	sum(il.quantity * tr.unit_price) as total_sales,
	dense_rank() over (order by sum(il.quantity * tr.unit_price) desc) as sales_rank
from track tr
join album al on tr.album_id = al.album_id
join invoice_line il on tr.track_id = il.track_id
join invoice inv on il.invoice_id = inv.invoice_id
join customer cust on inv.customer_id = cust.customer_id
join genre g on tr.genre_id = g.genre_id
where cust.country = 'USA'
group by genre_name, album_title
order by sales_rank
limit 3;

-- Determine the top-selling genres in countries other than the USA and identify any commonalities or differences.
select
    g.name as genre_name,
    sum(il.quantity) as total_Quantity
from track t
join invoice_line il on t.track_id = il.track_id
join invoice i on il.invoice_id = i.invoice_id
join customer c on i.customer_id = c.customer_id
join genre g on t.genre_id = g.genre_id
where c.country <> "USA"
group by genre_name
order by total_Quantity desc;

with usa_sales as (
	select
		g.genre_id,
		g.name as genre_name,
		sum(il.quantity) as total_quantity_sold
	from track t
	join invoice_line il on t.track_id = il.track_id
	join invoice i on il.invoice_id = i.invoice_id
	join customer c on i.customer_id = c.customer_id
	join genre g on t.genre_id = g.genre_id
	where c.country = 'USA'
	group by g.genre_id, genre_name
),
non_usa_sales as (
	select
		g.genre_id,
		g.name as genre_name,
		sum(il.quantity) as total_quantity_sold
	from track t
	join invoice_line il on t.track_id = il.track_id
	join invoice i on il.invoice_id = i.invoice_id
	join customer c on i.customer_id = c.customer_id
	join genre g on t.genre_id = g.genre_id
	where c.country <> 'USA'
	group by g.genre_id, genre_name
)
select 
	u.genre_id,
	u.genre_name as name,
	sum(u.total_quantity_sold + n.total_quantity_sold) over(partition by u.genre_id) as genre_total,
	round(u.total_quantity_sold * 100.0 / 
		  sum(u.total_quantity_sold + n.total_quantity_sold) over(partition by u.genre_id), 2) as usa_percentage,
	round(n.total_quantity_sold * 100.0 / 
		  sum(u.total_quantity_sold + n.total_quantity_sold) over(partition by u.genre_id), 2) as non_usa_percentage
from usa_sales u
join non_usa_sales n on u.genre_id = n.genre_id
order by genre_total desc; 

-- Customer Purchasing Behavior Analysis: How do the purchasing habits (frequency, basket size, spending amount) of long-term customers differ from those of new customers? What insights can these patterns provide about customer loyalty and retention strategies?
with purchase_statistics as (
    select 
        c.customer_id,
        count(il.invoice_id) as purchase_count,
        sum(il.quantity) as total_items_bought,
        sum(i.total) as total_spent,
        avg(i.total) as avg_spent_per_order,
        datediff(max(i.invoice_date), min(i.invoice_date)) as customer_lifetime_days
    from customer c
    join invoice i on c.customer_id = i.customer_id
    join invoice_line il on i.invoice_id = il.invoice_id
    group by c.customer_id
),
customer_segmentation as (
    select
        customer_id,
        purchase_count,
        total_items_bought,
        total_spent,
        avg_spent_per_order,
        customer_lifetime_days,
        case
            when customer_lifetime_days < 365 then 'recent' 
            else 'long-term' 
        end as customer_category
    from purchase_statistics
)
select
    customer_category,
    round(avg(purchase_count), 2) as average_purchase_frequency,
    round(avg(total_items_bought), 2) as average_basket_size,
    round(avg(total_spent), 2) as average_spending,
    round(avg(avg_spent_per_order), 2) as average_order_value
from customer_segmentation
group by customer_category;

-- Product Affinity Analysis: Which music genres, artists, or albums are frequently purchased together by customers? How can this information guide product recommendations and cross-selling initiatives
-- Analysis of Track Combinations
with track_pair_combination as (
    select
        il1.track_id as track1,
        il2.track_id as track2,
        count(*) as time_purchased_together
    from invoice_line il1
    join invoice_line il2 on il1.invoice_id = il2.invoice_id and il1.track_id < il2.track_id
    group by track1, track2
),
genre_pair_combination as (
    select 
        t1.genre_id as genre_id_1,
        t2.genre_id as genre_id_2,
        count(*) as times_purchased_together
    from track_pair_combination tc 
    join track t1 on tc.track1 = t1.track_id
    join track t2 on tc.track2 = t2.track_id
    where t1.genre_id <> t2.genre_id
    group by t1.genre_id, t2.genre_id
)
select
    g1.name as genre_1,
    g2.name as genre_2,
    gc.times_purchased_together
from genre_pair_combination gc
join genre g1 on gc.genre_id_1 = g1.genre_id
join genre g2 on gc.genre_id_2 = g2.genre_id
order by gc.times_purchased_together desc;

with track_combination as(
	select
		il1.track_id as track1,
        il2.track_id as track2,
        count(*) time_purchased_together
	from invoice_line il1
    join invoice_line il2 on il1.invoice_id = il2.invoice_id 
    and il1.track_id < il2.track_id
    group by track1,track2
),
artist_combination as (
	select
		a1.artist_id as artist1,
        a2.artist_id as artist2,
        count(*) as time_purchased_together
	from track_combination tc
    join track t1 on tc.track1 = t1.track_id
    join album al1 on t1.album_id = al1.album_id
    join artist a1 on al1.artist_id = a1.artist_id
    join track t2 on tc.track2 = t2.track_id
    join album al2 on t2.album_id = al2.album_id
    join artist a2 on al2.artist_id = a2.artist_id
    where a1.artist_id <> a2.artist_id
    group by a1.artist_id,a2.artist_id
)
select 
	a1.name as artist_name,
    a2.name as artist_name,
    ac.time_purchased_together
from artist_combination ac
join artist a1 on ac.artist1 = a1.artist_id
join artist a2 on ac.artist2 = a2.artist_id
order by ac.time_purchased_together desc;

with track_combination as(
	select
		il1.track_id as track1,
        il2.track_id as track2,
        count(*) time_purchased_together
	from invoice_line il1
    join invoice_line il2 on il1.invoice_id = il2.invoice_id 
    and il1.track_id < il2.track_id
    group by track1,track2
),
album_combination as (
	select
		al1.album_id as album_1,
        al2.album_id as album_2,
        count(*) as time_purchased_together
    from track_combination tc
    join track t1 on tc.track1 = t1.track_id
    join album al1 on t1.album_id = al1.album_id
    join track t2 on tc.track2 = t2.track_id
    join album al2 on t2.album_id = al2.album_id
    where al1.album_id <> al2.album_id
    group by al1.album_id,al2.album_id
)

select
	al1.title as album_name,
    al2.title as album_name,
    ac.time_purchased_together
from album_combination ac
join album al1 on ac.album_1 = al1.album_id
join album al2 on ac.album_2 = al2.album_id
order by ac.time_purchased_together desc;

-- Regional Market Analysis: Do customer purchasing behaviors and churn rates vary across different geographic regions or store locations? How might these correlate with local demographic or economic factors
-- Regional Purchase Behavior Analysis
with customer_purchase_summary as (
    select
        c.customer_id,
        count(i.invoice_id) as total_purchase_frequency,
        sum(i.total) as total_spending,
        avg(i.total) as avg_order_value
    from invoice i 
    join customer c on i.customer_id = c.customer_id
    group by c.customer_id
),
customer_location_summary as (
    select
        c.customer_id,
        c.country,
        coalesce(c.state, 'Not Available') as state,
        c.city,
        cps.total_purchase_frequency,
        cps.total_spending,
        cps.avg_order_value
    from customer c 
    join customer_purchase_summary cps on c.customer_id = cps.customer_id
)
select
    country,
    state,
    city,
    round(count(distinct customer_id), 2) as total_customers,
    round(sum(total_purchase_frequency), 2) as total_purchases,
    round(sum(total_spending), 2) as total_spending,
    round(avg(avg_order_value), 2) as avg_order_value,
    round(avg(total_spending), 2) as avg_spending_per_customer
from customer_location_summary
group by country, state, city
order by total_spending desc;

-- Analysis of Regional Churn Rates
with latest_purchase_by_region as (
    select 
        c.customer_id,
        c.country,
        coalesce(c.state, 'NA') as state,
        c.city,
        max(i.invoice_date) as latest_purchase_date
    from customer c 
    join invoice i on c.customer_id = i.customer_id
    group by c.customer_id, c.country, state, c.city
),
churned_customers_by_region as (
    select
        country,
        state,
        city,
        count(customer_id) as churned_customers
    from latest_purchase_by_region        
    where latest_purchase_date < date_sub(curdate(), interval 1 year)
    group by country, state, city
)
select
    cc.country,
    cc.state,
    cc.city,
    cc.churned_customers,
    count(c.customer_id) as total_customers,
    round(cc.churned_customers / count(c.customer_id) * 100, 2) as churn_rate
from churned_customers_by_region cc
join customer c on cc.country = c.country and cc.state = c.state and cc.city = c.city
group by cc.country, cc.state, cc.city
order by churn_rate desc;

-- Customer Risk Profiling: Based on customer profiles (age, gender, location, purchase history), which customer segments are more likely to churn or pose a higher risk of reduced spending? What factors contribute to this risk
with Details_customer as (
	select
		c.customer_id,
        concat(c.first_name,' ',c.last_name) as customer_name,
        c.country,
        coalesce(c.state,"NA") as state,
        c.city,
        max(i.invoice_date) as last_purchase_date,
        count(i.invoice_id) as purchase_frequency,
        sum(i.total) as total_spending,
        avg(i.total) as avg_order_value,
        case 
			when max(i.invoice_date) < date_sub(curdate(),interval 1 year) then 'High Risk'
			when sum(i.total) < 100 then 'Medium Risk'
            Else 'Low Risk'
		end as risk_profile
    from customer c 
    join invoice i on c.customer_id = i.customer_id
    group by c.customer_id,customer_name,c.country,state,c.city
	order by total_spending desc
),
Details_risk as (
	select
		country,state,city,risk_profile,
        count(customer_id) as num_customer,
        round(avg(total_spending),2) as avg_total_spending,
        round(avg(purchase_frequency),2) as avg_purchase_frequency,
        round(avg(avg_order_value),2) as avg_order_value
	from Details_customer
    group by country,state,city,risk_profile
)
select * 
from Details_risk
order by risk_profile,avg_total_spending desc;

-- Customer Lifetime Value Modeling: How can you leverage customer data (tenure, purchase history, engagement) to predict the lifetime value of different customer segments? This could inform targeted marketing and loyalty program strategies. Can you observe any common characteristics or purchase patterns among customers who have stopped purchasing
with customer_profile as (
 select
 c.customer_id,
 concat(c.first_name,' ',c.last_name) as customer_name,
 c.country,
 coalesce(c.state,'Not Available') as state,
 c.city,
 min(i.invoice_date) as first_purchase_date,
 max(i.invoice_date) as last_purchase_date,
 datediff(max(i.invoice_date),min(i.invoice_date)) as customer_tenure_days,
 count(i.invoice_id) as total_purchase,
 sum(i.total) as total_spending,
 avg(i.total) as avg_order_value,
 case
   when max(i.invoice_date) < date_sub(curdate(), interval 1 year) then 'Churn'
   else 'Active'
 end as status,
 case
   when datediff(max(i.invoice_date),min(i.invoice_date)) >= 365 then 'Long term'
   else 'Short term'
 end as customer_segment,
 sum(i.total)/greatest(datediff(max(i.invoice_date),min(i.invoice_date)),1) * 365 as predicted_annual_value,
 sum(i.total) as lifetime_valid
 from customer c
 join invoice i on c.customer_id = i.customer_id
 group by c.customer_id
),
segment_summary as (
 select
 customer_segment,
 status,
 count(customer_id) as num_customer,
 avg(customer_tenure_days) as avg_tenure_days,
 avg(total_spending) as avg_lifetime_value,
 avg(predicted_annual_value) as avg_predicted_annual_segment
 from customer_profile
 group by customer_segment, status
),
churn_summary as (
 select
 country,
 state,
 city,
 customer_segment,
 count(customer_id) as churned_customer,
 avg(total_spending) as avg_lifetime_value
 from customer_profile
 where status = 'Churn'
 group by country, state, city, customer_segment
)

-- To get customer lifestyle analysis
select * from customer_profile;

-- To get customer segment analysis
select * from segment_summary;

-- To get customer churn analysis
select * from churn_summary;

-- How can you alter the "Albums" table to add a new column named "ReleaseYear" of type INTEGER to store the release year of each album?

ALTER TABLE album
ADD COLUMN releaseyear INT;

-- Set release year to 2017 for album IDs 1 to 5
UPDATE album
SET releaseyear = 2017
WHERE album_id IN (1, 2, 3, 4, 5);

-- Set release year to 2018 for album IDs 6 to 10
UPDATE album
SET releaseyear = 2018
WHERE album_id IN (6, 7, 8, 9, 10);

select * from album;

-- Chinook is interested in understanding the purchasing behavior of customers based on their geographical location. They want to know the average total amount spent by customers from each country, along with the number of customers and the average number of tracks purchased per customer. Write an SQL query to provide this information.
with total_tracks_by_customer as (
    select 
        i.customer_id,
        sum(il.quantity) as total_tracks
    from invoice i
    join invoice_line il on i.invoice_id = il.invoice_id
    group by i.customer_id
),
customer_purchase_summary as (
    select 
        c.country,
        c.customer_id,
        sum(i.total) as total_spent,
        ttc.total_tracks
    from customer c
    join invoice i on c.customer_id = i.customer_id
    join total_tracks_by_customer ttc on c.customer_id = ttc.customer_id
    group by c.country, c.customer_id, ttc.total_tracks
)
select 
    cps.country,
    count(distinct cps.customer_id) as number_of_customers,
    round(avg(cps.total_spent), 2) as average_amount_spent_per_customer,
    round(avg(cps.total_tracks), 2) as average_tracks_purchased_per_customer
from customer_purchase_summary cps
group by cps.country
order by average_amount_spent_per_customer desc;