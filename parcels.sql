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
                 from property_profile join current_year on current_year.current_year = prop_val_yr),
     most_recent as (select prop_id, prop_val_yr, sup_num
                     from ordered
                     where rn = 1),
    -- select * from most_recent
     residential as (select most_recent.prop_id,
                            geo_id,
                            ltrim(rtrim(property.prop_type_cd))                    as prop_type_cd,
                            coalesce(property.state_cd, property_profile.state_cd) as tx_code,
                            property_profile.prop_val_yr,
                            most_recent.sup_num
                     from most_recent
                              join property
                                   on most_recent.prop_id = property.prop_id
                                       and ltrim(rtrim(prop_type_cd)) in ('R', 'MH')
                              join property_profile
                                   on most_recent.prop_id = property_profile.prop_id
                                       and most_recent.sup_num = property_profile.sup_num
                                       and most_recent.prop_val_yr = property_profile.prop_val_yr),
grouped as (
    select homestead_group_prop_assoc.prop_id,
           homestead_group_id from homestead_group_prop_assoc
                              join most_recent
                                   on most_recent.prop_id = homestead_group_prop_assoc.prop_id
                                       and most_recent.sup_num = homestead_group_prop_assoc.sup_num
                                       and most_recent.prop_val_yr = homestead_group_prop_assoc.prop_val_yr
)
select residential.prop_id pin,
       geo_id pin2,
       null as pin3,
       null as special_owner_type,
       null as married_owners,
       null as lat,
       null as long,
       market as market_value,
       appraised_val as assessed_value,
       assessed_val as tax_value,
       replace(replace(replace(replace(replace(replace(replace(replace(legal_desc, char(9), ' '), char(10), ' '), char(11), ' '), char(12), ' '), char(13), ' '), char(14), ' '), char(15), ' '), ',', ';') legal,
       concat(prop_type_cd, '|', tx_code) as p_class,
       homestead_group_id as hs_group
from property_val pv join residential
    on residential.prop_id = pv.prop_id
           and residential.prop_val_yr = pv.prop_val_yr
           and residential.sup_num = pv.sup_num
left join grouped on grouped.prop_id = pv.prop_id
