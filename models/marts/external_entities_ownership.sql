/* source CTEs */
with dashboards as (
    select *
    from {{ ref('dashboards') }}
    )

, datasets as (
    select *
    from {{ ref('datasets') }}
    )

, users as (
    select *
    from {{ ref('users') }}
    )    

/* logic CTEs */
, external_entities as (
    /* union datasets with dashboards because both of them can have owners */
    select 
        dashboard_id as external_entity_id
        , entity_type as external_entity_type
        , dashboard_owners as external_entity_owners
    from dashboards

    union all

    select 
        dataset_id as external_entity_id
        , entity_type as external_entity_type
        , dataset_owners as external_entity_owners
    from datasets
)

, external_entity_with_owners as (
select
    entity_with_owners.external_entity_id
    , external_entity_type
    , json_extract_string(owner_flat.owner_urn, '$.owner') as owner_id
from 
    external_entities as entity_with_owners,
    unnest(json_extract(external_entity_owners, '$.owners')::json[]) as owner_flat(owner_urn)
where 
    entity_with_owners.external_entity_owners is not null
)

select
    {{ dbt_utils.generate_surrogate_key(['external_entity_with_owners.external_entity_type'
                                       , 'user_details.user_name'
                                       , 'user_details.title']) }} as external_entities_ownership_id
    , external_entity_with_owners.external_entity_type
    , user_details.user_name
    , user_details.title
    , count(distinct external_entity_with_owners.external_entity_id) as distinct_id_count
from 
    external_entity_with_owners
left join 
    users as user_details
    on external_entity_with_owners.owner_id = user_details.user_id
group by 1, 2, 3, 4