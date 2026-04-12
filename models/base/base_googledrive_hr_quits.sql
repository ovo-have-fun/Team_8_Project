SELECT
    _FILE,
    _LINE,
    _MODIFIED,
    _FIVETRAN_SYNCED,

    CAST(EMPLOYEE_ID AS NUMBER) AS EMPLOYEE_ID,
    TRY_TO_DATE(QUIT_DATE) AS QUIT_DATE

FROM {{ source('google_drive', 'hr_quits') }}