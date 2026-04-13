SELECT
    "_fivetran_id",
    CAST("_fivetran_synced" AS TIMESTAMP) AS _fivetran_synced,
    CAST("_fivetran_deleted" AS BOOLEAN) AS _fivetran_deleted,
    SESSION_ID,
    PAGE_NAME,
    CAST(VIEW_AT AS TIMESTAMP) AS VIEW_TIME
FROM {{ source('web_schema', 'page_views') }}