select chg_of_owner_prop_assoc.prop_id            as         pin,
       format(chg_of_owner.deed_dt, 'yyyy-MM-dd') as         date,
       deed_type_desc                             as         type,
       iif(sales_ratio_report.chg_of_owner_id is null, 0, 1) qualified_sale,
       seller.file_as_name                        as         grantor,
       buyer.file_as_name                         as         grantee,
       sale.sl_price                              as         price
from chg_of_owner_prop_assoc
         join chg_of_owner on chg_of_owner_prop_assoc.chg_of_owner_id = chg_of_owner.chg_of_owner_id
         join deed_type on chg_of_owner.deed_type_cd = deed_type.deed_type_cd
         left join sale on chg_of_owner_prop_assoc.chg_of_owner_id = sale.chg_of_owner_id
         left join sales_ratio_report
                   on sales_ratio_report.chg_of_owner_id = chg_of_owner_prop_assoc.chg_of_owner_id
         left join buyer_assoc on chg_of_owner_prop_assoc.chg_of_owner_id = buyer_assoc.chg_of_owner_id
         left join account buyer on buyer_id = buyer.acct_id
         left join seller_assoc on chg_of_owner_prop_assoc.chg_of_owner_id = seller_assoc.chg_of_owner_id
         left join account seller on seller_id = seller.acct_id
