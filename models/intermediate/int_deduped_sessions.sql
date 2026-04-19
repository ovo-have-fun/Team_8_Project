with source_data as (
    select *
    from {{ ref('base_webschema_sessions') }}
    where coalesce("_fivetran_deleted", false) = false
),
ranked as (
    select *,
        row_number() over (
            partition by session_id
            order by session_time asc, "_FIVETRAN_SYNCED" asc, "_fivetran_id" asc
        ) as rn
from source_data
)

select
    "_fivetran_id",
    "_FIVETRAN_SYNCED",
    "_fivetran_deleted",
    session_id,
    client_id,
    session_time,
    ip,
    os
from ranked
where rn = 1