SELECT
    _FILE,
    _LINE,
    _MODIFIED,
    _FIVETRAN_SYNCED,
    RETURNED_AT,
    ORDER_ID,
    IS_REFUNDED
FROM {{ source('google_drive', 'returns') }}