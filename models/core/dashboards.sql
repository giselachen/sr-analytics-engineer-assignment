/* source CTEs */
with dashboards as (
    select *

    from {{ ref('stg_datahub_entities') }}
    
    where entity_type = 'dashboard'
    )

/* logic CTEs */
, dashboard_details as (
    /* It is more memory-efficient and performant to 
       extract a list of paths when extract multiple 
       values from the same JSON */

    select
        urn
        /* Exclude CustomProperties, datasets 
           and dashboards keys because the values are 
           not populated. */   
        , json_extract_string(entity_details, 
            ['dashboardId'
            , 'dashboardTool'
            , 'description'
            , 'title'
            , 'dashboardUrl'
            , 'charts'
            , 'lastModified']) AS detail_list

    from dashboards
    )

select
    /* primary key */
    dashboards.urn as dashboard_id

    /* timestamps */
    , dashboards.entity_created_at as dashboard_created_at
    , dashboard_details.detail_list[8] as dashboard_last_modified_at

    /* flags */

    /* dashboard details */
    , dashboards.entity_type
    , dashboard_details.detail_list[1] as dashboard_detail_id
    , dashboard_details.detail_list[2] as dashboard_tool
    , dashboard_details.detail_list[3] as dashboard_description
    , dashboard_details.detail_list[4] as dashboard_title
    , dashboard_details.detail_list[5] as dashboard_url
    , dashboard_details.detail_list[6] as dashboard_charts
    , lower(dashboards.entity_created_by[8:]) as dashboard_created_by

    /* dashboard relationship json */
    , dashboards.domains as dashboard_domains
    , dashboards.glossary_terms as dashboard_glossary_terms
    , dashboards.owners as dashboard_owners

from dashboards 
left join dashboard_details on dashboards.urn = dashboard_details.urn