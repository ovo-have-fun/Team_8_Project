select
    sku_key,
    item_name,
    current_price,
    first_seen_at,
    last_seen_at,
    times_viewed,
    total_add_to_cart_qty,
    total_remove_from_cart_qty
from {{ ref('int_unique_skus') }}