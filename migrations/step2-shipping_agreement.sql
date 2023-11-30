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
