
-- Public company task from Rishab
-- step1: basic information
SELECT * FROM ie.metadata_company
-- md_id, mt_id, md_name, md_desc, md_path, md_ticker, md_sector, md_industry, md_country, md_country_abbrv

select * from ie.series
----in series----
-- sr_id, cl_id, sr_name, sr_desc, sr_attrs, sr_first_observation, sr_lastest_observation,sr_create_date,sn_id,fr_id,sr_field,st_id,sr_update_fr_id
---example for sr_attrs: {"tag": "Hair / Skin Care Monthly Spend", "category": "Shopping", "datatype": "Crosstab", "answertext": "I don't buy these products on a regular basis", 
---"demographic": "Exurban", "subcategory": "Beauty Products", "questiontext": "How much do you spend per month on hair care, skin care, and fragrance products?", "demographiccategory": "Urban Density"}

select * from ie.series where cl_id=1156
-- 1531 rows

select sr_name,sr_desc,sr_attrs->>'customer' as customer,sr_attrs->>'csiticker' as csiticker from ie.series s where s.cl_id=1156
--1531 rows with  : sr_name, sr_desc, customer_name, ticker from ie.series s

select * from ie.metadata_company

select * from ie.metadata_catalog

-------------------------------------
-- step2 : get the 37 rows the md_name is null
--first query 
select sr_name,sr_desc,sr_attrs->>'customer' as customer,sr_attrs->>'csiticker' as csiticker ,mc.md_name 
from ie.series s 
left join ie.metadata_company mc on lower(s.sr_attrs->>'csiticker')=mc.md_name 
where s.cl_id=1156 and md_name is null
-- we find 37 rows the md_name is null.

select cl_id,sr_id,sr_attrs ,sr_name,sr_desc,sr_attrs->>'customer' as customer,sr_attrs->>'csiticker' as csiticker ,mc.md_name 
from ie.series s 
left join ie.metadata_company mc on lower(s.sr_attrs->>'csiticker')=mc.md_name 
where s.cl_id=1156 and md_name is null
-- row 37



--second query 
select a.cl_id,a.sr_id,a.sr_name,a.sr_desc,a.sr_attrs,mc.md_desc,mc.md_name, jsonb_set(sr_attrs,array['csiticker'],to_jsonb(upper(mc.md_name))) --into qa.gp_customer_sales
from
(select cl_id,sr_id,sr_name,sr_desc,sr_attrs,mc.md_name from ie.series s left join ie.metadata_company mc on lower(s.sr_attrs->>'csiticker')=mc.md_name where s.cl_id=1156
and md_name is null) a left join ie.metadata_company mc on mc.md_desc=a.sr_attrs->>'customer' and mc.md_sector is not null

SELECT * FROM ie.metadata_company

select a.cl_id,a.sr_id,a.sr_name,a.sr_desc,a.sr_attrs,mc.md_desc,mc.md_name, 
	jsonb_set(sr_attrs,array['csiticker'],to_jsonb(upper(mc.md_name))) --into qa.gp_customer_sales
from
(select cl_id,sr_id,sr_name,sr_desc,sr_attrs,mc.md_name from ie.series s left join ie.metadata_company mc on lower(s.sr_attrs->>'csiticker')=mc.md_name where s.cl_id=1156
and md_name is null) a 
left join ie.metadata_company mc on mc.md_desc=a.sr_attrs->>'customer' and mc.md_sector is not null


--------------------------------------
-- step3 : check the 37 rows infomation
SELECT * FROM ie.metadata_company where lower(md_name) like '%lumn%'

select * from ie.series where sr_name ='gp_bozzutos_inc_sales_monthly'

SELECT * FROM ie.metadata_company where lower(md_desc) like '%rmg%'

--------------------------------------
-- step4 : upload new file of 37 rows 

select * from qa_temp.gp_ticker_lookup
--id? company_name, industry, short_name

-------------------------------------------------------------------
-- step5 : deal with is_present = no 
-- 1. need to insert these rows into metadate_company
select * from qa_temp.gp_ticker_lookup where is_present like '%no%'

select * from qa_temp.gp_ticker_lookup where trim(is_present) = 'no'
-- row 6

select * from ie.metadata_company mc where md_name in  (select lower(csiticker)  from qa_temp.gp_ticker_lookup where trim(is_present) = 'no' )


--select
select 17, lower(csiticker) , customer, csiticker::ltree from qa_temp.gp_ticker_lookup where trim(is_present) = 'no'

--insert into metadata_company
insert into ie.metadata_company(mt_id, md_name, md_desc,md_path)
select 17, lower(csiticker) , customer, lower(csiticker)::ltree 
from qa_temp.gp_ticker_lookup pcn where trim(is_present) = 'no'

-- check after update
select * from ie.metadata_company where md_name in  (select lower(csiticker)  from qa_temp.gp_ticker_lookup where trim(is_present) = 'no' )


--------------------------------------------------------------------------------------
-- 2. for these 6 rows, we can also create 'csiticker_name'= 'csiticker'
select 
	pcn.customer,
	pcn.csiticker,
	pcn.is_present,
	s.sr_name,
	pcn.sr_name,
	sr_attrs,
	mc.md_name,
	mc.md_desc
from qa_temp.gp_ticker_lookup pcn
left join ie.series s on pcn.sr_name = s.sr_name 
left join ie.metadata_company mc on pcn.md_name = mc.md_name
where s.cl_id =1156  and trim(pcn.is_present) = 'no'

-- select
-- add jsonb
select 
	pcn.customer,
	pcn.csiticker,
	pcn.is_present,
	s.sr_name,
	pcn.sr_name,
	sr_attrs,
	sr_id,
	json_build_object(
	    'customer', s.sr_attrs->>'customer',
	    'csiticker',s.sr_attrs->>'csiticker',
	    'ticker',lower(s.sr_attrs->>'csiticker')
	) as sr_attrs_updated 
from qa_temp.gp_ticker_lookup pcn
left join ie.series s on pcn.sr_name = s.sr_name 
where s.cl_id =1156  and  trim(is_present) = 'no'

-- update 
update ie.series s set sr_attrs = a.sr_attrs_updated
from(
	select 
		pcn.customer,
		pcn.csiticker,
		pcn.is_present,
		s.sr_name,
		pcn.sr_name,
		sr_attrs,
		sr_id,
		json_build_object(
		    'customer', s.sr_attrs->>'customer',
		    'csiticker',s.sr_attrs->>'csiticker',
		    'ticker',lower(s.sr_attrs->>'csiticker')
		) as sr_attrs_updated 
	from qa_temp.gp_ticker_lookup pcn
	left join ie.series s on pcn.sr_name = s.sr_name 
	where s.cl_id =1156  and  trim(is_present) = 'no'
) a where s.sr_id = a.sr_id

-- check
select * from ie.series where  cl_id =1156 and sr_attrs->>'ticker' in (select lower(csiticker)  from qa_temp.gp_ticker_lookup where trim(is_present) = 'no')



----------------------------------------
-- step6: deal with is_present = yes, name_update = no
select * from qa_temp.gp_ticker_lookup pcn where trim(is_present) = 'yes' and trim(name_update) = 'no'
-- row 14
-- need to update ie.series sr_attrs
-- sr_attrs: {"customer": "Hillman Group Capital Trust", "csiticker": "HLM",'csiticker_new':md_name}
-- because there may be multiple md_desc, md_name in metadata_company, so just use the md_desc, md_name from metadata_caompany can match md_name from "public_ccustomerompany_update37"

-- select
select 
	pcn.customer,
	pcn.csiticker,
	pcn.is_present,
	pcn.name_update,
	pcn.md_desc,
	pcn.md_name,
	mc.md_desc ,
	mc.md_name,
	s.sr_name,
	pcn.sr_name,
	sr_attrs,
	s.sr_id,
	json_build_object(
	    'customer', s.sr_attrs->>'customer',
	    'csiticker',s.sr_attrs->>'csiticker',
	    'ticker', mc.md_name
	) as sr_attrs_updated 
from qa_temp.gp_ticker_lookup pcn
left join ie.series s on pcn.sr_name = s.sr_name 
left join ie.metadata_company mc on pcn.md_name = mc.md_name
where s.cl_id = 1156 and trim(is_present) = 'yes' and trim(name_update) = 'no'


-- update 
update ie.series s set sr_attrs = a.sr_attrs_updated
from(
	select 
		pcn.customer,
		pcn.csiticker,
		pcn.is_present,
		pcn.name_update,
		pcn.md_desc,
		pcn.md_name,
		mc.md_desc ,
		mc.md_name,
		s.sr_name,
		pcn.sr_name,
		sr_attrs,
		s.sr_id,
		json_build_object(
		    'customer', s.sr_attrs->>'customer',
		    'csiticker',s.sr_attrs->>'csiticker',
		    'ticker', mc.md_name
		) as sr_attrs_updated 
	from qa_temp.gp_ticker_lookup pcn
	left join ie.series s on pcn.sr_name = s.sr_name 
	left join ie.metadata_company mc on pcn.md_name = mc.md_name
	where s.cl_id = 1156 and trim(is_present) = 'yes' and trim(name_update) = 'no'
) a where s.cl_id =1156 and s.sr_id = a.sr_id


-- check 
select  * from ie.series where cl_id = 1156 and sr_attrs->>'customer' in (select customer from qa_temp.gp_ticker_lookup pcn where trim(is_present) = 'yes' and trim(name_update) = 'no')

-------------------------------------------
-- step7 : deal with is_present = yes, name_update = yes
select * from qa_temp.gp_ticker_lookup pcn where  trim(is_present) = 'yes' and trim(name_update) =  'yes'
-- row 17

--1. update sr_attrs in series
select 
	pcn.customer,
	pcn.csiticker,
	pcn.is_present,
	pcn.name_update,
	pcn.md_desc,
	pcn.md_name,
	mc.md_desc,
	pcn.ticker,
	mc.md_name,
	s.sr_name,
	pcn.sr_name,
	sr_attrs,
	sr_id,
	json_build_object(
	    'customer', s.sr_attrs->>'customer',
	    'csiticker',s.sr_attrs->>'csiticker',
	    'ticker',mc.md_name
	) as sr_attrs_updated 

from qa_temp.gp_ticker_lookup  pcn
left join ie.series s on pcn.sr_name = s.sr_name 
left join ie.metadata_company mc on pcn.md_name = mc.md_name
where s.cl_id=1156 and trim(is_present) = 'yes' and trim(name_update) =  'yes'

-- update 
update ie.series s set sr_attrs = a.sr_attrs_updated
from(
	select 
		pcn.customer,
		pcn.csiticker,
		pcn.is_present,
		pcn.name_update,
		pcn.md_desc,
		pcn.md_name,
		mc.md_desc,
		pcn.ticker,
		mc.md_name,
		s.sr_name,
		pcn.sr_name,
		sr_attrs,
		sr_id,
		json_build_object(
		    'customer', s.sr_attrs->>'customer',
		    'csiticker',s.sr_attrs->>'csiticker',
		    'ticker',mc.md_name
		) as sr_attrs_updated 
	
	from qa_temp.gp_ticker_lookup  pcn
	left join ie.series s on pcn.sr_name = s.sr_name 
	left join ie.metadata_company mc on pcn.md_name = mc.md_name
	where s.cl_id=1156 and trim(is_present) = 'yes' and trim(name_update) =  'yes'
) a where s.cl_id = 1156 and s.sr_id = a.sr_id

-- check 
select  * from ie.series where cl_id = 1156 and sr_attrs->>'customer' in (select customer from qa_temp.gp_ticker_lookup pcn where trim(is_present) = 'yes' and trim(name_update) = 'yes')



-- step8 : update for the other 1494 rows
-- select
--1531 in all
--1494 ticker is  null
select * from ie.series  where cl_id = 1156 and sr_attrs->>'ticker' is null

select 
    sr_id,
    sr_attrs,
    jsonb_build_object(
    'customer',sr_attrs->>'customer',
    'csiticker',sr_attrs->>'csiticker',
    'ticker',lower(sr_attrs->>'csiticker')
    ) as sr_attrs_updated
from ie.series  where cl_id = 1156 and sr_attrs->>'ticker' is null


-- update 
-- row 1494
update ie.series s set sr_attrs = a.sr_attrs_updated
from(
	select 
	    sr_id,
	    sr_attrs,
	    jsonb_build_object(
	    'customer',sr_attrs->>'customer',
	    'csiticker',sr_attrs->>'csiticker',
	    'ticker',lower(sr_attrs->>'csiticker')
	    ) as sr_attrs_updated
	from ie.series  where cl_id = 1156 and sr_attrs->>'ticker' is null
) a where s.cl_id = 1156 and s.sr_id = a.sr_id

-- check 
select * from ie.series where cl_id = 1156 --and sr_attrs->>'ticker' is null
--0 row

select * from ie.series s join ie.metadata_company mc on s.sr_attrs->>'ticker' = mc.md_name
where cl_id = 1156


select * from ie.metadata_catalog where cl_id = 1156

--------------------------------------------------------------
-- step9: insert ie.metadata_catalog 
select * from ie.metadata_catalog
-- mc_id, cl_id, mt_id,mc_name,mc_desc,mc_path

insert ie.metadata_catalog  values(1006,1156,17,'ticker','Ticker','company')
insert ie.metadata_catalog  values(1007,1156,null,'csiticker','Csiticker','company')
insert ie.metadata_catalog  values(1008,1156,null,'customer','Customer','company')









