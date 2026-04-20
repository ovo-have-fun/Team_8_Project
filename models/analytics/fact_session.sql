with session_events as (
    select *
    from {{ ref('int_session_events') }}
),
client_dim as (
    select client_id, client_key
    from {{ ref('dim_client') }}
)
select
    se.session_id,
    cd.client_key,
    se.client_id,
    se.session_time,
    se.ip,
    se.os,
    se.page_view_count,
    se.item_view_count,
    se.distinct_items_viewed,
    se.total_add_to_cart_qty,
    se.total_remove_from_cart_qty,
    se.net_cart_qty,
    se.saw_landing_page_flag,
    se.saw_shop_plants_flag,
    se.saw_plant_care_flag,
    se.saw_faq_flag,
    se.viewed_cart_flag,
    se.viewed_item_flag,
    se.added_to_cart_flag,
    se.placed_order_flag,
    se.order_count,
    se.funnel_step_reached,
    se.drop_off_stage
from session_events se
left join client_dim cd
on se.client_id = cd.client_id