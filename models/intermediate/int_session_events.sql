with sessions as (
    select *
    from {{ ref('int_deduped_sessions') }}
),
page_views as (
    select *
    from {{ ref('base_webschema_page_views') }}
    where coalesce(_fivetran_deleted, false) = false
),
item_views as (
    select *
    from {{ ref('base_webschema_item_views') }}
    where coalesce(_fivetran_deleted, false) = false
),
orders as (
    select *
    from {{ ref('int_deduped_orders') }}
),
page_metrics as (
    select
        session_id,
        count(*) as page_view_count,
        max(case when lower(page_name) like '%shop%' then 1 else 0 end) as saw_shop_plants_flag,
        max(case when lower(page_name) like '%cart%' then 1 else 0 end) as viewed_cart_flag,
        max(case when lower(page_name) like '%landing%' then 1 else 0 end) as saw_landing_page_flag,
        max(case when lower(page_name) like '%plant care%' or lower(page_name)
like '%care%' then 1 else 0 end) as saw_plant_care_flag,
        max(case when lower(page_name) like '%faq%' then 1 else 0 end) as saw_faq_flag
    from page_views
    group by 1
),
item_metrics as (
    select
        session_id,
        count(*) as item_view_count,
        count(distinct item_name) as distinct_items_viewed,
        sum(coalesce(add_to_cart_quantity, 0)) as total_add_to_cart_qty,
        sum(coalesce(remove_from_cart_quantity, 0)) as total_remove_from_cart_qty,
        sum(coalesce(add_to_cart_quantity, 0)) - sum(coalesce(remove_from_cart_quantity, 0)) as net_cart_qty,
        max(case when item_name is not null then 1 else 0 end) as viewed_item_flag,
        max(case when coalesce(add_to_cart_quantity, 0) > 0 then 1 else 0 end) as added_to_cart_flag
    from item_views
    group by 1
),
order_metrics as (
    select
        session_id,
        count(*) as order_count,
        1 as placed_order_flag
    from orders
    group by 1
)

select
    s.session_id,
    s.client_id,
    s.session_time,
    s.ip,
    s.os,
    coalesce(pm.page_view_count, 0) as page_view_count,
    coalesce(im.item_view_count, 0) as item_view_count,
    coalesce(im.distinct_items_viewed, 0) as distinct_items_viewed,
    coalesce(im.total_add_to_cart_qty, 0) as total_add_to_cart_qty,
    coalesce(im.total_remove_from_cart_qty, 0) as total_remove_from_cart_qty,
    coalesce(im.net_cart_qty, 0) as net_cart_qty,
    coalesce(pm.saw_landing_page_flag, 0) as saw_landing_page_flag,
    coalesce(pm.saw_shop_plants_flag, 0) as saw_shop_plants_flag,
    coalesce(pm.saw_plant_care_flag, 0) as saw_plant_care_flag,
    coalesce(pm.saw_faq_flag, 0) as saw_faq_flag,
    coalesce(pm.viewed_cart_flag, 0) as viewed_cart_flag,
    coalesce(im.viewed_item_flag, 0) as viewed_item_flag,
    coalesce(im.added_to_cart_flag, 0) as added_to_cart_flag,
    coalesce(om.placed_order_flag, 0) as placed_order_flag,
    coalesce(om.order_count, 0) as order_count,
    case
        when coalesce(om.placed_order_flag, 0) = 1 then 'placed_order'
        when coalesce(im.added_to_cart_flag, 0) = 1 or coalesce(pm.viewed_cart_flag, 0) = 1 then 'cart'
        when coalesce(im.viewed_item_flag, 0) = 1 then 'item_view'
        when coalesce(pm.saw_shop_plants_flag, 0) = 1 then 'shop_page'
        else 'session_only'
    end as funnel_step_reached,
    case
        when coalesce(om.placed_order_flag, 0) = 1 then 'converted'
        when coalesce(im.added_to_cart_flag, 0) = 1 or coalesce(pm.viewed_cart_flag, 0) = 1 then 'dropped_after_cart'
        when coalesce(im.viewed_item_flag, 0) = 1 then 'dropped_after_item_view'
        when coalesce(pm.saw_shop_plants_flag, 0) = 1 then 'dropped_after_shop_page'
        else 'dropped_before_shop_page'
    end as drop_off_stage
from sessions s
left join page_metrics pm
on s.session_id = pm.session_id
left join item_metrics im
on s.session_id = im.session_id
left join order_metrics om
on s.session_id = om.session_id