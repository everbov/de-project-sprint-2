
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