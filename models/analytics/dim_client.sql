select
    md5(client_id) as client_key,
    client_id,
    latest_client_name,
    latest_phone,
    latest_state,
    latest_shipping_address,
    first_session_at,
    last_session_at,
    first_order_at,
    last_order_at,
    session_count,
    order_count,
    is_repeat_customer,
    most_recent_os
from {{ ref('int_client_profiles') }}