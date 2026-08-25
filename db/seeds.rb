# db/seeds.rb

puts "🌱 Starting GreenPilot seeds..."

ApplicationRecord.transaction do
  # ============================================================
  # ORGANIZATIONS
  # ============================================================

  organization_a = Organization.find_or_initialize_by(
    slug: "greenpilot-paysage"
  )

  organization_a.assign_attributes(
    name: "GreenPilot Paysage",
    description: "Entreprise de paysage et entretien des espaces verts.",
    email: "contact@greenpilot-paysage.fr",
    phone: "0388000001",
    address: "10 rue des Jardins",
    city: "Strasbourg",
    postal_code: "67000",
    country: "FR",
    timezone: "Europe/Paris",
    active: true
  )

  organization_a.save!

  organization_b = Organization.find_or_initialize_by(
    slug: "espaces-verts-alsace"
  )

  organization_b.assign_attributes(
    name: "Espaces Verts Alsace",
    description: "Entreprise spécialisée dans la création et l'aménagement paysager.",
    email: "contact@espaces-verts-alsace.fr",
    phone: "0388000002",
    address: "25 avenue des Espaces Verts",
    city: "Schiltigheim",
    postal_code: "67300",
    country: "FR",
    timezone: "Europe/Paris",
    active: true
  )

  organization_b.save!

  puts "✓ Organizations"

  # ============================================================
  # USERS
  # ============================================================

  users = {}

  seed_password = "GreenPilot2026!"

  users_data = [
    {
      key: :owner_a,
      organization: organization_a,
      email: "owner@greenpilot-paysage.fr",
      first_name: "Pierre",
      last_name: "Martin",
      phone: "0600000001",
      role: "owner"
    },
    {
      key: :admin_a,
      organization: organization_a,
      email: "admin@greenpilot-paysage.fr",
      first_name: "Sophie",
      last_name: "Bernard",
      phone: "0600000002",
      role: "admin"
    },
    {
      key: :manager_a,
      organization: organization_a,
      email: "manager@greenpilot-paysage.fr",
      first_name: "Thomas",
      last_name: "Dubois",
      phone: "0600000003",
      role: "manager"
    },
    {
      key: :accountant_a,
      organization: organization_a,
      email: "compta@greenpilot-paysage.fr",
      first_name: "Claire",
      last_name: "Robert",
      phone: "0600000004",
      role: "accountant"
    },
    {
      key: :field_worker_a,
      organization: organization_a,
      email: "terrain@greenpilot-paysage.fr",
      first_name: "Lucas",
      last_name: "Petit",
      phone: "0600000005",
      role: "field_worker"
    },
    {
      key: :member_a,
      organization: organization_a,
      email: "member@greenpilot-paysage.fr",
      first_name: "Emma",
      last_name: "Richard",
      phone: "0600000006",
      role: "member"
    },
    {
      key: :manager_b,
      organization: organization_b,
      email: "manager@espaces-verts-alsace.fr",
      first_name: "Nicolas",
      last_name: "Moreau",
      phone: "0600000007",
      role: "manager"
    },
    {
      key: :member_b,
      organization: organization_b,
      email: "member@espaces-verts-alsace.fr",
      first_name: "Julie",
      last_name: "Simon",
      phone: "0600000008",
      role: "member"
    }
  ]

  users_data.each do |data|
    key = data.delete(:key)

    user = User.find_or_initialize_by(email: data[:email])

    user.assign_attributes(
      data.merge(
        password: seed_password,
        password_confirmation: seed_password
      )
    )

    user.active = true
    user.save!

    users[key] = user
  end

  puts "✓ Users"

  # ============================================================
  # CUSTOMERS
  # ============================================================

  customers = {}

  customer_a = Customer.find_or_initialize_by(
    organization: organization_a,
    email: "contact@jardin-alsace.fr"
  )

  customer_a.assign_attributes(
    customer_type: "company",
    company_name: "Jardin Alsace",
    first_name: "Marc",
    last_name: "Leroy",
    phone: "0388010001",
    mobile: "0601000001",
    notes: "Client professionnel principal.",
    active: true
  )

  customer_a.save!
  customers[:customer_a] = customer_a

  customer_b = Customer.find_or_initialize_by(
    organization: organization_b,
    email: "contact@vertesolutions.fr"
  )

  customer_b.assign_attributes(
    customer_type: "company",
    company_name: "Verte Solutions",
    first_name: "Anne",
    last_name: "Garcia",
    phone: "0388010002",
    mobile: "0601000002",
    notes: "Client entreprise pour projets d'aménagement.",
    active: true
  )

  customer_b.save!
  customers[:customer_b] = customer_b

  puts "✓ Customers"

  # ============================================================
  # SITES
  # ============================================================

  sites = {}

  site_a = Site.find_or_initialize_by(
    organization: organization_a,
    name: "Jardin principal - Jardin Alsace"
  )

  site_a.assign_attributes(
    customer: customer_a,
    address_line1: "15 rue des Fleurs",
    address_line2: nil,
    city: "Strasbourg",
    postal_code: "67000",
    country: "FR",
    site_type: "residential",
    surface_area: 1200.0,
    latitude: 48.5734,
    longitude: 7.7521,
    notes: "Grand jardin avec pelouse et massifs.",
    active: true
  )

  site_a.save!
  sites[:site_a] = site_a

  site_b = Site.find_or_initialize_by(
    organization: organization_b,
    name: "Projet espace vert - Verte Solutions"
  )

  site_b.assign_attributes(
    customer: customer_b,
    address_line1: "40 route de Bischwiller",
    address_line2: nil,
    city: "Schiltigheim",
    postal_code: "67300",
    country: "FR",
    site_type: "commercial",
    surface_area: 3500.0,
    latitude: 48.6167,
    longitude: 7.7500,
    notes: "Site professionnel destiné à un projet d'aménagement.",
    active: true
  )

  site_b.save!
  sites[:site_b] = site_b

  puts "✓ Sites"

  # ============================================================
  # SERVICE CATEGORIES
  # ============================================================

  categories = {}

  category_a = ServiceCategory.find_or_initialize_by(
    organization: organization_a,
    code: "ENT"
  )

  category_a.assign_attributes(
    name: "Entretien des espaces verts",
    description: "Travaux réguliers d'entretien des jardins et espaces verts.",
    category_type: "maintenance",
    position: 1,
    active: true
  )

  category_a.save!
  categories[:category_a] = category_a

  category_b = ServiceCategory.find_or_initialize_by(
    organization: organization_b,
    code: "CRE"
  )

  category_b.assign_attributes(
    name: "Création paysagère",
    description: "Création et aménagement d'espaces verts.",
    category_type: "creation",
    position: 1,
    active: true
  )

  category_b.save!
  categories[:category_b] = category_b

  puts "✓ Service categories"

  # ============================================================
  # SERVICE ITEMS
  # ============================================================

  service_items = {}

  item_a = ServiceItem.find_or_initialize_by(
    organization: organization_a,
    code: "TON"
  )

  item_a.assign_attributes(
    service_category: category_a,
    name: "Tonte de pelouse",
    description: "Tonte professionnelle des espaces verts",
    unit: "m2",
    default_quantity: 100.000,
    default_unit_price: 0.80,
    default_margin_percentage: 30.00,
    labor_cost: 40.00,
    material_cost: 5.00,
    equipment_cost: 10.00,
    overhead_cost: 8.00,
    estimated_duration_minutes: 60,
    position: 1,
    active: true
  )

  item_a.save!
  service_items[:item_a] = item_a

  item_b = ServiceItem.find_or_initialize_by(
    organization: organization_b,
    code: "CRE"
  )

  item_b.assign_attributes(
    service_category: category_b,
    name: "Création d'espace vert",
    description: "Création et aménagement d'espace vert",
    unit: "m2",
    default_quantity: 100.000,
    default_unit_price: 25.00,
    default_margin_percentage: 35.00,
    labor_cost: 500.00,
    material_cost: 800.00,
    equipment_cost: 100.00,
    overhead_cost: 150.00,
    estimated_duration_minutes: 480,
    position: 1,
    active: true
  )

  item_b.save!
  service_items[:item_b] = item_b

  puts "✓ Service items"

  # ============================================================
  # TEAMS
  # ============================================================

  teams = {}

  team_a = Team.find_or_initialize_by(
    organization: organization_a,
    code: "TEAM-A"
  )

  team_a.assign_attributes(
    name: "Équipe Entretien",
    description: "Équipe dédiée aux opérations d'entretien.",
    color: "#22C55E",
    active: true
  )

  team_a.save!
  teams[:team_a] = team_a

  team_b = Team.find_or_initialize_by(
    organization: organization_b,
    code: "TEAM-B"
  )

  team_b.assign_attributes(
    name: "Équipe Création",
    description: "Équipe dédiée aux projets de création paysagère.",
    color: "#3B82F6",
    active: true
  )

  team_b.save!
  teams[:team_b] = team_b

  puts "✓ Teams"

  # ============================================================
  # TEAM MEMBERSHIPS
  # ============================================================

  membership_a = TeamMembership.find_or_initialize_by(
    team: team_a,
    user: users[:field_worker_a]
  )

  membership_a.assign_attributes(
    organization: organization_a,
    role: "member",
    active: true,
    start_date: Date.current - 180.days
  )

  membership_a.save!

  membership_manager = TeamMembership.find_or_initialize_by(
    team: team_a,
    user: users[:manager_a]
  )

  membership_manager.assign_attributes(
    organization: organization_a,
    role: "manager",
    active: true,
    start_date: Date.current - 365.days
  )

  membership_manager.save!

  membership_b = TeamMembership.find_or_initialize_by(
    team: team_b,
    user: users[:manager_b]
  )

  membership_b.assign_attributes(
    organization: organization_b,
    role: "manager",
    active: true,
    start_date: Date.current - 365.days
  )

  membership_b.save!

  puts "✓ Team memberships"

  # ============================================================
  # VEHICLES
  # ============================================================

  vehicles = {}

  vehicle_a = Vehicle.find_or_initialize_by(
    organization: organization_a,
    registration_number: "AA-001-AA"
  )

  vehicle_a.assign_attributes(
    name: "Utilitaire Paysage 01",
    brand: "Renault",
    model: "Master",
    vehicle_type: "van",
    fuel_type: "diesel",
    capacity: 1200.0,
    fuel_consumption: 8.5,
    year: 2024,
    active: true,
    notes: "Véhicule principal de l'équipe terrain."
  )

  vehicle_a.save!
  vehicles[:vehicle_a] = vehicle_a

  vehicle_b = Vehicle.find_or_initialize_by(
    organization: organization_b,
    registration_number: "BB-002-BB"
  )

  vehicle_b.assign_attributes(
    name: "Utilitaire Création 01",
    brand: "Peugeot",
    model: "Boxer",
    vehicle_type: "van",
    fuel_type: "diesel",
    capacity: 1500.0,
    fuel_consumption: 9.0,
    year: 2023,
    active: true,
    notes: "Véhicule dédié aux projets de création."
  )

  vehicle_b.save!
  vehicles[:vehicle_b] = vehicle_b

  puts "✓ Vehicles"

  # ============================================================
  # EQUIPMENT
  # ============================================================

  equipment_a = Equipment.find_or_initialize_by(
    organization: organization_a,
    name: "Tondeuse professionnelle"
  )

  equipment_a.assign_attributes(
    equipment_type: "mower",
    brand: "Honda",
    model: "HRX",
    serial_number: "GP-MOWER-001",
    purchase_date: Date.current - 365.days,
    purchase_price: 2500.00,
    status: "available",
    active: true,
    maintenance_interval_days: 90,
    last_maintenance_at: Date.current - 20.days,
    next_maintenance_at: Date.current + 70.days,
    notes: "Tondeuse principale."
  )

  equipment_a.save!

  equipment_b = Equipment.find_or_initialize_by(
    organization: organization_b,
    name: "Taille-haie professionnel"
  )

  equipment_b.assign_attributes(
    equipment_type: "hedge_trimmer",
    brand: "Stihl",
    model: "HS 82",
    serial_number: "GP-HEDGE-001",
    purchase_date: Date.current - 240.days,
    purchase_price: 850.00,
    status: "available",
    active: true,
    maintenance_interval_days: 90,
    last_maintenance_at: Date.current - 15.days,
    next_maintenance_at: Date.current + 75.days,
    notes: "Matériel utilisé pour les opérations de taille."
  )

  equipment_b.save!

  puts "✓ Equipment"

  # ============================================================
  # QUOTES
  # ============================================================

  quotes = {}

  quote_a = Quote.find_or_initialize_by(
    organization: organization_a,
    number: "DEV-2026-0001"
  )

  quote_a.assign_attributes(
    customer: customer_a,
    site: site_a,
    title: "Entretien annuel du jardin",
    description: "Programme annuel d'entretien des espaces verts.",
    issue_date: Date.current - 15.days,
    valid_until: Date.current + 15.days,
    status: "accepted",
    subtotal: 800.00,
    discount_amount: 0.00,
    tax_amount: 160.00,
    total_amount: 960.00,
    estimated_cost: 560.00,
    estimated_margin_amount: 240.00,
    estimated_margin_percentage: 30.00,
    notes: "Devis accepté par le client.",
    accepted_at: Date.current - 10.days
  )

  quote_a.save!
  quotes[:quote_a] = quote_a

  quote_b = Quote.find_or_initialize_by(
    organization: organization_b,
    number: "DEV-2026-0002"
  )

  quote_b.assign_attributes(
    customer: customer_b,
    site: site_b,
    title: "Création d'espace vert",
    description: "Création complète d'un espace paysager.",
    issue_date: Date.current - 10.days,
    valid_until: Date.current + 20.days,
    status: "accepted",
    subtotal: 2500.00,
    discount_amount: 0.00,
    tax_amount: 500.00,
    total_amount: 3000.00,
    estimated_cost: 1625.00,
    estimated_margin_amount: 875.00,
    estimated_margin_percentage: 35.00,
    notes: "Projet de création accepté.",
    accepted_at: Date.current - 5.days
  )

  quote_b.save!
  quotes[:quote_b] = quote_b

  puts "✓ Quotes"

  # ============================================================
  # QUOTE ITEMS
  # ============================================================

  quote_item_a = QuoteItem.find_or_initialize_by(
    quote: quote_a,
    position: 1
  )

  quote_item_a.assign_attributes(
    service_item: item_a,
    description: "Tonte professionnelle des espaces verts",
    quantity: 100.000,
    unit: "m2",
    unit_price: 0.80,
    discount_percentage: 0.00,
    tax_rate: 20.00,
    subtotal: 80.00,
    tax_amount: 16.00,
    total_amount: 96.00,
    labor_cost: 40.00,
    material_cost: 5.00,
    equipment_cost: 10.00,
    estimated_cost: 55.00,
    margin_amount: 25.00,
    margin_percentage: 31.25,
    estimated_duration_minutes: 60
  )

  quote_item_a.save!

  quote_item_b = QuoteItem.find_or_initialize_by(
    quote: quote_b,
    position: 1
  )

  quote_item_b.assign_attributes(
    service_item: item_b,
    description: "Création et aménagement d'espace vert",
    quantity: 100.000,
    unit: "m2",
    unit_price: 25.00,
    discount_percentage: 0.00,
    tax_rate: 20.00,
    subtotal: 2500.00,
    tax_amount: 500.00,
    total_amount: 3000.00,
    labor_cost: 500.00,
    material_cost: 800.00,
    equipment_cost: 100.00,
    estimated_cost: 1625.00,
    margin_amount: 875.00,
    margin_percentage: 35.00,
    estimated_duration_minutes: 480
  )

  quote_item_b.save!

  puts "✓ Quote items"

  # ============================================================
  # JOBS
  # ============================================================

  jobs = {}

  job_a = Job.find_or_initialize_by(
    organization: organization_a,
    title: "Entretien jardin principal"
  )

  job_a.assign_attributes(
    customer: customer_a,
    site: site_a,
    quote: quote_a,
    team: team_a,
    vehicle: vehicle_a,
    job_type: "maintenance",
    description: "Tonte et entretien général du jardin.",
    customer_notes: "Accès par le portail principal.",
    internal_notes: "Prévoir la tondeuse professionnelle.",
    address: site_a.address_line1,
    scheduled_date: Date.current,
    scheduled_start_at: Time.zone.parse("2026-08-22 08:00"),
    scheduled_end_at: Time.zone.parse("2026-08-22 10:00"),
    estimated_duration_minutes: 120,
    actual_duration_minutes: 110,
    status: "completed",
    priority: "normal",
    started_at: Time.zone.parse("2026-08-22 08:05"),
    completed_at: Time.zone.parse("2026-08-22 09:55"),
    travel_distance_km: 8.5,
    travel_duration_minutes: 20,
    weather_risk: "low",
    weather_notes: "Conditions favorables.",
    #active: true
  )

  # `active` n'existe pas dans jobs selon le schema.
  job_a.attributes.delete("active")

  job_a.save!
  jobs[:job_a] = job_a

  job_b = Job.find_or_initialize_by(
    organization: organization_b,
    title: "Création espace vert"
  )

  job_b.assign_attributes(
    customer: customer_b,
    site: site_b,
    quote: quote_b,
    team: team_b,
    vehicle: vehicle_b,
    job_type: "creation",
    description: "Création complète de l'espace vert.",
    customer_notes: "Travaux à réaliser en journée.",
    internal_notes: "Prévoir matériel de création.",
    address: site_b.address_line1,
    scheduled_date: Date.current,
    scheduled_start_at: Time.zone.parse("2026-08-22 08:00"),
    scheduled_end_at: Time.zone.parse("2026-08-22 16:00"),
    estimated_duration_minutes: 480,
    status: "planned",
    priority: "high",
    weather_risk: "unknown"
  )

  job_b.save!
  jobs[:job_b] = job_b

  puts "✓ Jobs"

  # ============================================================
  # JOB ASSIGNMENTS
  # ============================================================

  assignment_a = JobAssignment.find_or_initialize_by(
    job: job_a,
    user: users[:field_worker_a]
  )

  assignment_a.assign_attributes(
    organization: organization_a,
    assignment_type: "primary",
    role: "worker",
    #active: true,
    assigned_at: Time.zone.parse("2026-08-22 07:45"),
    accepted_at: Time.zone.parse("2026-08-22 07:50"),
    completed_at: Time.zone.parse("2026-08-22 10:00"),
    notes: "Intervention principale."
  )

  assignment_a.save!

  assignment_b = JobAssignment.find_or_initialize_by(
    job: job_b,
    user: users[:manager_b]
  )

  assignment_b.assign_attributes(
    organization: organization_b,
    assignment_type: "primary",
    role: "manager",
    #active: true,
    assigned_at: Time.zone.parse("2026-08-22 07:45"),
    accepted_at: Time.zone.parse("2026-08-22 07:50"),
    notes: "Responsable du projet."
  )

  assignment_b.save!

  puts "✓ Job assignments"

  # ============================================================
  # JOB TIME ENTRIES
  # ============================================================

  time_entry_a = JobTimeEntry.find_or_initialize_by(
    job: job_a,
    user: users[:field_worker_a],
    started_at: Time.zone.parse("2026-08-22 08:05")
  )

  time_entry_a.assign_attributes(
    organization: organization_a,
    entry_type: "work",
    ended_at: Time.zone.parse("2026-08-22 09:55"),
    duration_minutes: 110,
    notes: "Tonte et nettoyage du site."
  )

  time_entry_a.save!

  time_entry_b = JobTimeEntry.find_or_initialize_by(
    job: job_b,
    user: users[:manager_b],
    started_at: Time.zone.parse("2026-08-22 08:00")
  )

  time_entry_b.assign_attributes(
    organization: organization_b,
    entry_type: "work",
    ended_at: nil,
    duration_minutes: nil,
    notes: "Démarrage du chantier."
  )

  time_entry_b.save!

  puts "✓ Job time entries"

  # ============================================================
  # JOB REPORTS
  # ============================================================

  report_a = JobReport.find_or_initialize_by(
    job: job_a
  )

  report_a.assign_attributes(
    organization: organization_a,
    summary: "Entretien du jardin terminé.",
    work_performed: "Tonte complète de la pelouse et nettoyage des abords.",
    observations: "Pelouse en bon état général.",
    recommendations: "Prévoir une nouvelle tonte dans deux semaines.",
    generated_at: Time.current,
    customer_signature: "Marc Leroy",
    customer_signed_at: Time.current,
    sent_to_customer_at: Time.current
  )

  report_a.save!

  report_b = JobReport.find_or_initialize_by(
    job: job_b
  )

  report_b.assign_attributes(
    organization: organization_b,
    summary: "Projet de création en cours.",
    work_performed: "Préparation initiale du terrain.",
    observations: "Terrain prêt pour les prochaines étapes.",
    recommendations: "Poursuivre les travaux selon le planning.",
    generated_at: nil,
    sent_to_customer_at: nil
  )

  report_b.save!

  puts "✓ Job reports"

  # ============================================================
  # INVOICES
  # ============================================================

  invoices = {}

  invoice_a = Invoice.find_or_initialize_by(
    organization: organization_a,
    number: "INV-2026-0001"
  )

  invoice_a.assign_attributes(
    customer: customer_a,
    job: job_a,
    quote: quote_a,
    site: site_a,
    issue_date: Date.current,
    due_date: Date.current + 30.days,
    status: "issued",
    subtotal: 1000.00,
    discount_amount: 0.00,
    tax_amount: 200.00,
    total_amount: 1200.00,
    amount_paid: 0.00,
    amount_due: 1200.00,
    notes: "Facture entretien jardin principal."
  )

  invoice_a.save!
  invoices[:invoice_a] = invoice_a

  invoice_b = Invoice.find_or_initialize_by(
    organization: organization_b,
    number: "INV-2026-0002"
  )

  invoice_b.assign_attributes(
    customer: customer_b,
    job: job_b,
    quote: quote_b,
    site: site_b,
    issue_date: Date.current,
    due_date: Date.current + 30.days,
    status: "issued",
    subtotal: 2000.00,
    discount_amount: 0.00,
    tax_amount: 400.00,
    total_amount: 2400.00,
    amount_paid: 0.00,
    amount_due: 2400.00,
    notes: "Facture création espace vert."
  )

  invoice_b.save!
  invoices[:invoice_b] = invoice_b

  puts "✓ Invoices"

  # ============================================================
  # INVOICE ITEMS
  # ============================================================

  invoice_item_a = InvoiceItem.find_or_initialize_by(
    invoice: invoice_a,
    position: 1
  )

  invoice_item_a.assign_attributes(
    service_item: item_a,
    description: "Tonte professionnelle des espaces verts",
    quantity: 100.000,
    unit: "m2",
    unit_price: 10.00,
    discount_percentage: 0.00,
    tax_rate: 20.00,
    subtotal: 1000.00,
    tax_amount: 200.00,
    total_amount: 1200.00
  )

  invoice_item_a.save!

  invoice_item_b = InvoiceItem.find_or_initialize_by(
    invoice: invoice_b,
    position: 1
  )

  invoice_item_b.assign_attributes(
    service_item: item_b,
    description: "Création et aménagement d'espace vert",
    quantity: 80.000,
    unit: "m2",
    unit_price: 25.00,
    discount_percentage: 0.00,
    tax_rate: 20.00,
    subtotal: 2000.00,
    tax_amount: 400.00,
    total_amount: 2400.00
  )

  invoice_item_b.save!

  puts "✓ Invoice items"

  # ============================================================
  # SUMMARY
  # ============================================================

  puts
  puts "=============================================="
  puts "🌱 GreenPilot seed completed successfully!"
  puts "=============================================="
  puts "Organizations:     #{Organization.count}"
  puts "Users:             #{User.count}"
  puts "Customers:         #{Customer.count}"
  puts "Sites:             #{Site.count}"
  puts "Categories:        #{ServiceCategory.count}"
  puts "Service items:     #{ServiceItem.count}"
  puts "Teams:             #{Team.count}"
  puts "Memberships:       #{TeamMembership.count}"
  puts "Vehicles:          #{Vehicle.count}"
  puts "Equipment:         #{Equipment.count}"
  puts "Quotes:            #{Quote.count}"
  puts "Quote items:       #{QuoteItem.count}"
  puts "Jobs:              #{Job.count}"
  puts "Assignments:       #{JobAssignment.count}"
  puts "Time entries:      #{JobTimeEntry.count}"
  puts "Reports:           #{JobReport.count}"
  puts "Invoices:          #{Invoice.count}"
  puts "Invoice items:     #{InvoiceItem.count}"
  puts "=============================================="
end