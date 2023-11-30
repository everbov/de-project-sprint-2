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
