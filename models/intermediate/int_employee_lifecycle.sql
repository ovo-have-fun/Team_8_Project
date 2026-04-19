with joins_data as (
    select *
    from {{ ref('base_googledrive_hr_joins') }}
),
quits_data as (
    select
        employee_id,
        min(quit_date) as quit_date
    from {{ ref('base_googledrive_hr_quits') }}
    group by 1
)

select
    j.employee_id,
    j.name as employee_name,
    j.city,
    j.address,
    j.title,
    j.annual_salary,
    j.hire_date,
    q.quit_date,
    case when q.quit_date is null or q.quit_date > current_date then true else false end as is_active,
    case when q.quit_date is null or q.quit_date > current_date then 'active' else 'inactive' end as employment_status
from joins_data j
left join quits_data q
on j.employee_id = q.employee_id