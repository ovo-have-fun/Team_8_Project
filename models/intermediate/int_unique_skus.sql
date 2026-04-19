with item_views as (
    select *
    from {{ ref('base_webschema_item_views') }}
    where coalesce("_FIVETRAN_DELETED", false) = false
),
latest_price as (
    select
        item_name,
        price_per_unit as current_price,
        item_view_time,
        row_number() over (
            partition by item_name
            order by item_view_time desc, "_FIVETRAN_SYNCED" desc, "_fivetran_id" desc
        ) as rn
    from item_views
)

select
    md5(iv.item_name) as sku_key,
    iv.item_name,
    min(iv.item_view_time) as first_seen_at,
    max(iv.item_view_time) as last_seen_at,
    max(case when lp.rn = 1 then lp.current_price end) as current_price,
    count(*) as times_viewed,
    sum(coalesce(iv.add_to_cart_quantity, 0)) as total_add_to_cart_qty,
    sum(coalesce(iv.remove_from_cart_quantity, 0)) as total_remove_from_cart_qty
from item_views iv
left join latest_price lp
on iv.item_name = lp.item_name
group by 1, 2