select
    finance_date,
    order_count,
    gross_revenue_estimated,
    refund_amount_estimated,
    net_revenue_estimated,
    shipping_amount,
    expense_hr,
    expense_warehouse,
    expense_tech_tool,
    expense_other,
    payroll_expense_estimated,
    total_operating_expense,
    estimated_profit
from {{ ref('int_daily_revenue_costs') }}