/* source CTEs */
with datasets as (
    select *

    from {{ ref('stg_datahub_entities') }}
    
    where entity_type = 'dataset'
    )

/* logic CTEs */
, dataset_details as (
    /* It is more memory-efficient and performant to 
       extract a list of paths when extract multiple 
       values from the same JSON */

    select
        urn
        , json_extract_string(entity_details, 
            ['name'
            , 'platform'
            , 'origin']) AS detail_list

    from datasets
    )

select
    /* primary key */
    datasets.urn as dataset_id

    /* timestamps */
    , datasets.entity_created_at as dataset_created_at

    /* flags */

    /* dataset details */ 
    , datasets.entity_type
    , dataset_details.detail_list[1] as dataset_name
      /* extract only the platform name */
    , dataset_details.detail_list[2][21:] as dataset_platform 
    , lower(dataset_details.detail_list[3]) as dataset_origin
    , lower(datasets.entity_created_by[8:]) as dataset_created_by

    /* dataset relationship json */
    , datasets.domains as dataset_domains
    , datasets.glossary_terms as dataset_glossary_terms
    , datasets.owners as dataset_owners

from datasets 
left join dataset_details on datasets.urn = dataset_details.urn