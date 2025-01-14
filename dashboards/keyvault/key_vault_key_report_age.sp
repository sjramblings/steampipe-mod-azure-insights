dashboard "key_vault_key_age_report" {

  title         = "Azure Key Vault Key Age Report"
  documentation = file("./dashboards/keyvault/docs/key_vault_key_report_age.md")


  tags = merge(local.keyvault_common_tags, {
    type     = "Report"
    category = "Age"
  })

  container {

    card {
      width = 2
      query = query.key_vault_key_count
    }

    card {
      type  = "info"
      width = 2
      query = query.key_vault_key_24_hours_count
    }

    card {
      type  = "info"
      width = 2
      query = query.key_vault_key_30_days_count
    }

    card {
      type  = "info"
      width = 2
      query = query.key_vault_key_30_90_days_count
    }

    card {
      type  = "info"
      width = 2
      query = query.key_vault_key_90_365_days_count
    }

    card {
      type  = "info"
      width = 2
      query = query.key_vault_key_1_year_count
    }

  }

  table {
    column "Subscription ID" {
      display = "none"
    }

    column "ID" {
      display = "none"
    }

    column "Name" {
      href = "${dashboard.key_vault_key_detail.url_path}?input.key_vault_key_id={{.'ID' | @uri}}"
    }

    column "Vault ID" {
      display = "none"
    }

    column "Vault Name" {
      href = "${dashboard.key_vault_detail.url_path}?input.key_vault_id={{.'Vault ID' | @uri}}"
    }

    query = query.key_vault_key_age_table
  }

}

query "key_vault_key_24_hours_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '< 24 hours' as label
    from
      azure_key_vault_key
    where
      created_at > now() - '1 days' :: interval;
  EOQ
}

query "key_vault_key_30_days_count" {
  sql = <<-EOQ
     select
      count(*) as value,
      '1-30 Days' as label
    from
      azure_key_vault_key
    where
      created_at between symmetric now() - '1 days' :: interval and now() - '30 days' :: interval;
  EOQ
}

query "key_vault_key_30_90_days_count" {
  sql = <<-EOQ
     select
      count(*) as value,
      '30-90 Days' as label
    from
      azure_key_vault_key
    where
      created_at between symmetric now() - '30 days' :: interval and now() - '90 days' :: interval;
  EOQ
}

query "key_vault_key_90_365_days_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '90-365 Days' as label
    from
      azure_key_vault_key
    where
      created_at between symmetric (now() - '90 days'::interval) and (now() - '365 days'::interval);
  EOQ
}

query "key_vault_key_1_year_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '> 1 Year' as label
    from
      azure_key_vault_key
    where
      created_at <= now() - '1 year' :: interval;
  EOQ
}

query "key_vault_key_age_table" {
  sql = <<-EOQ
    select
      k.name as "Name",
      now()::date - k.created_at::date as "Age in Days",
      k.created_at as "Creation Date",
      k.vault_name as "Vault Name",
      k.expires_at as "Key Expiration",
      k.key_size as "Key Size",
      k.key_type as "Key Type",
      sub.title as "Subscription",
      k.subscription_id as "Subscription ID",
      k.resource_group as "Resource Group",
      k.region as "Region",
      lower(k.id) as "ID",
      lower(v.id) as "Vault ID"
    from
      azure_key_vault_key as k
      left join azure_key_vault as v on v.name = k.vault_name,
      azure_subscription as sub
    where
      k.subscription_id = v.subscription_id
      and k.resource_group = v.resource_group
      and k.subscription_id = sub.subscription_id
    order by
      k.id;
  EOQ
}
