


-- Task 1 invista
-- step 1 :insert metadata_catalog
-- invista_customer_sales: cl_id = 1026, cl_desc: Invista Sales by Customer

insert into ie.metadata_catalog(cl_id, mt_id,mc_name, mc_desc,mc_path)
select 1026, 17, 'ticker', 'public company', 'ticker'::ltree

insert into ie.metadata_catalog(cl_id, mt_id,mc_name, mc_desc,mc_path)
select 1026, 18, 'private_company_short_name', 'private company', 'private_company_short_name'::ltree

insert into ie.metadata_catalog(cl_id, mt_id,mc_name, mc_desc,mc_path)
select 1026, null, 'csiticker', 'csiticker', 'csiticker'::ltree

insert into ie.metadata_catalog(cl_id, mt_id,mc_name, mc_desc,mc_path)
select 1026, null, 'csiname', 'csiname', 'csiname'::ltree

insert into ie.metadata_catalog(cl_id, mt_id,mc_name, mc_desc,mc_path)
select 1026, null, 'private_company_name', 'private company name', 'private_company_name'::ltree

insert into ie.metadata_catalog(cl_id, mt_id,mc_name, mc_desc,mc_path)
select 1026, null, 'company_type', 'company type', 'company_type'::ltree

------------------------
-- step2: goal to these 219 rows (csiname is NULL, customer_name is NULL): 
-- update 
update ie.series s set sr_attrs = a.sr_attrs_updated
from(
	select 
		s.sr_attrs->>'csiname' as csiname,
		s.sr_attrs->>'Customer' as customer_name,
		s.sr_attrs,
		mc.md_name,
		mc.md_desc,
		s.cl_id,
		mc.mt_id,
		s.sr_desc,
		s.sr_id,
		jsonb_build_object(
	           'csiname','',
	           'csiticker','',
	           'ticker','_none_',
	           'private_company_name',mc.md_desc,
	           'private_company_short_name', case when mc.md_name is null then '_none_' else mc.md_name end,
	           'company_type','Private'
	           ) as sr_attrs_updated
	from ie.series s
	left join ie.metadata_company mc on trim(s.sr_desc) = trim(mc.md_desc)
	where s.cl_id = 1026 and s.sr_attrs->>'csiname' is null and s.sr_attrs->>'Customer'  is null 
) a where s.sr_id = a.sr_id

-------------------------------------------------------------------
-- step3: goal to these 59 rows (csiname is NULL, customer_name is not NULL): 
-- update 
update ie.series s set sr_attrs = a.sr_attrs_updated
from(
	select 
		s.sr_attrs->>'csiname' as csiname,
		s.sr_attrs->>'Customer' as customer_name,
		s.sr_attrs,
		s.sr_desc,
		s.cl_id,
		s.sr_id,
		mc.mt_id,
		max(mc.md_name) as md_name,
		jsonb_build_object(
	           'csiname','',
	           'csiticker','',
	           'ticker','_none_',
	           'private_company_name',s.sr_attrs->>'Customer',
	           'private_company_short_name', case when max(mc.md_name) is null then '_none_' else max(mc.md_name) end,
	           'company_type','Private'
	           ) as sr_attrs_updated
	from ie.series  s
	left join ie.metadata_company mc on s.sr_attrs->>'Customer' = mc.md_desc
	where s.cl_id = 1026 and s.sr_attrs->>'csiname' is null --and s.sr_attrs->>'Customer'  is not null 
	group by 1,2,3,4,5,6,7
	
) a where a.cl_id = 1026 and s.sr_id = a.sr_id

-------------------------------
-- step4: goal to these 272 rows (csiname is not NULL):
-- it is public company
-- update 
update ie.series s set sr_attrs = a.sr_attrs_updated
from(
	select 
		a.csiname,
		a.csiticker,
		a.sr_attrs,
		a.cl_id,
		a.sr_id,
		max(mc.md_name) md_name,
		jsonb_build_object(
	           'csiname', a.csiname,
	           'csiticker', a.csiticker,
	           'ticker',case when max(mc.md_name) is null then '_none_' else max(mc.md_name) end,
	           'private_company_name','',
	           'private_company_short_name', '+none_',
	           'company_type','Public'
	           ) as sr_attrs_updated
	from (
		select 
			sr_attrs->>'csiname' as csiname,
			sr_attrs->>'Customer' as customer_name,
			s.sr_attrs->>'csiticker' as csiticker,
			s.cl_id,
			s.sr_id,
			s.sr_attrs,
			s.sr_name,
			unnest(string_to_array( s.sr_attrs->>'csiticker',',') ) as csiticker_new
		from ie.series  s
		where cl_id = 1026 and sr_attrs->>'csiname'  is not null  and sr_attrs->>'csiname' != ''
	) a
	left join ie.metadata_company mc on lower(a.csiticker_new) = mc.md_name
	group by 1,2,3,4,5 
) a where s.cl_id = 1026 and s.sr_id = a.sr_id

----------------------------------------------------------------------------------
-- TASK for modex
-- step1: insert metadata_catalog
-- molex_customer_sales : cl_id = 1060, cl_desc: Molex Sales by Customer

insert into ie.metadata_catalog(cl_id, mt_id,mc_name, mc_desc,mc_path)
select 1060, 17, 'ticker', 'public company', 'ticker'::ltree

insert into ie.metadata_catalog(cl_id, mt_id,mc_name, mc_desc,mc_path)
select 1060, 18, 'private_company_short_name', 'private company', 'private_company_short_name'::ltree;

insert into ie.metadata_catalog(cl_id, mt_id,mc_name, mc_desc,mc_path)
select 1060, null, 'csiticker', 'csiticker', 'csiticker'::ltree;

insert into ie.metadata_catalog(cl_id, mt_id,mc_name, mc_desc,mc_path)
select 1060, null, 'csiname', 'csiname', 'csiname'::ltree;

insert into ie.metadata_catalog(cl_id, mt_id,mc_name, mc_desc,mc_path)
select 1060, null, 'private_company_name', 'private company name', 'private_company_name'::ltree;

insert into ie.metadata_catalog(cl_id, mt_id,mc_name, mc_desc,mc_path)
select 1060, null, 'company_type', 'company type', 'company_type'::ltree;

------------------
-- step2: private company('csiticker' is null)
-- update 
update ie.series s set sr_attrs = a.sr_attrs_updated
from(
	select 
		s.sr_attrs->>'csiname' as csiname,
		s.sr_attrs->>'Customer' as customer_name,
		s.sr_attrs,
		mc.md_name,
		mc.md_desc,
		s.cl_id,
		mc.mt_id,
		s.sr_desc,
		s.sr_id,
		jsonb_build_object(
	           'csiname','',
	           'csiticker','',
	           'ticker','_none_',
	           'private_company_name',mc.md_desc,
	           'private_company_short_name', case when mc.md_name is null then '_none_' else mc.md_name end,
	           'company_type','Private'
	           ) as sr_attrs_updated
	from ie.series s
	left join ie.metadata_company mc on trim(s.sr_desc) = trim(mc.md_desc)
	where s.cl_id = 1060 and s.sr_attrs->>'csiname' is null and s.sr_attrs->>'Customer'  is null 
) a where s.cl_id = 1060 and s.sr_id = a.sr_id

----------------------------------------------------
-- step3: public company('csiticker' is not null)
-- update 
update ie.series s set sr_attrs = b.sr_attrs_updated
from(
	select 
		a.csiname,
		a.csiticker,
		a.sr_id,
		a.sr_attrs,
	    max(mc.md_name) as md_name,
	    jsonb_build_object(
		   'csiname',a.csiname,
	       'csiticker',a.csiticker,
	       'ticker', case when max(mc.md_name) is null then '_none_' else  max(mc.md_name) end,
	       'private_company_name','' ,
	       'private_company_short_name', '_none_',
	       'company_type','Public'
		) as sr_attrs_updated
	from (
	select
			s.sr_attrs->>'csiname' as csiname,
			s.sr_attrs->>'csiticker' as csiticker,
			unnest(string_to_array( s.sr_attrs->>'csiticker',',') ) as csiticker_new,
			s.sr_id,
			s.sr_attrs
		from ie.series s
		where cl_id = 1060 and sr_attrs->>'csiname'  is not null 
	) a
	left join ie.metadata_company mc on a.csiticker_new = mc.md_name and mt_id = 17
	--where a.sr_attrs->>'csiticker' = 'org'
	group by 1,2,3,4

) b where s.cl_id = 1060 and  s.sr_id = b.sr_id
