select coalesce(
               cad_exemption_code,
               exmpt_type_cd
           )      as exemption_code,
       exmpt_desc as description
from exmpt_type
         left join cad_exemptions
                   on exmpt_type_cd = cad_exemptions.pacs_exemption_code
