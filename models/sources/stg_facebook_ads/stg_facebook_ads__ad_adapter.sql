{% if var("attribution_warehouse_ad_sources") %}
{% if 'facebook_ads' in var("attribution_warehouse_ad_sources") %}

with report as (

    select *
    from {{ ref('stg_facebook_ads__basic_ad') }}

), creatives as (

    select *
    from {{ ref('stg_facebook_ads__creative_history_prep') }}

), accounts as (

    select *
    from {{ ref('stg_facebook_ads__account_history') }}
    where is_most_recent_record = true

), ads as (

    select *
    from {{ ref('stg_facebook_ads__ad_history') }}
    where is_most_recent_record = true

), ad_sets as (

    select *
    from {{ ref('stg_facebook_ads__ad_set_history') }}
    where is_most_recent_record = true

), campaigns as (

    select *
    from {{ ref('stg_facebook_ads__campaign_history') }}
    where is_most_recent_record = true

), currency_rates as (

    select *
    from {{ ref('stg_currency_rates') }}

), joined as (

    select
        report.date_day,
        accounts.account_id,
        accounts.account_name,
        accounts.local_currency,
        campaigns.campaign_id,
        campaigns.campaign_name,
        ad_sets.ad_set_id,
        ad_sets.ad_set_name,
        ads.ad_id,
        ads.ad_name,
        creatives.creative_id,
        creatives.creative_name,
        creatives.base_url,
        creatives.url_host,
        creatives.url_path,
        creatives.utm_source,
        creatives.utm_medium,
        creatives.utm_campaign,
        creatives.utm_content,
        creatives.utm_term,
        creatives.fbclid,
        sum(report.clicks) as clicks,
        sum(report.impressions) as impressions,
        sum(report.spend) as spend_local_currency,
        sum({{ convert_amount_to_global_currency('report.spend', 'accounts.local_currency', 'currency_rates.currency_rate') }}) as spend_global_currency
    from report
    left join ads
        on cast(report.ad_id as {{ dbt_utils.type_bigint() }}) = cast(ads.ad_id as {{ dbt_utils.type_bigint() }})
    left join creatives
        on cast(ads.creative_id as {{ dbt_utils.type_bigint() }}) = cast(creatives.creative_id as {{ dbt_utils.type_bigint() }})
    left join ad_sets
        on cast(ads.ad_set_id as {{ dbt_utils.type_bigint() }}) = cast(ad_sets.ad_set_id as {{ dbt_utils.type_bigint() }})
    left join campaigns
        on cast(ads.campaign_id as {{ dbt_utils.type_bigint() }}) = cast(campaigns.campaign_id as {{ dbt_utils.type_bigint() }})
    left join accounts
        on cast(report.account_id as {{ dbt_utils.type_bigint() }}) = cast(accounts.account_id as {{ dbt_utils.type_bigint() }})
    left join currency_rates
        on accounts.local_currency = currency_rates.base_currency_code
        and currency_rates.quote_currency_code = '{{ var('attribution_global_currency') }}'
        and report.date_day = currency_rates.currency_rate_date
    {{ dbt_utils.group_by(21) }}


)

select *
from joined

{% else %} {{config(enabled=false)}} {% endif %}
{% else %} {{config(enabled=false)}} {% endif %}
