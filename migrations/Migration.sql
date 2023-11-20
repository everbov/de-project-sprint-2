-----Ш А Г  1------------------------------------------------------------------------------------------------------------------
-- DROP TABLE if exists  public.shipping_country_rates;
CREATE TABLE public.shipping_country_rates 
(
id serial4 NOT null primary key,
shipping_country text NULL,
shipping_country_base_rate numeric(14, 3) NULL);

CREATE SEQUENCE shipping_country_rates_id_seq start 1;
INSERT INTO public.shipping_country_rates
(id, shipping_country, shipping_country_base_rate)
select  
nextval('shipping_country_rates_id_seq') as id,
		shipping_country,
		shipping_country_base_rate
			from (select distinct shipping_country,shipping_country_base_rate from public.shipping) as shipping_information;
drop sequence  shipping_country_rates_id_seq cascade;
--select * from public.shipping_country_rates 

-----Ш А Г  2------------------------------------------------------------------------------------------------------------------
--DROP table if exists public.shipping_agreement;
CREATE TABLE public.shipping_agreement 
(
agreement_id int primary key,
agreement_number text NULL,
agreement_rate numeric(3,2) NULL,
agreement_commission numeric(3,2) null
);

insert into public.shipping_agreement
(agreement_id,agreement_number,agreement_rate,agreement_commission)
SELECT DISTINCT vendor_agreement[1]::int AS agreement_id ,
			    vendor_agreement[2] AS agreement_number,
 			    vendor_agreement[3]::numeric(3, 2) AS agreement_rate,
   			    vendor_agreement[4]::numeric(3, 2) AS agreement_commission
FROM (
      SELECT (regexp_split_to_array(vendor_agreement_description , E'\\:+')) AS vendor_agreement
      FROM public.shipping s) AS v;
--select * from public.shipping_agreement

-----Ш А Г  3------------------------------------------------------------------------------------------------------------------
--DROP table if exists public.shipping_transfer;
CREATE TABLE public.shipping_transfer 
(
id serial primary key,
transfer_type text NULL,
transfer_model text NULL,
shipping_transfer_rate numeric(4,3) NULL
);

insert into public.shipping_transfer
(transfer_type,transfer_model,shipping_transfer_rate)
SELECT DISTINCT shipping_transfer[1] AS transfer_type ,
			    shipping_transfer[2] AS transfer_model,
 			    shipping_transfer_rate
   			   
FROM (
      SELECT (regexp_split_to_array(shipping_transfer_description , E'\\:+')) AS shipping_transfer,
      shipping_transfer_rate
      FROM public.shipping s) AS v;

--select * from shipping_transfer
     
-----Ш А Г  4--------------------------------------------------------------------------------------------------------------------
--DROP table if exists public.shipping_info;
CREATE TABLE public.shipping_info 
(
shipping_id int NOT null  primary key,
vendor_id int8 NULL,
payment_amount numeric(14, 2) NULL,
shipping_plan_datetime timestamp NULL,
shipping_transfer_id  int8 NULL,
shipping_agreement_id  int8 NULL,
shipping_country_rate_id  int8 NULL,
FOREIGN KEY (shipping_transfer_id)     REFERENCES public.shipping_transfer (id) ON UPDATE CASCADE,
FOREIGN KEY (shipping_agreement_id)    REFERENCES public.shipping_agreement (agreement_id) ON UPDATE CASCADE,
FOREIGN KEY (shipping_country_rate_id) REFERENCES public.shipping_country_rates (id) ON UPDATE CASCADE

);     
          
insert into public.shipping_info 
(shipping_id, vendor_id, payment_amount, shipping_plan_datetime ,shipping_transfer_id, shipping_agreement_id, shipping_country_rate_id)

WITH st AS (
SELECT	
    id, 
	concat(transfer_type,':',transfer_model) AS shipping_transfer_description,
	shipping_transfer_rate
FROM 
	public.shipping_transfer)
SELECT
DISTINCT 
	s.shippingid AS shipping_id, 
	s.vendorid AS vendor_id,
	s.payment_amount,
	s.shipping_plan_datetime::timestamp,
	st.id as vendor_id,
	(regexp_split_to_array(s.vendor_agreement_description , E'\\:+'))[1]::int AS shipping_agreement_id,
	scr.id AS shipping_country_rate_id	
FROM
	public.shipping s
	left join public.shipping_country_rates scr ON (s.shipping_country= scr.shipping_country and s.shipping_country_base_rate = scr.shipping_country_base_rate)
	left join st								ON (s.shipping_transfer_description = st.shipping_transfer_description 	AND s.shipping_transfer_rate = st.shipping_transfer_rate)
--select   * from public.shipping_info
	
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
	
-----Ш А Г  6---------------------------------------------------------------------------------------------------------------------------------------------------------------------	
	
DROP VIEW IF EXISTS shipping_datamart;
CREATE VIEW shipping_datamart AS
SELECT 
	s.shipping_id,
	s.vendor_id,
	st.transfer_type,
	DATE_PART('DAY', AGE(ss.shipping_end_fact_datetime,ss.shipping_start_fact_datetime)) AS full_day_at_shipping,
	(CASE WHEN ss.shipping_end_fact_datetime>s.shipping_plan_datetime THEN 1 ELSE 0 END) AS is_delay,
	(CASE WHEN ss.status='finished' THEN 1 ELSE 0 END) AS is_shipping_finish,
	(CASE WHEN ss.shipping_end_fact_datetime>s.shipping_plan_datetime THEN DATE_PART('DAY', AGE(ss.shipping_end_fact_datetime,s.shipping_plan_datetime)) ELSE 0 END) AS delay_day_at_shipping,
	s.payment_amount,
	s.payment_amount * (scr.shipping_country_base_rate + sa.agreement_rate + st.shipping_transfer_rate ) AS vat,
	s.payment_amount * sa.agreement_commission AS profit
FROM shipping_info s
LEFT JOIN shipping_transfer st ON s.shipping_transfer_id=st.id
LEFT JOIN shipping_status ss ON s.shipping_id=ss.shipping_id
LEFT JOIN shipping_country_rates scr ON s.shipping_country_rate_id=scr.id
LEFT JOIN shipping_agreement sa ON s.shipping_agreement_id=sa.agreement_id;	
--select * from public.shipping_datamart