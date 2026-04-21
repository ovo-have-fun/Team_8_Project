select
    order_id,
    session_id,
    client_id,
    order_time,
    client_name,
    state,
    payment_method,
    shipping_cost,
    tax_rate,
    estimated_item_subtotal,
    estimated_order_total,
    is_returned,
    returned_at,
    is_refunded
from {{ ref('int_order_details') }}