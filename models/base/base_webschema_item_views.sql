SELECT
    _fivetran_id,
    session_id,
    item_name,
    CAST(price_per_unit AS FLOAT) AS price_per_unit,
    CAST(add_to_cart_quantity AS NUMBER) AS add_to_cart_quantity,
    CAST(remove_from_cart_quantity AS NUMBER) AS remove_from_cart_quantity,
    CAST(item_view_at AS TIMESTAMP) AS item_view_time,
    CAST(_fivetran_synced AS TIMESTAMP) AS _fivetran_synced,
    CAST(_fivetran_deleted AS BOOLEAN) AS _fivetran_deleted
FROM {{ source('web_schema', 'item_views') }}