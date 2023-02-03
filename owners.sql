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
     all_owners as (select most_recent.prop_id         as pin,
                           IIF(
                                       lower(account.confidential_flag) = 't',
                                       account.confidential_first_name,
                                       account.first_name
                               )                       as first_name,
                           null                        as middle_name,
                           IIF(
                                       lower(account.confidential_flag) = 't',
                                       account.confidential_last_name,
                                       account.last_name
                               )                       as last_name,
                           null                        as suffix,
                           IIF(
                                       lower(account.confidential_flag) = 't',
                                       account.confidential_file_as_name,
                                       account.file_as_name
                               )                       as full_name,
                           format(coalesce(
                                          owner.birth_dt,
                                          account.birth_dt,
                                          property_exemption.birth_dt
                                      ), 'yyyy-MM-dd') as dob,
                           format(coalesce(
                                          account.spouse_birth_dt,
                                          property_exemption.spouse_birth_dt
                                      ), 'yyyy-MM-dd') as spouse_dob,
                           coalesce(
                                   account.dl_num,
                                   property_exemption.prop_exmpt_dl_num
                               )                       as dl_num,
                           prop_exmpt_ss_num           as ssn,
                           owner.owner_id              as party_id
                    from most_recent
                             join owner on most_recent.prop_id = owner.prop_id
                        and prop_val_yr = owner_tax_yr
                        and most_recent.sup_num = owner.sup_num
                             join account on owner_id = acct_id
                             left join property_exemption
                                       on owner.owner_id = property_exemption.owner_id
                                           and owner.owner_tax_yr = property_exemption.owner_tax_yr
                                           and most_recent.sup_num = property_exemption.sup_num),
     counted as (select all_owners.*,
                        row_number()
                                over (
                                    partition by pin, party_id
                                    order by (
                                            IIF(first_name is null, 1, 0) +
                                            IIF(middle_name is null, 1, 0) +
                                            IIF(last_name is null, 1, 0) +
                                            IIF(suffix is null, 1, 0) +
                                            IIF(full_name is null, 1, 0) +
                                            IIF(dob is null, 1, 0) +
                                            IIF(spouse_dob is null, 1, 0) +
                                            IIF(dl_num is null, 1, 0) +
                                            IIF(ssn is null, 1, 0))
                                    ) rn
                 from all_owners)
select pin,
       first_name,
       middle_name,
       last_name,
       suffix,
       full_name,
       dob,
       dl_num,
       substring(
               ssn,
               len(ssn) - 3,
               4
           ) as ssn4,
       iif(
               spouse_dob is null,
               null,
               concat('{"spouse_dob": "', spouse_dob, '"}')
           ) as details,
       party_id
from counted
where rn = 1
