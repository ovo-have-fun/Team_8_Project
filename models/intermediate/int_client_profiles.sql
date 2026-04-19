with sessions as (
    select *
    from {{ ref('int_deduped_sessions') }}
),
orders as (
    select *
    from {{ ref('int_deduped_orders') }}
),
session_stats as (
    select
        client_id,
        min(session_time) as first_session_at,
        max(session_time) as last_session_at,
        count(*) as session_count,
        max_by(os, session_time) as most_recent_os
    from sessions
group by 1
),
order_with_client as (
    select
        o.*,
        s.client_id
    from orders o
    left join sessions s
    on o.session_id = s.session_id
),
order_stats as (
    select
        client_id,
        min(order_time) as first_order_at,
        max(order_time) as last_order_at,
        count(*) as order_count
    from order_with_client
    where client_id is not null
    group by 1
),
latest_order_profile as (
    select
        client_id,
        client_name as latest_client_name,
        phone as latest_phone,
        state as latest_state,
        shipping_address as latest_shipping_address,
        row_number() over (
            partition by client_id
            order by order_time desc, order_id desc
        ) as rn
    from order_with_client
    where client_id is not null
)

select
    s.client_id,
    s.first_session_at,
    s.last_session_at,
    s.session_count,
    o.first_order_at,
    o.last_order_at,
    coalesce(o.order_count, 0) as order_count,
    lop.latest_client_name,
    lop.latest_phone,
    lop.latest_state,
    lop.latest_shipping_address,
    s.most_recent_os,
    case when coalesce(o.order_count, 0) > 1 then true else false end as is_repeat_customer
from session_stats s
left join order_stats o
on s.client_id = o.client_id
left join latest_order_profile lop
on s.client_id = lop.client_id
and lop.rn = 1