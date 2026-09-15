require "prawn"
require "prawn/table"
module Pdf
  class JobReportPdf
    def initialize(job_report)
      @job_report = job_report
    end

    def render
      Prawn::Document.new(
        page_size: "A4",
        margin: [40, 45, 40, 45]
      ) do |pdf|
        build_header(pdf)
        build_intervention(pdf)
        build_customer_and_site(pdf)
        build_content(pdf)
        build_signature(pdf)
        build_footer(pdf)
      end.render
    end

    private

    def build_header(pdf)
      pdf.text "GREENPILOT", size: 22, style: :bold
      pdf.move_down 4

      pdf.fill_color "64748B"
      pdf.text "Rapport d'intervention", size: 11
      pdf.fill_color "000000"

      pdf.move_down 18
      pdf.stroke_horizontal_rule
      pdf.move_down 18
    end

    def build_intervention(pdf)
      job = @job_report.job

      pdf.text "INTERVENTION", size: 9, style: :bold, color: "7C3AED"
      pdf.move_down 5

      pdf.text(
        job&.title.presence || "Intervention sans titre",
        size: 17,
        style: :bold
      )

      pdf.move_down 10

      data = [
        [
          "Statut",
          job&.status.presence || "—",
          "Date planifiée",
          format_date(job&.scheduled_date)
        ],
        [
          "Rapport généré",
          format_datetime(@job_report.generated_at),
          "Rapport envoyé",
          format_datetime(@job_report.sent_to_customer_at)
        ]
      ]

      pdf.table(
        data,
        width: pdf.bounds.width,
        cell_style: {
          borders: [],
          padding: [4, 6],
          size: 9
        }
      ) do |table|
        table.columns(0).font_style = :bold
        table.columns(2).font_style = :bold
      end

      pdf.move_down 20
    end

    def build_customer_and_site(pdf)
      customer = @job_report.job&.customer
      site = @job_report.job&.site

      pdf.text "CLIENT & SITE", size: 9, style: :bold, color: "7C3AED"
      pdf.move_down 8

      data = [
        [
          "Client",
          customer_name(customer),
          "Site",
          site&.name.presence || "—"
        ],
        [
          "Adresse",
          site&.try(:address).presence || "—",
          "",
          ""
        ]
      ]

      pdf.table(
        data,
        width: pdf.bounds.width,
        cell_style: {
          borders: [],
          padding: [4, 6],
          size: 9
        }
      ) do |table|
        table.columns(0).font_style = :bold
        table.columns(2).font_style = :bold
      end

      pdf.move_down 20
    end

    def build_content(pdf)
      add_section(pdf, "Résumé", @job_report.summary)
      add_section(pdf, "Travaux réalisés", @job_report.work_performed)
      add_section(pdf, "Observations", @job_report.observations)
      add_section(pdf, "Recommandations", @job_report.recommendations)
    end

    def add_section(pdf, title, content)
      pdf.text title.upcase, size: 9, style: :bold, color: "7C3AED"
      pdf.move_down 6

      pdf.fill_color "F8FAFC"

      pdf.bounding_box([0, pdf.cursor], width: pdf.bounds.width) do
        pdf.text(
          content.presence || "Aucune information renseignée.",
          size: 10,
          leading: 4,
          color: "334155"
        )
      end

      pdf.fill_color "000000"
      pdf.move_down 16
    end

    def build_signature(pdf)
      pdf.start_new_page if pdf.cursor < 170

      pdf.text "VALIDATION CLIENT", size: 9, style: :bold, color: "7C3AED"
      pdf.move_down 10

      data = [
        [
          "Signature",
          @job_report.customer_signature.presence || "Non signée"
        ],
        [
          "Date de signature",
          format_datetime(@job_report.customer_signed_at)
        ]
      ]

      pdf.table(
        data,
        width: pdf.bounds.width,
        cell_style: {
          borders: [],
          padding: [5, 6],
          size: 9
        }
      ) do |table|
        table.columns(0).font_style = :bold
      end
    end

    def build_footer(pdf)
      pdf.number_pages(
        "Page <page> / <total>",
        at: [pdf.bounds.right - 100, 0],
        align: :right,
        size: 8,
        color: "64748B"
      )
    end

    def customer_name(customer)
      return "—" unless customer

      if customer.respond_to?(:name) && customer.name.present?
        customer.name
      elsif customer.respond_to?(:company_name) && customer.company_name.present?
        customer.company_name
      elsif customer.respond_to?(:first_name) ||
            customer.respond_to?(:last_name)
        [
          customer.try(:first_name),
          customer.try(:last_name)
        ].compact.join(" ").presence || "—"
      else
        "—"
      end
    end

    def format_date(value)
      return "—" unless value

      value.respond_to?(:strftime) ? value.strftime("%d/%m/%Y") : value.to_s
    end

    def format_datetime(value)
      return "—" unless value

      value.respond_to?(:strftime) ? value.strftime("%d/%m/%Y à %H:%M") : value.to_s
    end
  end
end