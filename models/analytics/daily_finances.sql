with order_details as (
    select *
    from {{ ref('int_order_details') }}
),

expenses as (
    select *
    from {{ ref('base_googledrive_expenses') }}
),

employee_lifecycle as (
    select *
    from {{ ref('int_employee_lifecycle') }}
),

all_relevant_dates as (

    select cast(order_time as date) as finance_date
    from order_details

    union

    select cast(returned_at as date) as finance_date
    from order_details
    where returned_at is not null

    union

    select cast(expense_date as date) as finance_date
    from expenses

    union

    select cast(hire_date as date) as finance_date
    from employee_lifecycle

    union

    select cast(quit_date as date) as finance_date
    from employee_lifecycle
    where quit_date is not null
),

date_bounds as (
    select
        min(finance_date) as min_date,
        max(finance_date) as max_date
    from all_relevant_dates
),

date_spine as (
    select
        dateadd(day, row_number() over (order by seq4()) - 1, db.min_date) as finance_date
    from date_bounds db,
         table(generator(rowcount => 10000))
    qualify finance_date <= db.max_date
),

daily_orders as (
    select
        cast(order_time as date) as finance_date,
        count(distinct order_id) as order_count,
        sum(coalesce(estimated_item_subtotal, 0)) as gross_item_revenue_estimated,
        sum(coalesce(shipping_cost, 0)) as shipping_amount,
        sum(coalesce(estimated_order_total, 0)) as gross_revenue_estimated
    from order_details
    group by 1
),

daily_refunds as (
    select
        cast(returned_at as date) as finance_date,
        count(distinct order_id) as refunded_order_count,
        sum(
            case
                when is_refunded = true then coalesce(estimated_order_total, 0)
                else 0
            end
        ) as refund_amount_estimated
    from order_details
    where returned_at is not null
    group by 1
),

daily_expenses as (
    select
        cast(expense_date as date) as finance_date,

        sum(
            case
                when lower(expense_type) = 'hr' then coalesce(expense_amount, 0)
                else 0
            end
        ) as expense_hr,

        sum(
            case
                when lower(expense_type) = 'warehouse' then coalesce(expense_amount, 0)
                else 0
            end
        ) as expense_warehouse,

        sum(
            case
                when lower(expense_type) in ('tech tool', 'tech tools', 'tech_tool', 'tech')
                    then coalesce(expense_amount, 0)
                else 0
            end
        ) as expense_tech_tool,

        sum(
            case
                when lower(expense_type) not in ('hr', 'warehouse', 'tech tool', 'tech tools', 'tech_tool', 'tech')
                    then coalesce(expense_amount, 0)
                else 0
            end
        ) as expense_other

    from expenses
    group by 1
),

employee_active_days as (
    select
        ds.finance_date,
        el.employee_id,
        el.annual_salary
    from date_spine ds
    join employee_lifecycle el
      on ds.finance_date >= cast(el.hire_date as date)
     and ds.finance_date <= cast(coalesce(el.quit_date, current_date) as date)
),

daily_payroll as (
    select
        finance_date,
        count(distinct employee_id) as active_employee_count,
        sum(coalesce(annual_salary, 0) / 365.0) as payroll_expense_estimated
    from employee_active_days
    group by 1
)

select
    ds.finance_date,
    coalesce(do.order_count, 0) as order_count,
    coalesce(do.gross_item_revenue_estimated, 0) as gross_item_revenue_estimated,
    coalesce(do.shipping_amount, 0) as shipping_amount,
    coalesce(do.gross_revenue_estimated, 0) as gross_revenue_estimated,
    coalesce(dr.refunded_order_count, 0) as refunded_order_count,
    coalesce(dr.refund_amount_estimated, 0) as refund_amount_estimated,
    coalesce(do.gross_revenue_estimated, 0) - coalesce(dr.refund_amount_estimated, 0) as net_revenue_estimated,
    coalesce(de.expense_hr, 0) as expense_hr,
    coalesce(de.expense_warehouse, 0) as expense_warehouse,
    coalesce(de.expense_tech_tool, 0) as expense_tech_tool,
    coalesce(de.expense_other, 0) as expense_other,
    coalesce(dp.active_employee_count, 0) as active_employee_count,
    coalesce(dp.payroll_expense_estimated, 0) as payroll_expense_estimated,
    (
        coalesce(de.expense_hr, 0)
        + coalesce(de.expense_warehouse, 0)
        + coalesce(de.expense_tech_tool, 0)
        + coalesce(de.expense_other, 0)
        + coalesce(dp.payroll_expense_estimated, 0)
    ) as total_operating_expense,
    (
        coalesce(do.gross_revenue_estimated, 0)
        - coalesce(dr.refund_amount_estimated, 0)
        - (
            coalesce(de.expense_hr, 0)
            + coalesce(de.expense_warehouse, 0)
            + coalesce(de.expense_tech_tool, 0)
            + coalesce(de.expense_other, 0)
            + coalesce(dp.payroll_expense_estimated, 0)
        )
    ) as estimated_profit
from date_spine ds
left join daily_orders do
    on ds.finance_date = do.finance_date
left join daily_refunds dr
    on ds.finance_date = dr.finance_date
left join daily_expenses de
    on ds.finance_date = de.finance_date
left join daily_payroll dp
    on ds.finance_date = dp.finance_date
order by ds.finance_date