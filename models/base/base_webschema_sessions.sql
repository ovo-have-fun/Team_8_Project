select "_fivetran_id",
       IP,
       CAST(SESSION_AT AS TIMESTAMP) AS SESSION_TIME,
       OS,
       CAST(CLIENT_ID as STRING)as CLIENT_ID,
       SESSION_ID,
       "_fivetran_deleted",
       CAST("_fivetran_synced" AS TIMESTAMP) AS _fivetran_synced,
from {{ source('web_schema', 'sessions') }}