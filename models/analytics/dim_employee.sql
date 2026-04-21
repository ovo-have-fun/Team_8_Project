select
    md5(cast(employee_id as string)) as employee_key,
    employee_id,
    employee_name,
    city,
    address,
    title,
    annual_salary,
    hire_date,
    quit_date,
    is_active,
    employment_status
from {{ ref('int_employee_lifecycle') }}