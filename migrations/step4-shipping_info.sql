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
