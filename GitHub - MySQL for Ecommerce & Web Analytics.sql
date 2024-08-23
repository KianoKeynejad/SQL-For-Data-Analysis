select * from website_sessions ;
select * from orders ;

-- We use the utm parameters stored in the database to identify paid website sessions
-- From our session data, we can link to our order data to understand how much revenue our paid campaigns are driving
select 
	utm_source,
    count(distinct website_sessions.website_session_id ) as sessions,
    count(distinct orders.order_id) as orders
    from website_sessions
    left join orders
    on website_sessions.website_session_id = orders.website_session_id
    where website_sessions.website_session_id between 1000 and 2000
    group by 
		utm_source
        
;


-- where the bulk of the website sessions are coming from, through 2012-04-12?
-- breakdown by UTM source, campaign and referring domain. 
select 
	utm_source,
    utm_campaign,
    http_referer,
    count(website_session_id) as sessions
from website_sessions
where created_at < '2012-04-12'
group by 
	utm_source,
    utm_campaign,
    http_referer
order by 
	sessions Desc
    ;


-- calculate the conversion rate (CVR) from session to order? Based on what we're paying for clicks, we’ll need a CVR of at least 4% to make the numbers work.
-- If we're much lower, we’ll need to reduce bids. If we’re higher, we can increase bids to drive more volume.

select 
	count(Distinct website_sessions.website_session_id) as sessions,
	count( Distinct orders.order_id) as orders,
	(count( Distinct orders.order_id)/count(Distinct website_sessions.website_session_id))  as sessions_to_order_conv_rate

from website_sessions
left join orders
on website_sessions.website_session_id = orders.website_session_id
where website_sessions.created_at < '2012-04-14'
	And utm_source = 'gsearch'
    And utm_campaign = 'nonbrand'
;

select 
year(created_at) as created_yr,
week(created_at)  as created_wk,
count( Distinct website_session_id) as sessions
from 
	website_sessions
group by 
	created_yr,
	created_wk
;

-- Pivoting data with count and case
-- breaking down the count of order_id by primary_product_id (rows) and items_purchased (columns) 
-- to see how many orders were placed for each primary product and how many of those orders included multiple items.

select
	primary_product_id,
    order_id,
    items_purchased,
    created_at
from 
	orders

;

select 
	primary_product_id,
	count( case when items_purchased = 1 then order_id Else Null End ) as orders_w_1_item,
	count( case when items_purchased = 2 then order_id Else Null End ) as orders_w_2_item
from 
	orders
group by 1
;
-- Based on your conversion rate analysis, we bid down gsearch nonbrand on 2012-04-15.
-- pull gsearch nonbrand trended session volume, by week, to see if the bid changes have caused volume to drop at all?
-- how we can find week_start_date

select 
	yearweek(created_at) as year_week,
    Min(date(created_at)) as week_start_date,
    count( Distinct website_session_id) as sessions
from 
	website_sessions
where website_sessions.created_at < '2012-05-10'
	And utm_source = 'gsearch'
    And utm_campaign = 'nonbrand'
group by 
	year_week
	
;

-- conversion rates from session to order, by device type
-- When we bid higher, we’ll rank higher in the auctions
select 
	website_sessions.device_type,
	count(distinct website_sessions.website_session_id) as sessions,
    count(distinct orders.order_id) as orders,
    count(distinct orders.order_id)/count(distinct website_sessions.website_session_id) as session_to_order_conv_rate
from 
	website_sessions
    left join orders
    on website_sessions.website_session_id = orders.website_session_id
where 
	website_sessions.created_at < '2012-05-11'
	And utm_source = 'gsearch'
    And utm_campaign = 'nonbrand'
group by
	device_type
;

-- pull weekly trends for both desktop and mobile so we can see the impact on volume
select 
    -- yearweek(website_sessions.created_at),
    min(date(website_sessions.created_at))as week_start_date,
	count(Distinct case  when device_type = 'desktop' then website_sessions.website_session_id Else null End ) as dtop_sessions,
	count(Distinct case  when device_type = 'mobile' then website_sessions.website_session_id Else null End ) as mob_sessions
from 
	website_sessions
    left join orders
    on website_sessions.website_session_id = orders.website_session_id
where 
	website_sessions.created_at < '2012-06-09'
	And website_sessions.created_at >'2012-04-15'
	And utm_source = 'gsearch'
    And utm_campaign = 'nonbrand'
group by
     yearweek(website_sessions.created_at)
;

-- most-viewed website pages, ranked by session volume
select 
	pageview_url,
	count(distinct website_session_id) as views
from 
	website_pageviews
where 
	created_at < '2012-06-09'
group by pageview_url
order by 2 desc
;

-- pull all entry pages and rank them on entry volume

use mavenfuzzyfactory;
create temporary table first_pageviews
select 
	website_session_id,
	min(website_pageview_id) as min_pageview_id
from 
	website_pageviews
where
	created_at < '2012-06-12'
group by 
	website_session_id
; 

select 
	website_pageviews.pageview_url as landing_page,
    count(first_pageviews.website_session_id) as sessions_hitting_this_landing_page
    
from 
	first_pageviews
    left join website_pageviews
		on website_pageviews.website_pageview_id = first_pageviews.min_pageview_id
group by
	website_pageviews.pageview_url
;



-- all of the questions 

select * from website_sessions;
select * from website_pageviews;

-- example :
create temporary table first_pageview
select 
	website_session_id,
    min(website_pageview_id) as min_pv_id
from website_pageviews
where website_pageview_id < 1000 -- arbitrary
group by website_session_id
;

select 
    website_pageviews.pageview_url as landing_page, -- aka "entry page"
    count(distinct first_pageview.website_session_id) as sessions_hitting_this_lander
from first_pageview
	left join website_pageviews
		on first_pageview.min_pv_id = website_pageviews.website_pageview_id
group by website_pageviews.pageview_url
;


-- Finding Top Website Pages
select 
	pageview_url,
    count(distinct website_pageview_id) as pvs
from website_pageviews
where created_at < '2012-06-09'
group by
	pageview_url
order by 
	pvs desc
;

-- Finding Top Entry Pages

create temporary table first_pv_per_session
select 
	website_session_id,
    min(website_pageview_id) as first_pv
from website_pageviews
where created_at < '2012-06-12'
group by website_session_id
;

select 
	website_pageviews.pageview_url as landing_page_url,
    count(distinct first_pv_per_session.first_pv) as sessions_hitting_page
from first_pv_per_session
	left Join website_pageviews
		on first_pv_per_session.first_pv = website_pageviews.website_pageview_id
group by 
		website_pageviews.pageview_url
;
    
-- Building Conversion Funnels
-- step 1: select all pageviews for relevant sessions

select 
	website_sessions.website_session_id,
    website_pageviews.pageview_url,
    -- website_pageviews.created_at AS pageview_created_at,
    case when pageview_url = '/products' then 1 else 0 end as products_page,
    case when pageview_url = '/the-original-mr-fuzzy' then 1 else 0 end as mrfuzzy_page,
    case when pageview_url = '/cart' then 1 else 0 end as cart_page,
    case when pageview_url = '/shipping' then 1 else 0 end as shipping_page,
    case when pageview_url = '/billing' then 1 else 0 end as billing_page,
    case when pageview_url = '/thank-you-for-your-order' then 1 else 0 end as thankyou_page
from website_sessions
	left join website_pageviews
		on website_sessions.website_session_id = website_pageviews.website_pageview_id
where website_sessions.utm_source = 'gsearch'
	and website_sessions.utm_campaign = 'nonbrand'
    and website_sessions.created_at > '2012-08-05'
    and website_sessions.created_at < '2012-09-05'
order by 
	website_sessions.website_session_id,
    website_pageviews.created_at;

-- step 2: identify each pageview as the specific funnel step

# now we are going to wrap the above query to another query as subquery:

select 
	website_session_id,
    Max(products_page) as product_made_it,
    Max(mrfuzzy_page) as mrfuzzy_made_it,
    Max(cart_page) as cart_made_it,
    Max(shipping_page) as shipping_made_it,
    Max(billing_page) as billing_made_it,
    Max(thankyou_page) as thankyou_made_it
from(
select 
	website_sessions.website_session_id,
    website_pageviews.pageview_url,
    -- website_pageviews.created_at AS pageview_created_at,
    case when pageview_url = '/products' then 1 else 0 end as products_page,
    case when pageview_url = '/the-original-mr-fuzzy' then 1 else 0 end as mrfuzzy_page,
    case when pageview_url = '/cart' then 1 else 0 end as cart_page,
    case when pageview_url = '/shipping' then 1 else 0 end as shipping_page,
    case when pageview_url = '/billing' then 1 else 0 end as billing_page,
    case when pageview_url = '/thank-you-for-your-order' then 1 else 0 end as thankyou_page
from website_sessions
	left join website_pageviews
		on website_sessions.website_session_id = website_pageviews.website_pageview_id
where website_sessions.utm_source = 'gsearch'
	and website_sessions.utm_campaign = 'nonbrand'
    and website_sessions.created_at > '2012-08-05'
    and website_sessions.created_at < '2012-09-05'
order by 
	website_sessions.website_session_id,
    website_pageviews.created_at
) as page_view_level
group by
	website_session_id
;


-- step 3: create the session-level conversion funnel view

# next we run the same query we just create a temporary table

create temporary table session_level_made_it_flags
select 
	website_session_id,
    Max(products_page) as product_made_it,
    Max(mrfuzzy_page) as mrfuzzy_made_it,
    Max(cart_page) as cart_made_it,
    Max(shipping_page) as shipping_made_it,
    Max(billing_page) as billing_made_it,
    Max(thankyou_page) as thankyou_made_it
from(
select 
	website_sessions.website_session_id,
    website_pageviews.pageview_url,
    -- website_pageviews.created_at AS pageview_created_at,
    case when pageview_url = '/products' then 1 else 0 end as products_page,
    case when pageview_url = '/the-original-mr-fuzzy' then 1 else 0 end as mrfuzzy_page,
    case when pageview_url = '/cart' then 1 else 0 end as cart_page,
    case when pageview_url = '/shipping' then 1 else 0 end as shipping_page,
    case when pageview_url = '/billing' then 1 else 0 end as billing_page,
    case when pageview_url = '/thank-you-for-your-order' then 1 else 0 end as thankyou_page
from website_sessions
	left join website_pageviews
		on website_sessions.website_session_id = website_pageviews.website_pageview_id
where website_sessions.utm_source = 'gsearch'
	and website_sessions.utm_campaign = 'nonbrand'
    and website_sessions.created_at > '2012-08-05'
    and website_sessions.created_at < '2012-09-05'
order by 
	website_sessions.website_session_id,
    website_pageviews.created_at
) as page_view_level
group by
	website_session_id
;


-- step 4: aggregate the data to assess funnel performance 

# then this would produce the final output
 
select 
	count(Distinct website_session_id) as sessions, 
    count(distinct case when product_made_it = 1 then website_session_id else null end) as to_products,
	count(distinct case when mrfuzzy_made_it = 1 then website_session_id else null end) as to_mrfuzzy,
	count(distinct case when cart_made_it = 1 then website_session_id else null end) as to_cart,
	count(distinct case when shipping_made_it = 1 then website_session_id else null end) as to_shipping,
	count(distinct case when billing_made_it = 1 then website_session_id else null end) as to_billing,
	count(distinct case when thankyou_made_it = 1 then website_session_id else null end) as to_thankyou
from session_level_made_it_flags;


-- ASSIGNMENT: Analyzing Conversion Funnel Tests
-- first, finding the starting point to frame the analysis:

select
	min(website_pageviews.website_pageview_id) as first_pv_id
from website_pageviews
where pageview_url = '/billing-2';
-- first_pv_id = 53550
    
select
	website_pageviews.website_pageview_id,
    website_pageviews.pageview_url as billing_version_seen,
    orders.order_id
from 
	website_pageviews
		left join orders
			on orders.website_session_id = website_pageviews.website_session_id
where
	website_pageviews.website_pageview_id >= 53550 -- first pageview_id where test was live
    and website_pageviews.created_at < '2012-11-10' -- time of assgnment
    and website_pageviews.pageview_url in ('/billing','/billing-2');
    
 -- same as above, just wrapping as a subquery and summarising
 -- final analysis output
 
select 
	billing_version_seen,
    count(distinct website_session_id) as sessions,
    count(distinct order_id) as orders,
    count(distinct order_id)/count(distinct website_session_id) as billing_to_order_rt
from (
select
	website_pageviews.website_session_id,
    website_pageviews.pageview_url as billing_version_seen,
    orders.order_id
from 
	website_pageviews
		left join orders
			on orders.website_session_id = website_pageviews.website_session_id
where
	website_pageviews.website_pageview_id >= 53550 -- first pageview_id where test was live
    and website_pageviews.created_at < '2012-11-10' -- time of assgnment
    and website_pageviews.pageview_url in ('/billing','/billing-2')
) as billing_sessions_w_orders
group by
	billing_version_seen
    
    
    
    
   
    
    
    
    
    
    
    
    
    
    







   
   

























