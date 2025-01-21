/* source CTEs */
with users as (
    select *

    from {{ ref('stg_datahub_entities') }}

    where entity_type = 'user'
    )

/* logic CTEs */
, user_details as (
    /* it is more memory-efficient and performant to 
       extract a list of paths when extract multiple 
       values from the same json */

    select
        urn
        , json_extract_string(entity_details, 
            ['username'
            , 'departmentName'
            , 'lastName'
            , 'firstName'
            , 'displayName'
            , 'fullName'
            , 'active'
            , 'title'
            , 'email']) AS detail_list

    from users
)

select
    /* primary key */
    users.urn as user_id

    /* timestamps */
    , users.entity_created_at as user_created_at

    /* flags */
    , user_details.detail_list[7]::boolean as is_active

    /* user details */ 
    , user_details.detail_list[1] as user_name
    , user_details.detail_list[2] as department_name
    , user_details.detail_list[3] as last_name
    , user_details.detail_list[4] as first_name
    , user_details.detail_list[5] as display_name
    , user_details.detail_list[6] as full_name
    , user_details.detail_list[8] as title
    , user_details.detail_list[9] as email
    , lower(users.entity_created_by[8:]) as user_created_by

from users 
left join user_details on users.urn = user_details.urn