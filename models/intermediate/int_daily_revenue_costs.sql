with orders as (
    select *
    from {{ ref('int_order_details') }}
),

expenses as (
    select *
    from {{ ref('base_googledrive_expenses') }}
),

employees as (
    select *
    from {{ ref('int_employee_lifecycle') }}
),

bounds as (
    select
        least(
            coalesce((select min(cast(order_time as date)) from orders), current_date),
            coalesce((select min(expense_date) from expenses), current_date),
            coalesce((select min(hire_date) from employees), current_date)
        ) as min_date,
        greatest(
            coalesce((select max(cast(order_time as date)) from orders), current_date),
            coalesce((select max(expense_date) from expenses), current_date),
            coalesce((select max(coalesce(quit_date, current_date)) from employees), current_date)
        ) as max_date
),

date_spine as (
    select
        dateadd(day, seq4(), b.min_date)::date as finance_date
    from bounds b,
         table(generator(rowcount => 10000))
    qualify finance_date <= b.max_date
),

revenue_by_day as (
    select
        cast(order_time as date) as finance_date,
        count(*) as order_count,
        sum(estimated_order_total) as gross_revenue_estimated,
        sum(case when is_refunded then estimated_order_total else 0 end) as refund_amount_estimated,
        sum(estimated_order_total) - sum(case when is_refunded then estimated_order_total else 0 end) as net_revenue_estimated,
        sum(coalesce(shipping_cost, 0)) as shipping_amount
    from orders
    group by 1
),

expenses_by_day as (
    select
        expense_date as finance_date,
        sum(case when lower(expense_type) like '%hr%' then expense_amount else 0 end) as expense_hr,
        sum(case when lower(expense_type) like '%warehouse%' then expense_amount else 0 end) as expense_warehouse,
        sum(case when lower(expense_type) like '%tool%' or lower(expense_type) like '%tech%' or lower(expense_type) like '%software%' then expense_amount else 0 end) as expense_tech_tool,
        sum(case when lower(expense_type) not like '%hr%'
                   and lower(expense_type) not like '%warehouse%'
                   and lower(expense_type) not like '%tool%'
                   and lower(expense_type) not like '%tech%'
                   and lower(expense_type) not like '%software%'
                 then expense_amount else 0 end) as expense_other
    from expenses
    group by 1
),

payroll_by_day as (
    select
        d.finance_date,
        sum(e.annual_salary / 365.0) as payroll_expense_estimated
    from date_spine d
    join employees e
        on d.finance_date >= e.hire_date
       and d.finance_date <= coalesce(e.quit_date, current_date)
    group by 1
)

select
    d.finance_date,
    coalesce(r.order_count, 0) as order_count,
    coalesce(r.gross_revenue_estimated, 0) as gross_revenue_estimated,
    coalesce(r.refund_amount_estimated, 0) as refund_amount_estimated,
    coalesce(r.net_revenue_estimated, 0) as net_revenue_estimated,
    coalesce(r.shipping_amount, 0) as shipping_amount,
    coalesce(e.expense_hr, 0) as expense_hr,
    coalesce(e.expense_warehouse, 0) as expense_warehouse,
    coalesce(e.expense_tech_tool, 0) as expense_tech_tool,
    coalesce(e.expense_other, 0) as expense_other,
    coalesce(p.payroll_expense_estimated, 0) as payroll_expense_estimated,
    coalesce(e.expense_hr, 0)
        + coalesce(e.expense_warehouse, 0)
        + coalesce(e.expense_tech_tool, 0)
        + coalesce(e.expense_other, 0)
        + coalesce(p.payroll_expense_estimated, 0) as total_operating_expense,
    coalesce(r.net_revenue_estimated, 0)
        - (
            coalesce(e.expense_hr, 0)
            + coalesce(e.expense_warehouse, 0)
            + coalesce(e.expense_tech_tool, 0)
            + coalesce(e.expense_other, 0)
            + coalesce(p.payroll_expense_estimated, 0)
        ) as estimated_profit
from date_spine d
left join revenue_by_day r
    on d.finance_date = r.finance_date
left join expenses_by_day e
    on d.finance_date = e.finance_date
left join payroll_by_day p
    on d.finance_date = p.finance_date