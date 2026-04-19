with source_data as (
    select *
    from {{ ref('base_webschema_orders') }}
where coalesce("_FIVETRAN_DELETED", false) = false
),
ranked as (
    select *,
        row_number() over (
            partition by order_id
            order by order_time asc, "_FIVETRAN_SYNCED" asc, "_fivetran_id" asc
        ) as rn
    from source_data
)

select
    "_fivetran_id",
    "_FIVETRAN_SYNCED",
    "_FIVETRAN_DELETED",
    order_id,
    session_id,
    client_name,
    phone,
    state,
    shipping_address,
    payment_method,
    payment_info,
    tax_rate,
    order_time,
    shipping_cost
from ranked
where rn = 1