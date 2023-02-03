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
                     where rn = 1),
     mail as (select prop_id    as pin,
                     'mail'     as type,
                     null       as house_nbr,
                     null       as pre_direction,
                     null       as post_direction,
                     null       as street_name,
                     null       as street_suffix,
                     null       as unit_prefix,
                     null       as unit_nbrorletter,
                     concat_ws(
                             '|',
                             addr_line1,
                             addr_line2,
                             addr_line3
                         )      as address_line_1,
                     addr_city  as city,
                     addr_state as state,
                     zip        as zip5
              from address
                       join
                   (select owner_id, owner.prop_id
                    from owner
                             join most_recent
                                  on most_recent.prop_id = owner.prop_id
                                      and most_recent.prop_val_yr = owner.owner_tax_yr
                                      and most_recent.sup_num = owner.sup_num) o on owner_id = acct_id),
     non as (select most_recent.prop_id,
                    max(situs_num)          as situs_num,
                    max(situs_street_prefx) as situs_street_prefx,
                    max(situs_street)       as situs_street,
                    max(situs_street_sufix) as situs_street_sufix,
                    max(situs_unit)         as situs_unit,
                    max(situs_city)         as situs_city,
                    max(situs_state)        as situs_state,
                    max(situs_zip)          as situs_zip
             from most_recent
                      left join situs on most_recent.prop_id = situs.prop_id
             where primary_situs = 'N'
             group by most_recent.prop_id),
     oui as (select most_recent.prop_id,
                    situs_id,
                    situs_num,
                    situs_street_prefx,
                    situs_street,
                    situs_street_sufix,
                    situs_unit,
                    situs_city,
                    situs_state,
                    situs_zip
             from most_recent
                      left join situs on most_recent.prop_id = situs.prop_id
             where primary_situs = 'Y'),
     situs as (select oui.prop_id                                              as pin,
                      'situs'                                                  as type,
                      coalesce(oui.situs_num, non.situs_num)                   as house_nbr,
                      coalesce(oui.situs_street_prefx, non.situs_street_prefx) as pre_direction,
                      null                                                     as post_direction,
                      coalesce(oui.situs_street, non.situs_street)             as street_name,
                      coalesce(oui.situs_street_sufix, non.situs_street_sufix) as street_suffix,
                      null                                                     as unit_prefix,
                      coalesce(oui.situs_unit, non.situs_unit)                 as unit_nbrorletter,
                      null                                                     as address_line_1,
                      coalesce(oui.situs_city, non.situs_city)                 as city,
                      coalesce(oui.situs_state, non.situs_state)               as state,
                      coalesce(oui.situs_zip, non.situs_zip)                   as zip5
               from oui
                        left join non on oui.prop_id = non.prop_id),
all_addresses as (
    select *
    from situs
    union all
    select *
    from mail
    )
select pin,
       type,
       replace(house_nbr, ',', '') as house_nbr,
       replace(pre_direction, ',', '') as pre_direction,
       replace(post_direction, ',', '') as post_direction,
       replace(street_name, ',', '') as street_name,
       replace(street_suffix, ',', '') as street_suffix,
       replace(unit_prefix, ',', '') as unit_prefix,
       replace(unit_nbrorletter, ',', '') as unit_nbrorletter,
       replace(address_line_1, ',', '') as address_line_1,
       replace(city, ',', '') as city,
       replace(state, ',', '') as state,
       replace(zip5, ',', '') as zip5
from all_addresses
