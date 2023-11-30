-----Ш А Г  5---------------------------------------------------------------------------------------------------------------------------------------------------------------------	
DROP table if exists public.shipping_status;
CREATE TABLE public.shipping_status 
(
shipping_id int unique primary key,
status text,
state text,
shipping_start_fact_datetime timestamp,
shipping_end_fact_datetime timestamp
);
INSERT INTO public.shipping_status (shipping_id, status, state, shipping_start_fact_datetime, shipping_end_fact_datetime)


WITH  t_booked_time AS
  (SELECT shippingid,
          state,
          state_datetime AS shipping_start_fact_datetime
   FROM shipping s
   WHERE state = 'booked'),
t_max_order_time AS
  (SELECT shippingid, MAX(state_datetime) AS max_state_datetime
   FROM shipping
   GROUP BY shippingid
),
     t_recieved AS
  (SELECT shippingid,
          state,
          state_datetime AS shipping_end_fact_datetime
   FROM shipping s
   WHERE state = 'recieved')

   SELECT s.shippingid,
       s.status,
       s.state,
       b.shipping_start_fact_datetime,
       r.shipping_end_fact_datetime
FROM shipping s
LEFT JOIN t_booked_time b ON s.shippingid  = b.shippingid
LEFT JOIN t_max_order_time mot ON s.shippingid = mot.shippingid 
LEFT JOIN t_recieved r ON s.shippingid = r.shippingid
WHERE s.state_datetime = mot.max_state_datetime;
--select * from public.shipping_status
	
