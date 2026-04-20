with orders as (
    select *
    from {{ ref('int_deduped_orders') }}
),
sessions as (
    select *
    from {{ ref('int_deduped_sessions') }}
),
item_views as (
    select *
    from {{ ref('base_webschema_item_views') }}
    where coalesce(_fivetran_deleted, false) = false
),
returns_raw as (
    select *
    from {{ ref('base_googledrive_returns') }}
),
session_item_rollup as (
    select
        session_id,
        item_name,
        max(price_per_unit) as price_per_unit,
        sum(coalesce(add_to_cart_quantity, 0)) as add_qty,
        sum(coalesce(remove_from_cart_quantity, 0)) as remove_qty,
        greatest(sum(coalesce(add_to_cart_quantity, 0)) - sum(coalesce(remove_from_cart_quantity, 0)), 0) as net_qty
    from item_views
    group by 1, 2
),
session_estimated_subtotal as (
    select
        session_id,
        sum(net_qty * price_per_unit) as estimated_item_subtotal,
        count_if(net_qty > 0) as distinct_items_in_final_cart,
        sum(net_qty) as estimated_total_units
    from session_item_rollup
    group by 1
),
returns_rollup as (
    select
        order_id,
        min(returned_at::timestamp) as returned_at, ---这里有错误，修改了
        max(
            case
                when lower(cast(is_refunded as string)) in ('1', 'true', 't', 'yes', 'y') then 1
                else 0
            end
        ) as is_refunded_num,
        1 as is_returned
    from returns_raw
    group by 1
)

select
    o.order_id,
    o.session_id,
    s.client_id,
    o.order_time,
    o.client_name,
    o.phone,
    o.state,
    o.shipping_address,
    o.payment_method,
    o.payment_info,
    o.tax_rate,
    o.shipping_cost,
    coalesce(se.estimated_item_subtotal, 0) as estimated_item_subtotal,
    (
        coalesce(se.estimated_item_subtotal, 0) * (1 + coalesce(o.tax_rate, 0))
    ) + coalesce(o.shipping_cost, 0) as estimated_order_total,
    coalesce(se.distinct_items_in_final_cart, 0) as distinct_items_in_final_cart,
    coalesce(se.estimated_total_units, 0) as estimated_total_units,
    coalesce(rr.is_returned, 0) as is_returned,
    rr.returned_at,
    case when coalesce(rr.is_refunded_num, 0) = 1 then true else false end as is_refunded
from orders o
left join sessions s
on o.session_id = s.session_id
left join session_estimated_subtotal se
on o.session_id = se.session_id
left join returns_rollup rr
on o.order_id = rr.order_id