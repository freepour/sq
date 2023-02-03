with current_year as (select max(prop_val_yr) current_year from property_profile),
     ordered as (select prop_id,
                        prop_val_yr,
                        sup_num,
                        row_number()
                                over (
                                    partition by prop_id
                                    order by
                                        prop_val_yr desc,
                                        sup_num desc
                                    ) rn
                 from property_profile
                          join current_year on current_year.current_year = prop_val_yr),
     most_recent as (select prop_id, prop_val_yr, sup_num
                     from ordered
                     where rn = 1)
select property_exemption.prop_id as pin,
       exmpt_type_cd              as code,
       coalesce(
               format(effective_dt, 'yyyy-MM-dd'),
               IIF(
                       qualify_yr is null,
                       null,
                       cast(concat(cast(qualify_yr as varchar), '-01-01') as varchar))
           )                      as start_date,
       termination_dt                end_date,
       property_exemption.owner_id   party_id
from property_exemption
         join
     (select owner_id,
             owner.prop_id,
             owner.sup_num,
             owner.owner_tax_yr
      from owner
               join most_recent
                    on most_recent.prop_id = owner.prop_id
                        and most_recent.prop_val_yr = owner.owner_tax_yr
                        and most_recent.sup_num = owner.sup_num) o
     on o.owner_id = property_exemption.owner_id
         and o.prop_id = property_exemption.prop_id
         and o.sup_num = property_exemption.sup_num
         and o.owner_tax_yr = property_exemption.exmpt_tax_yr
         join current_year on exmpt_tax_yr = current_year.current_year
