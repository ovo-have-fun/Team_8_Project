SELECT
    _fivetran_id,
    session_id,
    page_name,
    CAST(view_at AS TIMESTAMP) AS view_time,
    CAST(_fivetran_synced AS TIMESTAMP) AS _fivetran_synced,
    CAST(_fivetran_deleted AS BOOLEAN) AS _fivetran_deleted
FROM {{ source('web_schema', 'page_views') }}