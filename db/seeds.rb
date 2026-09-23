# db/seeds.rb

require "bigdecimal"

puts
puts "============================================================"
puts " GREENPILOT DEMO SEED"
puts "============================================================"
puts

ApplicationRecord.transaction do
  today = Date.current
  now = Time.zone.now

  seed_password = "GreenPilot2026!"

  # ============================================================
  # HELPERS
  # ============================================================

  money = ->(value) { BigDecimal(value.to_s) }

  datetime = lambda do |date, hour = 8, minute = 0|
    Time.zone.local(date.year, date.month, date.day, hour, minute)
  end

  valid_inclusion_values = lambda do |model, attribute|
    validator = model.validators_on(attribute).find do |item|
      item.is_a?(ActiveModel::Validations::InclusionValidator)
    end

    next [] unless validator

    values = validator.options[:in]

    values.respond_to?(:call) ? Array(values.call) : Array(values)
  end

  job_status_values = valid_inclusion_values.call(Job, :status)
  job_priority_values = valid_inclusion_values.call(Job, :priority)
  job_weather_values = valid_inclusion_values.call(Job, :weather_risk)

  job_status_values = job_status_values.map(&:to_s)
  job_priority_values = job_priority_values.map(&:to_s)
  job_weather_values = job_weather_values.map(&:to_s)

  pick_value = lambda do |values, preferred, fallback|
    preferred = preferred.to_s

    if values.include?(preferred)
      preferred
    else
      values.first || fallback
    end
  end

  status_planned = pick_value.call(job_status_values, "planned", "planned")
  status_scheduled = pick_value.call(job_status_values, "scheduled", status_planned)
  status_in_progress = pick_value.call(job_status_values, "in_progress", status_scheduled)
  status_completed = pick_value.call(job_status_values, "completed", status_scheduled)
  status_cancelled = pick_value.call(job_status_values, "cancelled", status_planned)

  priority_low = pick_value.call(job_priority_values, "low", "normal")
  priority_normal = pick_value.call(job_priority_values, "normal", "normal")
  priority_high = pick_value.call(job_priority_values, "high", "normal")
  priority_urgent = pick_value.call(job_priority_values, "urgent", priority_high)

  weather_low = pick_value.call(job_weather_values, "low", "unknown")
  weather_medium = pick_value.call(job_weather_values, "medium", weather_low)
  weather_high = pick_value.call(job_weather_values, "high", weather_medium)
  weather_unknown = pick_value.call(job_weather_values, "unknown", weather_low)

  puts "Job statuses detected: #{job_status_values.join(", ")}"
  puts "Job priorities detected: #{job_priority_values.join(", ")}"
  puts "Weather risks detected: #{job_weather_values.join(", ")}"
  puts

  # ============================================================
  # ORGANIZATION
  # ============================================================

  organization = Organization.find_or_initialize_by(
    slug: "greenpilot-paysage"
  )

  organization.assign_attributes(
    name: "GreenPilot Paysage",
    description: "Entreprise de paysage, entretien des espaces verts et aménagement extérieur.",
    email: "contact@greenpilot-paysage.fr",
    phone: "0388000001",
    address: "10 rue des Jardins",
    city: "Strasbourg",
    postal_code: "67000",
    country: "FR",
    timezone: "Europe/Paris",
    active: true
  )

  organization.save!

  puts "✓ Organization"

  # ============================================================
  # USERS
  # ============================================================

  users = {}

  users_data = [
    {
      key: :owner,
      email: "owner@greenpilot-paysage.fr",
      first_name: "Pierre",
      last_name: "Martin",
      phone: "0612034311",
      role: "owner"
    },
    {
      key: :admin,
      email: "admin@greenpilot-paysage.fr",
      first_name: "Sophie",
      last_name: "Bernard",
      phone: "0640030392",
      role: "admin"
    },
    {
      key: :manager,
      email: "manager@greenpilot-paysage.fr",
      first_name: "Thomas",
      last_name: "Dubois",
      phone: "0647012033",
      role: "manager"
    },
    {
      key: :accountant,
      email: "compta@greenpilot-paysage.fr",
      first_name: "Claire",
      last_name: "Robert",
      phone: "0600000004",
      role: "accountant"
    },
    {
      key: :field_worker_1,
      email: "terrain1@greenpilot-paysage.fr",
      first_name: "Lucas",
      last_name: "Petit",
      phone: "0600000005",
      role: "field_worker"
    },
    {
      key: :field_worker_2,
      email: "terrain2@greenpilot-paysage.fr",
      first_name: "Emma",
      last_name: "Richard",
      phone: "0600000006",
      role: "field_worker"
    },
    {
      key: :member,
      email: "member@greenpilot-paysage.fr",
      first_name: "Julien",
      last_name: "Lefèvre",
      phone: "0600000007",
      role: "member"
    }
  ]

  users_data.each do |data|
    key = data[:key]

    user = User.find_or_initialize_by(
      email: data[:email]
    )

    user.assign_attributes(
      organization: organization,
      email: data[:email],
      first_name: data[:first_name],
      last_name: data[:last_name],
      phone: data[:phone],
      role: data[:role],
      active: true,
      password: seed_password,
      password_confirmation: seed_password
    )

    user.save!

    users[key] = user
  end

  puts "✓ Users: #{users.count}"

  # ============================================================
  # CUSTOMERS
  # ============================================================

  customers = []

  customer_data = [
    ["Alsace Patrimoine", "Marc", "Leroy", "marc.leroy@alsace-patrimoine.fr", "0388010001", "0601000001", "company"],
    ["Résidence Les Tilleuls", "Anne", "Martin", "anne.martin@example.fr", "0388010002", "0601000002", "company"],
    ["Hôtel des Vosges", "Nathalie", "Schmitt", "n.schmitt@hotel-vosges.fr", "0388010003", "0601000003", "company"],
    ["Cabinet Horizon", "Laurent", "Muller", "laurent.muller@horizon.fr", "0388010004", "0601000004", "company"],
    ["Restaurant Le Jardin", "Paul", "Weber", "paul.weber@lejardin.fr", "0388010005", "0601000005", "company"],
    ["Villa Strasbourg", "Claire", "Fischer", "claire.fischer@example.fr", "0388010006", "0601000006", "individual"],
    ["Famille Bernard", "Jean", "Bernard", "jean.bernard@example.fr", "0388010007", "0601000007", "individual"],
    ["Famille Meyer", "Sophie", "Meyer", "sophie.meyer@example.fr", "0388010008", "0601000008", "individual"],
    ["Maison Klein", "Thomas", "Klein", "thomas.klein@example.fr", "0388010009", "0601000009", "individual"],
    ["Groupe Immobilier Est", "Olivier", "Roux", "olivier.roux@gie.fr", "0388010010", "0601000010", "company"],
    ["Résidence Bellevue", "Isabelle", "Simon", "isabelle.simon@example.fr", "0388010011", "0601000011", "company"],
    ["Clinique Sainte-Marie", "Élodie", "Robert", "elodie.robert@clinique.fr", "0388010012", "0601000012", "company"],
    ["Bureau Alsace Conseil", "François", "Moreau", "francois.moreau@alsaceconseil.fr", "0388010013", "0601000013", "company"],
    ["Agence Immobilière Centre", "Julie", "Garcia", "julie.garcia@agence-centre.fr", "0388010014", "0601000014", "company"],
    ["Maison Dupont", "Nicolas", "Dupont", "nicolas.dupont@example.fr", "0388010015", "0601000015", "individual"],
    ["Famille Wagner", "Caroline", "Wagner", "caroline.wagner@example.fr", "0388010016", "0601000016", "individual"],
    ["Campus Strasbourg", "Vincent", "Faure", "vincent.faure@campus.fr", "0388010017", "0601000017", "company"],
    ["Espace Médical Alsace", "Sandrine", "Giraud", "sandrine.giraud@medical.fr", "0388010018", "0601000018", "company"],
    ["Maison du Parc", "Philippe", "Chevalier", "philippe.chevalier@example.fr", "0388010019", "0601000019", "individual"],
    ["Boulangerie des Halles", "Amélie", "Bonnet", "amelie.bonnet@boulangerie.fr", "0388010020", "0601000020", "company"],
    ["Résidence du Canal", "Hugo", "Blanc", "hugo.blanc@example.fr", "0388010021", "0601000021", "company"],
    ["Atelier Créatif", "Marion", "Gauthier", "marion.gauthier@atelier.fr", "0388010022", "0601000022", "company"],
    ["Famille Schaeffer", "Arnaud", "Schaeffer", "arnaud.schaeffer@example.fr", "0388010023", "0601000023", "individual"],
    ["Domaine de l'Orangerie", "Céline", "Lemaire", "celine.lemaire@orangerie.fr", "0388010024", "0601000024", "company"]
  ]

  customer_data.each_with_index do |data, index|
    company_name = data[6] == "company" ? data[0] : nil

    customer = Customer.find_or_initialize_by(
      organization: organization,
      email: data[3]
    )

    customer.assign_attributes(
      customer_type: data[6],
      company_name: company_name,
      first_name: data[1],
      last_name: data[2],
      phone: data[4],
      mobile: data[5],
      notes: "Client GreenPilot ##{index + 1}.",
      active: index != 22
    )

    customer.save!
    customers << customer
  end

  puts "✓ Customers: #{customers.count}"

  # ============================================================
  # SITES
  # ============================================================

  sites = []

  site_templates = [
    ["Jardin principal", "15 rue des Fleurs", "Strasbourg", "67000", "residential", 1200.0],
    ["Siège social", "22 avenue des Vosges", "Strasbourg", "67000", "commercial", 850.0],
    ["Espace extérieur", "40 route de Bischwiller", "Schiltigheim", "67300", "commercial", 3500.0],
    ["Jardin arrière", "8 rue des Jardins", "Bischheim", "67800", "residential", 650.0],
    ["Parking végétalisé", "12 rue du Commerce", "Strasbourg", "67100", "commercial", 1800.0],
    ["Parc principal", "5 avenue de l'Europe", "Illkirch-Graffenstaden", "67400", "commercial", 5200.0],
    ["Maison principale", "17 rue des Roses", "Ostwald", "67540", "residential", 900.0],
    ["Terrasse et jardin", "31 rue du Parc", "Lingolsheim", "67380", "residential", 720.0],
    ["Domaine", "2 route de la Forêt", "Mundolsheim", "67450", "residential", 4800.0],
    ["Entrée principale", "18 rue du Centre", "Hœnheim", "67800", "commercial", 1100.0],
    ["Espace accueil", "9 rue de la Gare", "Vendenheim", "67550", "commercial", 1400.0],
    ["Cour intérieure", "25 rue Nationale", "Geispolsheim", "67118", "commercial", 600.0],
    ["Jardin familial", "7 rue des Acacias", "Eckbolsheim", "67201", "residential", 780.0],
    ["Maison secondaire", "44 rue des Prés", "Oberhausbergen", "67205", "residential", 1350.0],
    ["Complexe professionnel", "60 avenue de Strasbourg", "Entzheim", "67960", "commercial", 6200.0],
    ["Parc paysager", "4 rue du Château", "Molsheim", "67120", "commercial", 7600.0],
    ["Résidence principale", "14 rue Bellevue", "Saverne", "67700", "residential", 1600.0],
    ["Jardin avant", "3 rue des Lilas", "Barr", "67140", "residential", 950.0],
    ["Zone d'accueil", "10 rue du Stade", "Obernai", "67210", "commercial", 2100.0],
    ["Espace vert", "16 route de Colmar", "Sélestat", "67600", "commercial", 3300.0],
    ["Terrasse", "21 rue des Vignes", "Rosheim", "67560", "residential", 550.0],
    ["Parc entreprise", "33 rue de l'Industrie", "Duttlenheim", "67120", "commercial", 4500.0],
    ["Jardin privé", "6 rue du Moulin", "Mittelhausbergen", "67206", "residential", 1000.0],
    ["Centre administratif", "50 rue de la République", "Strasbourg", "67000", "commercial", 2700.0],
    ["Domaine extérieur", "12 chemin du Lac", "Plobsheim", "67115", "residential", 3900.0],
    ["Jardin clients", "19 rue des Écoles", "Brumath", "67170", "commercial", 1700.0],
    ["Espace détente", "28 rue de la Paix", "La Wantzenau", "67610", "residential", 1150.0],
    ["Jardin principal", "41 rue des Champs", "Hoerdt", "67720", "residential", 2400.0],
    ["Site logistique", "55 rue des Entreprises", "Haguenau", "67500", "commercial", 8900.0],
    ["Maison du parc", "8 chemin des Bois", "Wasselonne", "67310", "residential", 3100.0],
    ["Domaine de l'Orangerie", "1 route de l'Orangerie", "Strasbourg", "67000", "commercial", 5400.0]
  ]

  site_templates.each_with_index do |template, index|
    customer = customers[index % customers.length]

    site = Site.find_or_initialize_by(
      organization: organization,
      name: "#{template[0]} - #{customer.last_name}"
    )

    site.assign_attributes(
      customer: customer,
      address_line1: template[1],
      address_line2: index.even? ? nil : "Zone #{index + 1}",
      city: template[2],
      postal_code: template[3],
      country: "FR",
      site_type: template[4],
      surface_area: template[5],
      latitude: 48.50 + (index * 0.004),
      longitude: 7.65 + (index * 0.005),
      notes: "Site client #{index + 1} — suivi opérationnel GreenPilot.",
      active: index != 29
    )

    site.save!
    sites << site
  end

  puts "✓ Sites: #{sites.count}"

  # ============================================================
  # SERVICE CATEGORIES
  # ============================================================

  category_names = [
    ["ENT", "Entretien des espaces verts", "maintenance"],
    ["TON", "Tonte et gazon", "maintenance"],
    ["TAIL", "Taille et haies", "maintenance"],
    ["ARB", "Élagage et arboriculture", "tree_care"],
    ["IRR", "Arrosage et irrigation", "irrigation"],
    ["CRE", "Création paysagère", "creation"],
    ["PLT", "Plantation et végétalisation", "planting"],
    ["SOL", "Sols et préparation", "groundwork"],
    ["TER", "Terrassement et travaux extérieurs", "groundwork"],
    ["SAI", "Prestations saisonnières", "seasonal"]
  ]

  categories = []

  category_names.each_with_index do |data, index|
    category = ServiceCategory.find_or_initialize_by(
      organization: organization,
      code: data[0]
    )

    category.assign_attributes(
      name: data[1],
      description: "Prestations GreenPilot — #{data[1].downcase}.",
      category_type: data[2],
      position: index + 1,
      active: true
    )

    category.save!
    categories << category
  end

  puts "✓ Service categories: #{categories.count}"

  # ============================================================
  # SERVICE ITEMS
  # ============================================================

  service_definitions = [
    ["TON-01", 1, "Tonte de pelouse", "Tonte professionnelle des surfaces engazonnées", "m2", 0.85, 30],
    ["TON-02", 1, "Tonte grande surface", "Tonte mécanisée de grandes surfaces", "m2", 0.65, 32],
    ["TON-03", 1, "Scarification", "Scarification du gazon", "m2", 1.40, 35],
    ["TON-04", 1, "Aération du gazon", "Aération mécanique du gazon", "m2", 1.20, 34],

    ["ENT-01", 0, "Entretien massif", "Entretien courant des massifs", "m2", 3.50, 38],
    ["ENT-02", 0, "Désherbage manuel", "Désherbage manuel des espaces plantés", "heure", 42.00, 40],
    ["ENT-03", 0, "Nettoyage espace vert", "Nettoyage général des espaces verts", "heure", 38.00, 36],
    ["ENT-04", 0, "Soufflage", "Soufflage et nettoyage des surfaces", "heure", 35.00, 35],

    ["TAIL-01", 2, "Taille de haie", "Taille mécanique des haies", "ml", 7.50, 38],
    ["TAIL-02", 2, "Taille arbustes", "Taille d'entretien des arbustes", "heure", 45.00, 40],
    ["TAIL-03", 2, "Taille topiaire", "Taille de précision", "heure", 55.00, 42],
    ["TAIL-04", 2, "Taille de rosiers", "Taille saisonnière des rosiers", "heure", 44.00, 39],

    ["ARB-01", 3, "Élagage arbre", "Élagage d'entretien d'un arbre", "unité", 280.00, 35],
    ["ARB-02", 3, "Abattage arbre", "Abattage contrôlé d'un arbre", "unité", 650.00, 38],
    ["ARB-03", 3, "Dessouchage", "Dessouchage mécanique", "unité", 320.00, 36],
    ["ARB-04", 3, "Évacuation bois", "Évacuation et traitement des déchets verts", "m3", 95.00, 35],

    ["IRR-01", 4, "Diagnostic arrosage", "Diagnostic d'une installation d'arrosage", "forfait", 180.00, 40],
    ["IRR-02", 4, "Installation arrosage", "Installation d'un système d'arrosage", "heure", 65.00, 38],
    ["IRR-03", 4, "Maintenance arrosage", "Maintenance préventive d'une installation", "forfait", 145.00, 42],
    ["IRR-04", 4, "Hivernage arrosage", "Mise en hivernage du réseau", "forfait", 120.00, 40],

    ["CRE-01", 5, "Création massif", "Création complète d'un massif", "m2", 28.00, 35],
    ["CRE-02", 5, "Création pelouse", "Création d'une pelouse", "m2", 18.00, 36],
    ["CRE-03", 5, "Plantation paysagère", "Plantation et composition végétale", "m2", 42.00, 38],
    ["CRE-04", 5, "Aménagement jardin", "Aménagement paysager complet", "m2", 55.00, 34],

    ["PLT-01", 6, "Plantation arbre", "Plantation d'un arbre", "unité", 180.00, 38],
    ["PLT-02", 6, "Plantation arbuste", "Plantation d'un arbuste", "unité", 45.00, 40],
    ["PLT-03", 6, "Plantation vivaces", "Plantation de vivaces", "m2", 32.00, 39],
    ["PLT-04", 6, "Paillage végétal", "Fourniture et pose de paillage", "m2", 12.00, 42],

    ["SOL-01", 7, "Préparation du sol", "Préparation mécanique du terrain", "m2", 9.50, 34],
    ["SOL-02", 7, "Amendement", "Apport et incorporation d'amendement", "m2", 7.50, 36],
    ["SOL-03", 7, "Nivellement", "Nivellement de terrain", "m2", 11.00, 35],
    ["SOL-04", 7, "Apport de terre", "Fourniture et mise en place de terre végétale", "m3", 75.00, 32],

    ["TER-01", 8, "Terrassement léger", "Travaux de terrassement léger", "heure", 65.00, 34],
    ["TER-02", 8, "Pose bordures", "Pose de bordures paysagères", "ml", 28.00, 35],
    ["TER-03", 8, "Allée gravillonnée", "Création d'une allée gravillonnée", "m2", 48.00, 33],
    ["TER-04", 8, "Terrasse extérieure", "Préparation et réalisation d'une terrasse", "m2", 95.00, 30],

    ["SAI-01", 9, "Ramassage feuilles", "Ramassage saisonnier des feuilles", "heure", 38.00, 40],
    ["SAI-02", 9, "Déneigement", "Déneigement des accès", "heure", 55.00, 35],
    ["SAI-03", 9, "Nettoyage printemps", "Remise en état printanière", "forfait", 240.00, 38],
    ["SAI-04", 9, "Mise en hivernage", "Préparation des espaces avant hiver", "forfait", 190.00, 38]
  ]

  service_items = []

  service_definitions.each_with_index do |data, index|
    code = data[0]
    category = categories[data[1]]

    item = ServiceItem.find_or_initialize_by(
      organization: organization,
      code: code
    )

    item.assign_attributes(
      service_category: category,
      name: data[2],
      description: data[3],
      unit: data[4],
      default_quantity: data[4] == "unité" ? 1.0 : 100.0,
      default_unit_price: data[5],
      default_margin_percentage: data[6],
      labor_cost: data[5] * 0.30,
      material_cost: data[5] * 0.18,
      equipment_cost: data[5] * 0.10,
      overhead_cost: data[5] * 0.08,
      estimated_duration_minutes: data[4] == "heure" ? 60 : 90,
      position: index + 1,
      active: true
    )

    item.save!
    service_items << item
  end

  puts "✓ Service items: #{service_items.count}"

  # ============================================================
  # TEAMS
  # ============================================================

  team_definitions = [
    ["ENT-TEAM", "Équipe Entretien", "Opérations d'entretien récurrentes", "#22C55E"],
    ["CRE-TEAM", "Équipe Création", "Création et aménagement paysager", "#3B82F6"],
    ["ARB-TEAM", "Équipe Arboricole", "Élagage et travaux arboricoles", "#F59E0B"]
  ]

  teams = []

  team_definitions.each do |data|
    team = Team.find_or_initialize_by(
      organization: organization,
      code: data[0]
    )

    team.assign_attributes(
      name: data[1],
      description: data[2],
      color: data[3],
      active: true
    )

    team.save!
    teams << team
  end

  puts "✓ Teams: #{teams.count}"

  # ============================================================
  # TEAM MEMBERSHIPS
  # ============================================================

  membership_data = [
    [teams[0], users[:manager], "manager"],
    [teams[0], users[:field_worker_1], "member"],
    [teams[0], users[:member], "member"],
    [teams[1], users[:admin], "manager"],
    [teams[1], users[:field_worker_2], "member"],
    [teams[2], users[:owner], "manager"],
    [teams[2], users[:accountant], "member"]
  ]

  membership_data.each_with_index do |data, index|
    membership = TeamMembership.find_or_initialize_by(
      team: data[0],
      user: data[1]
    )

    membership.assign_attributes(
      organization: organization,
      role: data[2],
      active: true,
      start_date: today - (180 + index * 20).days,
      end_date: nil
    )

    membership.save!
  end

  puts "✓ Team memberships: #{TeamMembership.where(organization: organization).count}"

  # ============================================================
  # VEHICLES
  # ============================================================

  vehicle_definitions = [
    ["AA-001-AA", "Utilitaire Paysage 01", "Renault", "Master", "van", "diesel", 1200.0, 8.5, 2024],
    ["AA-002-AA", "Utilitaire Paysage 02", "Peugeot", "Boxer", "van", "diesel", 1400.0, 8.9, 2023],
    ["AA-003-AA", "Camion Benne 01", "Renault", "Maxity", "truck", "diesel", 2500.0, 11.2, 2022],
    ["AA-004-AA", "Fourgon Arboricole", "Ford", "Transit", "van", "diesel", 1000.0, 8.1, 2024]
  ]

  vehicles = []

  vehicle_definitions.each do |data|
    vehicle = Vehicle.find_or_initialize_by(
      organization: organization,
      registration_number: data[0]
    )

    vehicle.assign_attributes(
      name: data[1],
      brand: data[2],
      model: data[3],
      vehicle_type: data[4],
      fuel_type: data[5],
      capacity: data[6],
      fuel_consumption: data[7],
      year: data[8],
      active: true,
      notes: "Véhicule GreenPilot — flotte opérationnelle."
    )

    vehicle.save!
    vehicles << vehicle
  end

  puts "✓ Vehicles: #{vehicles.count}"

  # ============================================================
  # EQUIPMENT
  # ============================================================

  equipment_definitions = [
    ["Tondeuse Honda HRX", "mower", "Honda", "HRX", "GP-MOW-001", "available"],
    ["Tondeuse professionnelle", "mower", "Toro", "Pro 21", "GP-MOW-002", "in_use"],
    ["Taille-haie Stihl", "hedge_trimmer", "Stihl", "HS 82", "GP-HED-001", "available"],
    ["Taille-haie sur perche", "hedge_trimmer", "Stihl", "HL 94", "GP-HED-002", "available"],
    ["Débroussailleuse", "brushcutter", "Stihl", "FS 131", "GP-BRU-001", "in_use"],
    ["Débroussailleuse légère", "brushcutter", "Honda", "UMK", "GP-BRU-002", "available"],
    ["Souffleur", "blower", "Stihl", "BR 600", "GP-BLO-001", "available"],
    ["Souffleur compact", "blower", "Makita", "EB5300", "GP-BLO-002", "maintenance"],
    ["Tronçonneuse", "chainsaw", "Stihl", "MS 261", "GP-CHA-001", "available"],
    ["Élagueuse sur perche", "pole_saw", "Stihl", "HT 135", "GP-POL-001", "available"],
    ["Scarificateur", "scarifier", "Honda", "FG 110", "GP-SCA-001", "available"],
    ["Motobineuse", "tiller", "Honda", "F 220", "GP-TIL-001", "in_use"],
    ["Tarière", "auger", "Stihl", "BT 131", "GP-AUG-001", "available"],
    ["Broyeur végétaux", "chipper", "Jo Beau", "M300", "GP-CHI-001", "available"],
    ["Groupe électrogène", "generator", "Honda", "EU30", "GP-GEN-001", "out_of_service"]
  ]

  equipment_definitions.each_with_index do |data, index|
    equipment = Equipment.find_or_initialize_by(
      organization: organization,
      name: data[0]
    )

    equipment.assign_attributes(
      equipment_type: data[1],
      brand: data[2],
      model: data[3],
      serial_number: data[4],
      purchase_date: today - (120 + index * 35).days,
      purchase_price: 650.0 + (index * 325.0),
      status: data[5],
      active: data[5] != "retired",
      maintenance_interval_days: 90,
      last_maintenance_at: today - (10 + index).days,
      next_maintenance_at: today + (80 - index).days,
      notes: "Équipement opérationnel GreenPilot."
    )

    equipment.save!
  end

  puts "✓ Equipment: #{Equipment.where(organization: organization).count}"

  # ============================================================
  # QUOTES
  # ============================================================

  quotes = []

  quote_statuses = [
    "draft",
    "sent",
    "accepted",
    "accepted",
    "accepted",
    "rejected",
    "expired",
    "sent",
    "accepted",
    "draft",
    "accepted",
    "sent",
    "rejected",
    "accepted",
    "accepted",
    "draft",
    "sent",
    "accepted",
    "expired",
    "accepted"
  ]

  20.times do |index|
    customer = customers[index % customers.length]
    site = sites[index % sites.length]
    issue_date = today - (index * 6 + 2).days
    status = quote_statuses[index]

    subtotal = money.call(850 + (index * 137))
    discount = index % 5 == 0 ? money.call(50) : money.call(0)
    tax = (subtotal - discount) * money.call("0.20")
    total = subtotal - discount + tax
    estimated_cost = (subtotal - discount) * money.call("0.62")
    margin = subtotal - discount - estimated_cost

    quote = Quote.find_or_initialize_by(
      organization: organization,
      number: format("DEV-%<year>s-%<number>04d", year: today.year, number: index + 1)
    )

    quote.assign_attributes(
      customer: customer,
      site: site,
      title: [
        "Entretien annuel des espaces verts",
        "Création paysagère",
        "Taille et remise en forme",
        "Programme d'entretien saisonnier",
        "Aménagement du jardin",
        "Maintenance arboricole"
      ][index % 6],
      description: "Proposition commerciale GreenPilot pour #{site.name}.",
      issue_date: issue_date,
      valid_until: issue_date + 30.days,
      status: status,
      subtotal: subtotal,
      discount_amount: discount,
      tax_amount: tax,
      total_amount: total,
      estimated_cost: estimated_cost,
      estimated_margin_amount: margin,
      estimated_margin_percentage: subtotal.zero? ? 0 : ((margin / subtotal) * 100),
      notes: "Devis de démonstration #{index + 1}.",
      accepted_at: status == "accepted" ? issue_date + 5.days : nil,
      rejected_at: status == "rejected" ? issue_date + 7.days : nil
    )

    quote.save!
    quotes << quote
  end

  puts "✓ Quotes: #{quotes.count}"

  # ============================================================
  # QUOTE ITEMS
  # ============================================================

  quotes.each_with_index do |quote, quote_index|
    2.times do |line_index|
      service_item = service_items[(quote_index * 2 + line_index) % service_items.length]

      quantity =
        if service_item.unit == "unité"
          2 + (quote_index % 4)
        elsif service_item.unit == "heure"
          3 + (quote_index % 5)
        elsif service_item.unit == "forfait"
          1
        elsif service_item.unit == "ml"
          20 + (quote_index * 3)
        else
          80 + (quote_index * 10)
        end

      unit_price = service_item.default_unit_price
      subtotal = money.call(quantity) * money.call(unit_price)
      discount_percentage = quote_index % 6 == 0 ? 5.0 : 0.0
      discounted_subtotal = subtotal * (money.call(100) - money.call(discount_percentage)) / money.call(100)
      tax_rate = 20.0
      tax_amount = discounted_subtotal * money.call("0.20")
      total_amount = discounted_subtotal + tax_amount

      labor_cost = money.call(quantity) * money.call(service_item.labor_cost || 0)
      material_cost = money.call(quantity) * money.call(service_item.material_cost || 0)
      equipment_cost = money.call(quantity) * money.call(service_item.equipment_cost || 0)
      estimated_cost = labor_cost + material_cost + equipment_cost
      margin_amount = discounted_subtotal - estimated_cost

      item = QuoteItem.find_or_initialize_by(
        quote: quote,
        position: line_index + 1
      )

      item.assign_attributes(
        service_item: service_item,
        description: service_item.name,
        quantity: quantity,
        unit: service_item.unit,
        unit_price: unit_price,
        discount_percentage: discount_percentage,
        tax_rate: tax_rate,
        subtotal: discounted_subtotal,
        tax_amount: tax_amount,
        total_amount: total_amount,
        labor_cost: labor_cost,
        material_cost: material_cost,
        equipment_cost: equipment_cost,
        estimated_cost: estimated_cost,
        margin_amount: margin_amount,
        margin_percentage: discounted_subtotal.zero? ? 0 : ((margin_amount / discounted_subtotal) * 100),
        estimated_duration_minutes: service_item.estimated_duration_minutes
      )

      item.save!
    end
  end

 puts "✓ Quote items: #{QuoteItem.where(quote_id: quotes.map(&:id)).count}"

# ------------------------------------------------------------
# Jobs
# ------------------------------------------------------------

jobs = []

35.times do |index|
  site = sites[index % sites.length]
  customer = site.customer

  scheduled_date =
    if index < 12
      Date.current - (35 - index).days
    elsif index < 24
      Date.current + (index - 11).days
    else
      Date.current + (index - 20).days
    end

  status =
    case index
    when 0..7
      "completed"
    when 8..11
      "in_progress"
    when 12..24
      "planned"
    when 25..30
      "planned"
    else
      "cancelled"
    end

  priority =
    case index % 4
    when 0
      "high"
    when 1
      "normal"
    when 2
      "low"
    else
      "urgent"
    end

  weather_risk =
    case index % 4
    when 0
      "low"
    when 1
      "medium"
    when 2
      "unknown"
    else
      "high"
    end

  quote =
    quotes.find do |candidate|
      candidate.customer_id == customer.id &&
        candidate.site_id == site.id
    end

  start_hour = 8 + (index % 3)

  scheduled_start_at =
    Time.zone.parse(
      "#{scheduled_date} #{format('%02d', start_hour)}:00"
    )

  scheduled_end_at =
    scheduled_start_at + (2 + (index % 4)).hours

  completed_at =
    status == "completed" ? scheduled_end_at : nil

  started_at =
    %w[in_progress completed].include?(status) ?
      scheduled_start_at + 15.minutes :
      nil

  actual_duration_minutes =
    if status == "completed"
      90 + ((index % 5) * 30)
    elsif status == "in_progress"
      60 + ((index % 3) * 30)
    end
  cancelled_at = status == "cancelled" ? scheduled_start_at : nil

  cancellation_reason = status == "cancelled" ? "Intervention annulée par le client." : nil

  job = Job.create!(
    organization: organization,
    customer: customer,
    site: site,
    quote: quote,
    title: [
      "Entretien espaces verts",
      "Taille de haies",
      "Tonte et finitions",
      "Élagage préventif",
      "Entretien massif",
      "Maintenance arrosage",
      "Débroussaillage",
      "Remise en état du jardin"
    ][index % 8],
    description: [
      "Intervention d'entretien courant du site.",
      "Travaux de taille et évacuation des déchets verts.",
      "Prestation complète avec finitions et nettoyage.",
      "Intervention technique planifiée selon les besoins du site."
    ][index % 4],
    job_type: [
      "maintenance",
      "chantier",
      "elagage",
      "arrosage"
    ][index % 4],
    status: status,
    priority: priority,
    weather_risk: weather_risk,
    scheduled_date: scheduled_date,
    scheduled_start_at: scheduled_start_at,
    scheduled_end_at: scheduled_end_at,
    started_at: started_at,
    completed_at: completed_at,
    cancelled_at: cancelled_at,
    cancellation_reason: cancellation_reason,
    estimated_duration_minutes: 120 + ((index % 4) * 60),
    actual_duration_minutes: actual_duration_minutes,
    address: site.address_line1,
    latitude: site.latitude,
    longitude: site.longitude,
    travel_distance_km: 5 + ((index * 3) % 35),
    travel_duration_minutes: 10 + ((index * 5) % 40),
    customer_notes: "Prévenir le client avant l'arrivée de l'équipe.",
    internal_notes: "Vérifier le matériel avant départ.",
    weather_notes: weather_risk == "high" ? "Surveiller les conditions météo." : nil,
    team: teams[index % teams.length],
    vehicle: vehicles[index % vehicles.length]
  )

  jobs << job
end

puts "✓ Jobs: #{jobs.count}"
  # ============================================================
  # JOB ASSIGNMENTS
  # ============================================================

  assignment_users = [
    users[:field_worker_1],
    users[:field_worker_2],
    users[:manager],
    users[:admin],
    users[:owner],
    users[:member],
    users[:accountant]
  ]

  7.times do |index|
    job = jobs[index]

    assignment = JobAssignment.find_or_initialize_by(
      job: job,
      user: assignment_users[index]
    )

    assignment.assign_attributes(
      organization: organization,
      assignment_type: index.even? ? "primary" : "secondary",
      role: index < 3 ? "worker" : "supervisor",
      active: true,
      assigned_at: datetime.call(job.scheduled_date, 7, 30),
      accepted_at: datetime.call(job.scheduled_date, 7, 45),
      completed_at: job.status == status_completed ? datetime.call(job.scheduled_date, 10, 30) : nil,
      notes: "Affectation terrain GreenPilot."
    )

    assignment.save!
  end

  puts "✓ Job assignments: #{JobAssignment.where(organization: organization).count}"

  # ============================================================
  # JOB TIME ENTRIES
  # ============================================================

  jobs.each_with_index do |job, index|
    user =
      if index.even?
        users[:field_worker_1]
      else
        users[:field_worker_2]
      end

    started_at =
      if job.started_at
        job.started_at
      else
        datetime.call(job.scheduled_date, 8, 0)
      end

    duration =
      if job.actual_duration_minutes
        job.actual_duration_minutes
      else
        job.estimated_duration_minutes
      end

    entry = JobTimeEntry.find_or_initialize_by(
      job: job,
      user: user,
      started_at: started_at
    )

    entry.assign_attributes(
      organization: organization,
      entry_type: index % 4 == 0 ? "travel" : "work",
      ended_at: started_at + duration.minutes,
      duration_minutes: duration,
      notes: "Temps terrain enregistré pour la démonstration."
    )

    entry.save!
  end

  puts "✓ Job time entries: #{JobTimeEntry.where(organization: organization).count}"

  # ============================================================
  # JOB REPORTS
  # ============================================================

  completed_jobs = jobs.select { |job| job.status == status_completed }

  completed_jobs.first(25).each_with_index do |job, index|
    report = JobReport.find_or_initialize_by(
      job: job
    )

    generated_at = datetime.call(job.scheduled_date, 16, 30)

    report.assign_attributes(
      organization: organization,
      summary: "Intervention #{index + 1} terminée avec succès.",
      work_performed: "Travaux réalisés conformément à l'ordre de travail.",
      observations: [
        "Site en bon état général.",
        "Végétation correctement entretenue.",
        "Quelques zones nécessitent une surveillance.",
        "Aucun incident constaté."
      ][index % 4],
      recommendations: [
        "Prévoir une nouvelle intervention dans deux semaines.",
        "Maintenir le programme d'entretien actuel.",
        "Prévoir une taille complémentaire au prochain passage.",
        "Contrôler l'arrosage lors de la prochaine visite."
      ][index % 4],
      generated_at: generated_at,
      customer_signature: index.even? ? "Signature client" : nil,
      customer_signed_at: index.even? ? generated_at + 15.minutes : nil,
      sent_to_customer_at: generated_at + 30.minutes
    )

    report.save!
  end

  puts "✓ Job reports: #{JobReport.where(organization: organization).count}"

  # ============================================================
  # INVOICES
  # ============================================================

  invoice_statuses = [
    "paid",
    "paid",
    "issued",
    "overdue",
    "paid",
    "draft",
    "issued",
    "paid",
    "overdue",
    "paid",
    "issued",
    "paid",
    "cancelled",
    "paid",
    "issued",
    "draft",
    "paid",
    "overdue",
    "issued",
    "paid",
    "paid",
    "issued",
    "overdue",
    "paid",
    "draft"
  ]

  invoices = []

  25.times do |index|
    customer = customers[index % customers.length]
    site = sites[index % sites.length]
    job = jobs[index % jobs.length]
    quote = quotes[index % quotes.length]

    issue_date = today - (index * 5 + 3).days
    due_date = issue_date + 30.days

    subtotal = money.call(650 + (index * 185))
    discount = index % 7 == 0 ? money.call(75) : money.call(0)
    taxable = subtotal - discount
    tax = taxable * money.call("0.20")
    total = taxable + tax

    status = invoice_statuses[index]

    paid =
      case status
      when "paid"
        total
      when "issued"
        index.even? ? total * money.call("0.25") : money.call(0)
      when "overdue"
        total * money.call("0.10")
      else
        money.call(0)
      end

    amount_due = total - paid

    invoice = Invoice.find_or_initialize_by(
      organization: organization,
      number: format("FAC-%<year>s-%<number>04d", year: today.year, number: index + 1)
    )

    invoice.assign_attributes(
      customer: customer,
      job: job,
      quote: quote,
      site: site,
      issue_date: issue_date,
      due_date: due_date,
      status: status,
      subtotal: subtotal,
      discount_amount: discount,
      tax_amount: tax,
      total_amount: total,
      amount_paid: paid,
      amount_due: amount_due,
      paid_at: status == "paid" ? issue_date + 12.days : nil,
      payment_method: status == "paid" ? "bank_transfer" : nil,
      payment_reference: status == "paid" ? "VIR-#{today.year}-#{index + 1}" : nil,
      notes: "Facture de démonstration GreenPilot ##{index + 1}."
    )

    invoice.save!
    invoices << invoice
  end

  puts "✓ Invoices: #{invoices.count}"

  # ============================================================
  # INVOICE ITEMS
  # ============================================================

  invoices.each_with_index do |invoice, index|
    service_item = service_items[index % service_items.length]

    quantity =
      if service_item.unit == "unité"
        2
      elsif service_item.unit == "heure"
        4
      elsif service_item.unit == "forfait"
        1
      elsif service_item.unit == "ml"
        25
      else
        100
      end

    taxable_subtotal = money.call(invoice.subtotal) - money.call(invoice.discount_amount)
    quantity = 1 if taxable_subtotal <= 0

    unit_price = taxable_subtotal / money.call(quantity)
    tax_rate = 20.0
    tax_amount = taxable_subtotal * money.call("0.20")
    total_amount = taxable_subtotal + tax_amount

    item = InvoiceItem.find_or_initialize_by(
      invoice: invoice,
      position: index + 1
    )

    item.assign_attributes(
      service_item: service_item,
      description: service_item.name,
      quantity: quantity,
      unit: service_item.unit,
      unit_price: unit_price,
      discount_percentage: invoice.discount_amount.to_f.positive? ? 5.0 : 0.0,
      tax_rate: tax_rate,
      subtotal: taxable_subtotal,
      tax_amount: tax_amount,
      total_amount: total_amount
    )

    item.save!
  end

  puts "✓ Invoice items: #{InvoiceItem.joins(:invoice).where(invoices: { organization_id: organization.id }).count}"

  # ============================================================
  # PLANS
  # ============================================================

  plans = [
    {
      name: "Starter",
      slug: "starter",
      monthly_price_cents: 2_900,
      yearly_price_cents: 29_000,
      max_users: 1,
      active: true
    },
    {
      name: "Pro",
      slug: "pro",
      monthly_price_cents: 5_900,
      yearly_price_cents: 59_000,
      max_users: 5,
      active: true
    },
    {
      name: "Business",
      slug: "business",
      monthly_price_cents: 9_900,
      yearly_price_cents: 99_000,
      max_users: 15,
      active: true
    },
    {
      name: "Founder",
      slug: "founder",
      monthly_price_cents: 3_900,
      yearly_price_cents: 39_000,
      max_users: 5,
      active: true
    }
  ]

  plans.each do |attributes|
    plan = Plan.find_or_initialize_by(
      slug: attributes[:slug]
    )

    plan.assign_attributes(attributes)
    plan.save!
  end

  puts "✓ Plans: #{Plan.count}"

  # ============================================================
  # FINAL SUMMARY
  # ============================================================

  puts
  puts "============================================================"
  puts " GREENPILOT DEMO SEED COMPLETED"
  puts "============================================================"
  puts
  puts "Organization:      #{organization.name}"
  puts
  puts "Users:             #{User.where(organization: organization).count}"
  puts "Customers:         #{Customer.where(organization: organization).count}"
  puts "Sites:             #{Site.where(organization: organization).count}"
  puts "Categories:        #{ServiceCategory.where(organization: organization).count}"
  puts "Service items:     #{ServiceItem.where(organization: organization).count}"
  puts "Teams:             #{Team.where(organization: organization).count}"
  puts "Memberships:       #{TeamMembership.where(organization: organization).count}"
  puts "Vehicles:          #{Vehicle.where(organization: organization).count}"
  puts "Equipment:         #{Equipment.where(organization: organization).count}"
  puts "Quotes:            #{Quote.where(organization: organization).count}"
  puts "Quote items:       #{QuoteItem.joins(:quote).where(quotes: { organization_id: organization.id }).count}"
  puts "Jobs:              #{Job.where(organization: organization).count}"
  puts "Assignments:       #{JobAssignment.where(organization: organization).count}"
  puts "Time entries:      #{JobTimeEntry.where(organization: organization).count}"
  puts "Reports:           #{JobReport.where(organization: organization).count}"
  puts "Invoices:          #{Invoice.where(organization: organization).count}"
  puts "Invoice items:     #{InvoiceItem.joins(:invoice).where(invoices: { organization_id: organization.id }).count}"
  puts
  puts "Demo login:"
  puts "  Organization: greenpilot-paysage"
  puts "  Email:        owner@greenpilot-paysage.fr"
  puts "  Password:     #{seed_password}"
  puts
  puts "============================================================"
end
