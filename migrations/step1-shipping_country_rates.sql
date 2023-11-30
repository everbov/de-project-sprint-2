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
