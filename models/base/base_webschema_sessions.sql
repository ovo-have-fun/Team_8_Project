select _fivetran_id,
       IP,
       CAST(session_at AS TIMESTAMP) AS session_time,
       OS,
       CAST(client_id as string)as client_id,
       session_id,
       CAST(_fivetran_deleted AS BOOLEAN) AS _fivetran_deleted,
       CAST(_fivetran_synced AS TIMESTAMP) AS _fivetran_synced,
from {{ source('web_schema', 'sessions') }}