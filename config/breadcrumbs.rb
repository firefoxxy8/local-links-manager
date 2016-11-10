crumb :root do
  link "Local links", root_path
end

crumb :services do |local_authority|
  link local_authority.name, local_authority_path(local_authority.slug)
  parent :root
end

crumb :interactions do |local_authority, service|
  link service.label, interactions_path(local_authority.slug, service.slug)
  parent :services, local_authority
end

crumb :links do |local_authority, service, interaction|
  link interaction.label, interaction_links_path(local_authority.slug, service.slug, interaction.slug)
  parent :interactions, local_authority, service
end
