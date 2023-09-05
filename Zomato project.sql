create schema Fassos;
use Fassos;
drop table if exists driver;
CREATE TABLE driver(driver_id integer,reg_date date); 

INSERT INTO driver(driver_id,reg_date) 
VALUES (1,'2021-01-01'),
(2,'2021-01-03'),
(3,'2021-01-08'),
(4,'2021-01-15');


drop table if exists ingredients;
CREATE TABLE ingredients(ingredients_id integer,ingredients_name varchar(60)); 

INSERT INTO ingredients(ingredients_id ,ingredients_name) 
 VALUES (1,'BBQ Chicken'),
(2,'Chilli Sauce'),
(3,'Chicken'),
(4,'Cheese'),
(5,'Kebab'),
(6,'Mushrooms'),
(7,'Onions'),
(8,'Egg'),
(9,'Peppers'),
(10,'schezwan sauce'),
(11,'Tomatoes'),
(12,'Tomato Sauce');

drop table if exists rolls;
CREATE TABLE rolls(roll_id integer,roll_name varchar(30)); 

INSERT INTO rolls(roll_id ,roll_name) 
 VALUES (1	,'Non Veg Roll'),
(2	,'Veg Roll');

drop table if exists rolls_recipes;
CREATE TABLE rolls_recipes(roll_id integer,ingredients varchar(24)); 

INSERT INTO rolls_recipes(roll_id ,ingredients) 
 VALUES (1,'1,2,3,4,5,6,8,10'),
(2,'4,6,7,9,11,12');

drop table if exists driver_order;
CREATE TABLE driver_order(order_id integer,driver_id integer,pickup_time datetime,distance VARCHAR(7),duration VARCHAR(10),cancellation VARCHAR(23));
INSERT INTO driver_order(order_id,driver_id,pickup_time,distance,duration,cancellation) 
 VALUES(1,1,'2021-01-01 18:15:34','20km','32 minutes',''),
(2,1,'2021-01-01 19:10:54','20km','27 minutes',''),
(3,1,'2021-01-03 00:12:37','13.4km','20 mins','NaN'),
(4,2,'2021-01-04 13:53:03','23.4','40','NaN'),
(5,3,'2021-01-08 21:10:57','10','15','NaN'),
(6,3,null,null,null,'Cancellation'),
(7,2,'2021-01-08 21:30:45','25km','25mins',null),
(8,2,'2021-01-10 00:15:02','23.4 km','15 minute',null),
(9,2,null,null,null,'Customer Cancellation'),
(10,1,'2021-01-11 18:50:20','10km','10minutes',null);


drop table if exists customer_orders;
CREATE TABLE customer_orders(order_id integer,customer_id integer,roll_id integer,not_include_items VARCHAR(4),extra_items_included VARCHAR(4),order_date datetime);
INSERT INTO customer_orders(order_id,customer_id,roll_id,not_include_items,extra_items_included,order_date)
values (1,101,1,'','','2021-01-01  18:05:02'),
(2,101,1,'','','2021-01-01 19:00:52'),
(3,102,1,'','','2021-01-02 23:51:23'),
(3,102,2,'','NaN','2021-01-02 23:51:23'),
(4,103,1,'4','','2021-01-04 13:23:46'),
(4,103,1,'4','','2021-01-04 13:23:46'),
(4,103,2,'4','','2021-01-04 13:23:46'),
(5,104,1,null,'1','2021-01-08 21:00:29'),
(6,101,2,null,null,'2021-01-08 21:03:13'),
(7,105,2,null,'1','2021-01-08 21:20:29'),
(8,102,1,null,null,'2021-01-09 23:54:33'),
(9,103,1,'4','1,5','2021-01-10 11:22:59'),
(10,104,1,null,null,'2021-01-11 18:34:49'),
(10,104,1,'2,6','1,4','2021-01-11 18:34:49');

select * from customer_orders;
select * from driver_order;
select * from ingredients;
select * from driver;
select * from rolls;
select * from rolls_recipes;

-- A. Roll Metrics
-- B. Driver and Customer Experience
-- C. Ingredient Optimisation
-- D.Pricing and Ratings

-- A. Roll Metrics
-- 1.How many rolls were added?
select count(roll_id) from customer_orders;

-- 2. How many unique customer orders were made?
select count(distinct customer_id) from customer_orders;

-- 3. How many sucessful orders were delivered by each driver?
select driver_id,count(distinct order_id) as successfulorders from driver_order 
where pickup_time not like "null"
group by driver_id;

-- 4. How many of each type of roll was ordered?
select roll_id,count(roll_id) from
customer_orders where order_id in(
select order_id from
(select * ,case when cancellation in('cancellation','customer cancellation') then 'c' else 'nc' end as 
order_cancel_details from driver_order)a
where order_cancel_details = 'nc')
group by roll_id;

-- 5.How many veg and non-veg rolls ordered by customers.
select a.*,b.roll_name from
(
select customer_id, roll_id, count(roll_id) from customer_orders
group by customer_id,roll_id)a inner join rolls b on a.roll_id = b.roll_id; 

-- 6.what was the maximum number of rolls delivered in single order?
select order_id , count(roll_id) as total from customer_orders
group by order_id
order by total desc
limit 3;

-- 7.For each customer ,how many delivered rolls had atleast 1 change and how many had no changes?
with temp_customer_orders(order_id,customer_id,roll_id,not_include_items,extra_items_included,order_date)as
(
select order_id,customer_id,roll_id,
case when not_include_items is null or not_include_items = ' ' then '0' else not_include_items end as new_not_include_items,
case when extra_items_included is null or extra_items_included = ' ' or extra_items_included='NaN' or extra_items_included = 'NULL' then '0' else extra_items_included end as new_extra_items_included, order_date from customer_orders
)
,
 temp_driver_order(order_id,driver_id,pickup_time,distance,duration,new_cancellation)as
(
select order_id,driver_id,pickup_time,distance,duration,
case when cancellation in('cancellation','customer cancellation')then 0 else 1 end as new_cancellation
from driver_order
)

select *,case when not_include_items ='0' and extra_items_included ='0' then 'no change' else 'change' end chg_no_chg
from temp_customer_orders where order_id in (
select order_id from temp_driver_order where new_cancellation!=0);

-- 8.What was the total number of rolls ordered for each hour of the day?
select
bucket,count(roll_id) from 
(select *,
concat(datepart(hour,order_date),'-',datepart(hour,order_date)+1) as bucket from customer_orders)a
group by bucket;

-- 9. What was the number of orders for each day of the week?
select dow,count(distinct order_id) from
(select *,datetime(dw,order_date) dow from customer_orders)a
group by dow;

-- 10. What was the average time in minutes it took for each driver to arrive at the fassos HQ to picup the order?
select driver_id,sum(diff),count(order_id) from 
(select * from
(select *,row_number() over(partition by order_id order by diff ) rnk from
(select a.order_id,a.customer_id,a.roll_id,a.not_include_items,a.extra_items_included,a.order_date,
b.driver_id,b.pick_up_time,b.distance,b.duration,b.cancellation,datediff(minute,a.order_date,b.pickup_time)diff
from customer_orders a inner join driver_order b on a.order_id=b.order_id
where b.pickup_time is not null)a) b where rnk=1)c
group by driver_id;

-- 11.Is there any relationship between the number of rollsand how long the order takes to prepare?
Select order_id, count(roll_id) as cnt , sum(DIFF)/count(roll_id) as Tym_Diff_per_order from
(Select * ,datediff(minute,a.order_date,b.pickup_time) DIFF
from customer_orders a join driver_order b
on a.order_id=b.order_id 
where b.pickup_time IS NOT NULL) as c 
group by order_id;

